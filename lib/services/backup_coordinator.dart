import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import '../data/local_repository.dart';
import '../database/app_database.dart';
import 'app_storage_paths.dart';
import 'backup_archive_service.dart';

/// A validated candidate remains private until the user confirms replacement.
class BackupPreview {
  BackupPreview._(this._folder, this.database, this.images, this.attachments,
      this.manifest);

  final Directory _folder;
  final File database;
  final Directory? images;
  final Directory? attachments;
  final Map<String, dynamic> manifest;

  Map<String, int> get counts => (manifest['tableCounts'] as Map)
      .map((key, value) => MapEntry(key as String, value as int));
  String? get createdAt => manifest['createdAt'] as String?;
  int get schemaVersion => manifest['schemaVersion'] as int;
  bool get isLegacy => manifest['version'] == 1;

  Future<void> dispose() async {
    if (await _folder.exists()) await _folder.delete(recursive: true);
  }
}

class BackupCoordinator {
  const BackupCoordinator(this._repository);

  final LocalRepository _repository;
  static const _archive = BackupArchiveService();

  Future<File> export(String password, File destination) async {
    final scratch = await Directory.systemTemp.createTemp('organiza-export-');
    try {
      final copy = File(path.join(scratch.path, 'organiza.db'));
      await _repository.createConsistentCopy(copy);
      final copiedDatabase = AppDatabase.openFile(copy, migrate: false);
      late final Map<String, int> counts;
      late final int version;
      try {
        counts = copiedDatabase.tableCounts;
        version = copiedDatabase.schemaVersion;
      } finally {
        copiedDatabase.close();
      }
      return await _archive.export(
        database: copy,
        imageDirectory: AppStoragePaths.imageDirectory,
        attachmentDirectory: AppStoragePaths.attachmentDirectory,
        tableCounts: counts,
        schemaVersion: version,
        password: password,
        destination: destination,
        createdAt: DateTime.now(),
      );
    } finally {
      await scratch.delete(recursive: true);
    }
  }

  Future<BackupPreview> prepare(File source, String password) async {
    final scratch = await Directory.systemTemp.createTemp('organiza-restore-');
    try {
      final prepared = await _archive.prepare(source, password, scratch);
      final candidate = File(path.join(scratch.path, 'candidate.db'));
      if (prepared.isLegacy) {
        final staged = AppDatabase.openFile(candidate);
        try {
          staged.restoreSnapshot(prepared.legacySnapshot!);
          staged.validateIntegrity();
        } finally {
          staged.close();
        }
      } else {
        final raw = AppDatabase.openFile(prepared.database!, migrate: false);
        try {
          raw.validateIntegrity();
          final actual = raw.tableCounts;
          final declared = (prepared.manifest['tableCounts'] as Map)
              .map((key, value) => MapEntry(key as String, value as int));
          if (actual.length != declared.length ||
              actual.entries
                  .any((entry) => declared[entry.key] != entry.value)) {
            throw const FormatException(
                'Contagens do banco não conferem com o manifesto.');
          }
          if (raw.schemaVersion != prepared.manifest['schemaVersion']) {
            throw const FormatException(
                'Versão do banco não confere com o manifesto.');
          }
        } finally {
          raw.close();
        }
        await prepared.database!.copy(candidate.path);
        final staged = AppDatabase.openFile(candidate);
        try {
          staged.validateIntegrity();
        } finally {
          staged.close();
        }
      }
      return BackupPreview._(scratch, candidate, prepared.images,
          prepared.attachments, prepared.manifest);
    } catch (_) {
      if (await scratch.exists()) await scratch.delete(recursive: true);
      rethrow;
    }
  }

  /// Makes a safety copy first. The SQLite file is then replaced in one rename
  /// on the same filesystem. Images are added before that rename and old images
  /// remain, so interruption cannot make the current database lose references.
  Future<File> confirm(BackupPreview preview) async {
    final filePath = _repository.filePath;
    if (filePath == null) {
      throw StateError('Restauração de arquivo requer banco persistente.');
    }
    final live = File(filePath);
    final safety = File('$filePath.pre-restore.bak');
    final replacement = File('$filePath.restore-pending');
    if (await replacement.exists()) await replacement.delete();
    if (await safety.exists()) await safety.delete();
    await _repository.createConsistentCopy(safety);
    try {
      if (preview.images != null) {
        await for (final entity in preview.images!.list(followLinks: false)) {
          if (entity is! File) continue;
          final target = File(path.join(
              AppStoragePaths.imageDirectory.path, path.basename(entity.path)));
          if (await target.exists()) {
            final old = await target.readAsBytes();
            final incoming = await entity.readAsBytes();
            if (!_sameBytes(old, incoming)) {
              throw const FormatException(
                  'Conflito de nome entre imagens locais.');
            }
          } else {
            await entity.copy(target.path);
          }
        }
      }
      if (preview.attachments != null) {
        await AppStoragePaths.attachmentDirectory.create(recursive: true);
        await for (final entity
            in preview.attachments!.list(followLinks: false)) {
          if (entity is! File) continue;
          final target = File(path.join(
              AppStoragePaths.attachmentDirectory.path,
              path.basename(entity.path)));
          if (await target.exists()) {
            final old = await target.readAsBytes();
            final incoming = await entity.readAsBytes();
            if (!_sameBytes(old, incoming)) {
              throw const FormatException(
                  'Conflito de nome entre anexos locais.');
            }
          } else {
            await entity.copy(target.path);
          }
        }
      }
      await preview.database.copy(replacement.path);
      final check = AppDatabase.openFile(replacement);
      try {
        check.validateIntegrity();
      } finally {
        check.close();
      }
      _repository.closeForReplacement();
      try {
        if (await File('${live.path}-wal').exists() ||
            await File('${live.path}-shm').exists()) {
          throw const FileSystemException(
              'Outro acesso mantém o banco aberto; restauração cancelada.');
        }
        await _replaceFile(replacement, live);
      } finally {
        _repository.reopenAfterReplacement();
      }
      return safety;
    } finally {
      if (await replacement.exists()) await replacement.delete();
      await preview.dispose();
    }
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Future<void> _replaceFile(File source, File destination) async {
    if (Platform.isWindows) {
      final kernel = DynamicLibrary.open('kernel32.dll');
      final move = kernel.lookupFunction<
          Int32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32),
          int Function(Pointer<Utf16>, Pointer<Utf16>, int)>('MoveFileExW');
      final from = source.absolute.path.toNativeUtf16();
      final to = destination.absolute.path.toNativeUtf16();
      try {
        // MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH.
        if (move(from, to, 0x1 | 0x8) == 0) {
          throw FileSystemException(
              'Falha ao substituir o banco; a cópia de segurança foi preservada.',
              destination.path);
        }
      } finally {
        calloc.free(from);
        calloc.free(to);
      }
      return;
    }
    await source.rename(destination.path);
  }
}

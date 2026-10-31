import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import '../data/local_repository.dart';
import '../database/app_database.dart';
import '../domain/models.dart';
import 'app_storage_paths.dart';
import 'attachment_storage_service.dart';
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
      late final List<Attachment> attachments;
      try {
        counts = copiedDatabase.tableCounts;
        version = copiedDatabase.schemaVersion;
        attachments =
            version >= 21 ? copiedDatabase.loadAllAttachments() : const [];
      } finally {
        copiedDatabase.close();
      }
      final attachmentExport =
          Directory(path.join(scratch.path, 'attachments'));
      await attachmentExport.create();
      const storage = AttachmentStorageService();
      final seenReferences = <String>{};
      for (final attachment in attachments) {
        if (!seenReferences.add(attachment.relativePath.toLowerCase())) {
          throw const FormatException(
              'Mais de um registro aponta para o mesmo arquivo.');
        }
        final bytes = await storage.readVerified(
          relativePath: attachment.relativePath,
          sizeBytes: attachment.sizeBytes,
          sha256: attachment.sha256,
          mimeType: attachment.mimeType,
        );
        final filename = path.basename(attachment.relativePath);
        await File(path.join(attachmentExport.path, filename))
            .writeAsBytes(bytes, flush: true);
      }
      if (path.isWithin(AppStoragePaths.attachmentDirectory.path,
          path.absolute(destination.path))) {
        throw const FormatException(
            'Escolha um destino separado dos dados do aplicativo.');
      }
      return await _archive.export(
        database: copy,
        imageDirectory: AppStoragePaths.imageDirectory,
        attachmentDirectory: attachmentExport,
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
          if (raw.schemaVersion >= 21) {
            const storage = AttachmentStorageService();
            final metadata = raw.loadAllAttachments();
            final names = <String>{};
            for (final attachment in metadata) {
              final segments = attachment.relativePath.split('/');
              if (segments.length != 2 ||
                  segments.first != 'attachments' ||
                  !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,199}\.(jpg|jpeg|png|webp|gif|pdf)$',
                          caseSensitive: false)
                      .hasMatch(segments.last) ||
                  !names.add(segments.last.toLowerCase())) {
                throw const FormatException(
                    'Referência de anexo inválida no banco.');
              }
              await storage.verifyFile(
                File(path.join(prepared.attachments!.path, segments.last)),
                sizeBytes: attachment.sizeBytes,
                sha256: attachment.sha256,
                mimeType: attachment.mimeType,
              );
            }
            final stagedNames = await prepared.attachments!
                .list()
                .map((entity) => path.basename(entity.path))
                .toList();
            if (stagedNames.length != names.length ||
                stagedNames
                    .any((name) => !names.contains(name.toLowerCase()))) {
              throw const FormatException(
                  'Os arquivos anexos não correspondem ao banco.');
            }
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
    final installedAttachments = <File>[];
    var databaseReplaced = false;
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
        final incoming = <(File, File)>[];
        await for (final entity
            in preview.attachments!.list(followLinks: false)) {
          if (entity is! File ||
              await FileSystemEntity.type(entity.path, followLinks: false) !=
                  FileSystemEntityType.file) {
            throw const FormatException('Entrada inválida na pasta de anexos.');
          }
          final target = File(path.join(
              AppStoragePaths.attachmentDirectory.path,
              path.basename(entity.path)));
          final type =
              await FileSystemEntity.type(target.path, followLinks: false);
          if (type == FileSystemEntityType.link) {
            throw const FormatException(
                'O destino do anexo não pode ser um link.');
          }
          if (type == FileSystemEntityType.file) {
            final old = await target.readAsBytes();
            final incoming = await entity.readAsBytes();
            if (!_sameBytes(old, incoming)) {
              throw const FormatException(
                  'Conflito de nome entre anexos locais.');
            }
          } else if (type == FileSystemEntityType.notFound) {
            incoming.add((entity, target));
          } else {
            throw const FormatException(
                'O destino do anexo não é um arquivo regular.');
          }
        }
        for (final (source, target) in incoming) {
          await target.create(exclusive: true);
          installedAttachments.add(target);
          await target.writeAsBytes(await source.readAsBytes(), flush: true);
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
        databaseReplaced = true;
      } finally {
        _repository.reopenAfterReplacement();
      }
      return safety;
    } finally {
      if (await replacement.exists()) await replacement.delete();
      if (!databaseReplaced) {
        for (final file in installedAttachments.reversed) {
          if (await file.exists()) await file.delete();
        }
      }
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

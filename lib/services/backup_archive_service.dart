import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;

import 'backup_service.dart';

/// Validated transport output. The database layer validates/migrates the copied
/// database before the application may replace any live data.
class PreparedBackup {
  const PreparedBackup({
    this.database,
    this.images,
    this.attachments,
    this.manifest = const {},
    this.legacySnapshot,
  });

  final File? database;
  final Directory? images;
  final Directory? attachments;
  final Map<String, dynamic> manifest;
  final Map<String, dynamic>? legacySnapshot;
  bool get isLegacy => legacySnapshot != null;
}

/// Encrypted ZIP transport with bounded, strict extraction into a private copy.
/// [export] expects a consistent SQLite copy produced by the database layer.
class BackupArchiveService {
  const BackupArchiveService();

  static const maxDatabaseBytes = 64 * 1024 * 1024;
  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxManifestBytes = 1024 * 1024;
  static const maxTotalBytes = 128 * 1024 * 1024;
  static const maxEntries = 10002;
  static const _crypto = BackupService();
  static final _imageName = RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9._-]{0,199}\.(jpg|jpeg|png|webp|gif)$',
      caseSensitive: false);
  static final _attachmentName = RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9._-]{0,199}\.(jpg|jpeg|png|webp|gif|pdf)$',
      caseSensitive: false);
  static final _reservedName = RegExp(
      r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\.|$)',
      caseSensitive: false);

  Future<File> export({
    required File database,
    required Directory imageDirectory,
    Directory? attachmentDirectory,
    required Map<String, int> tableCounts,
    required int schemaVersion,
    required String password,
    required File destination,
    required DateTime createdAt,
    String appVersion = '0.9.0+13',
  }) async {
    _validateCounts(tableCounts);
    if (schemaVersion < 1 || appVersion.isEmpty || appVersion.length > 100) {
      throw const FormatException('Metadados do backup inválidos.');
    }
    final files = <String, Uint8List>{};
    if (await FileSystemEntity.type(database.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FormatException(
          'A cópia do banco deve ser um arquivo regular.');
    }
    files['organiza.db'] = await _readBounded(database, maxDatabaseBytes);
    var total = files['organiza.db']!.length;
    if (await imageDirectory.exists()) {
      if (await FileSystemEntity.type(imageDirectory.path,
              followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const FormatException('A pasta de imagens deve ser privada.');
      }
      await for (final entity in imageDirectory.list(followLinks: false)) {
        final name = 'images/${path.basename(entity.path)}';
        _entryLimit(name);
        if (entity is! File ||
            await FileSystemEntity.type(entity.path, followLinks: false) !=
                FileSystemEntityType.file) {
          throw const FormatException(
              'A pasta de imagens contém entrada inválida.');
        }
        if (files.keys.any((key) => key.toLowerCase() == name.toLowerCase())) {
          throw const FormatException('Nomes de imagens duplicados.');
        }
        if (files.length + 2 > maxEntries) {
          throw const FormatException('O backup contém arquivos demais.');
        }
        final length = await entity.length();
        if (length > maxImageBytes ||
            total + length > maxTotalBytes - maxManifestBytes) {
          throw const FormatException('O backup excede o limite de tamanho.');
        }
        files[name] = await _readBounded(entity, maxImageBytes);
        total += files[name]!.length;
      }
    }
    if (attachmentDirectory != null && await attachmentDirectory.exists()) {
      if (await FileSystemEntity.type(attachmentDirectory.path,
              followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const FormatException('A pasta de anexos deve ser privada.');
      }
      await for (final entity in attachmentDirectory.list(followLinks: false)) {
        final name = 'attachments/${path.basename(entity.path)}';
        _entryLimit(name);
        if (entity is! File ||
            await FileSystemEntity.type(entity.path, followLinks: false) !=
                FileSystemEntityType.file) {
          throw const FormatException(
              'A pasta de anexos contém entrada inválida.');
        }
        if (files.keys.any((key) => key.toLowerCase() == name.toLowerCase())) {
          throw const FormatException('Nomes de anexos duplicados.');
        }
        if (files.length + 2 > maxEntries) {
          throw const FormatException('O backup contém arquivos demais.');
        }
        final length = await entity.length();
        if (length <= 0 ||
            length > maxImageBytes ||
            total + length > maxTotalBytes - maxManifestBytes) {
          throw const FormatException('O backup excede o limite de tamanho.');
        }
        files[name] = await _readBounded(entity, maxImageBytes);
        total += files[name]!.length;
      }
    }
    final imageCount =
        files.keys.where((name) => name.startsWith('images/')).length;
    final attachmentCount =
        files.keys.where((name) => name.startsWith('attachments/')).length;
    final descriptions = <String, Object?>{};
    for (final name in files.keys.toList()..sort()) {
      final bytes = files[name]!;
      descriptions[name] = {
        'size': bytes.length,
        'sha256': await _digest(bytes)
      };
    }
    final manifest = <String, dynamic>{
      'format': 'organiza.backup',
      'version': 2,
      'appVersion': appVersion,
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'tableCounts': tableCounts,
      'imageCount': imageCount,
      'attachmentCount': attachmentCount,
      'fileCount': files.length,
      'files': descriptions,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    if (manifestBytes.length > maxManifestBytes ||
        total + manifestBytes.length > maxTotalBytes) {
      throw const FormatException('O manifesto excede o limite de tamanho.');
    }
    final zip = await Isolate.run(() {
      final archive = Archive()
        ..add(ArchiveFile.bytes('manifest.json', manifestBytes));
      for (final name in files.keys.toList()..sort()) {
        archive.add(ArchiveFile.bytes(name, files[name]!));
      }
      return Uint8List.fromList(ZipEncoder().encode(archive));
    });
    final envelope = await _crypto.encryptBytes(zip, password);
    final serialized = utf8.encode(jsonEncode(envelope));
    if (serialized.length > BackupService.maxEnvelopeBytes) {
      throw const FormatException('O backup excede o limite de tamanho.');
    }
    // Only the completed encrypted file is renamed onto the chosen destination.
    // A failure during validation/encryption leaves an existing backup intact.
    if (path.equals(
            path.absolute(database.path), path.absolute(destination.path)) ||
        path.isWithin(path.absolute(imageDirectory.path),
            path.absolute(destination.path)) ||
        (attachmentDirectory != null &&
            path.isWithin(path.absolute(attachmentDirectory.path),
                path.absolute(destination.path)))) {
      throw const FormatException(
          'Escolha um destino separado dos dados do aplicativo.');
    }
    await destination.parent.create(recursive: true);
    final scratch = await destination.parent.createTemp('.organiza-export-');
    try {
      final pending = File(path.join(scratch.path, 'encrypted.part'));
      await pending.writeAsBytes(serialized, flush: true);
      await pending.rename(destination.path);
      return destination;
    } finally {
      if (await scratch.exists()) await scratch.delete(recursive: true);
    }
  }

  Future<PreparedBackup> prepare(
      File source, String password, Directory staging) async {
    final bytes = await _readBounded(source, BackupService.maxEnvelopeBytes);
    final parsed = jsonDecode(utf8.decode(bytes));
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Arquivo de backup inválido.');
    }
    if (parsed['format'] == 'organiza.json' && parsed['version'] == 1) {
      return _legacy(parsed['content'], parsed['exportedAt']);
    }
    if (parsed['format'] == 'organiza.encrypted-backup' &&
        parsed['version'] == 1) {
      final snapshot = await _crypto.decryptContent(parsed, password);
      return _legacy(snapshot, parsed['exportedAt']);
    }
    final zip = await _crypto.decryptBytes(parsed, password);
    // Parsing and decompression happen outside the UI isolate. Structural
    // preflight runs before ZipDecoder can deduplicate entries or read symlinks.
    final files = await Isolate.run(() => _decodeZip(zip));
    final decodedManifest =
        jsonDecode(utf8.decode(files.remove('manifest.json')!));
    if (decodedManifest is! Map<String, dynamic>) {
      throw const FormatException('Manifesto inválido.');
    }
    await _validateManifest(decodedManifest, files);
    await staging.create(recursive: true);
    final working = await staging.createTemp('organiza-backup-');
    try {
      final images = Directory(path.join(working.path, 'images'));
      final attachments = Directory(path.join(working.path, 'attachments'));
      await images.create();
      await attachments.create();
      for (final entry in files.entries) {
        await File(path.joinAll([working.path, ...entry.key.split('/')]))
            .writeAsBytes(entry.value, flush: true);
      }
      return PreparedBackup(
          database: File(path.join(working.path, 'organiza.db')),
          images: images,
          attachments: attachments,
          manifest: Map.unmodifiable(decodedManifest));
    } catch (_) {
      await working.delete(recursive: true);
      rethrow;
    }
  }

  static PreparedBackup _legacy(Object? content, Object? exportedAt) {
    if (content is! Map<String, dynamic> ||
        content['schemaVersion'] is! int ||
        (content['schemaVersion'] as int) < 1 ||
        content['tables'] is! Map<String, dynamic>) {
      throw const FormatException('Conteúdo do backup legado inválido.');
    }
    final tables = content['tables'] as Map<String, dynamic>;
    final counts = <String, int>{};
    for (final entry in tables.entries) {
      final rows = entry.value;
      if (rows is! List || rows.any((row) => row is! Map<String, dynamic>)) {
        throw const FormatException('Tabela do backup legado inválida.');
      }
      counts[entry.key] = rows.length;
    }
    _validateCounts(counts);
    return PreparedBackup(
        legacySnapshot: content,
        manifest: Map.unmodifiable({
          'format': 'organiza.legacy-backup',
          'version': 1,
          'schemaVersion': content['schemaVersion'],
          'tableCounts': counts,
          'createdAt': exportedAt is String ? exportedAt : null,
          'imageCount': 0,
        }));
  }

  static Future<void> _validateManifest(
      Map<String, dynamic> manifest, Map<String, Uint8List> files) async {
    final schema = manifest['schemaVersion'];
    final version = manifest['appVersion'];
    final stamp = manifest['createdAt'];
    final descriptions = manifest['files'];
    if (manifest['format'] != 'organiza.backup' ||
        manifest['version'] != 2 ||
        schema is! int ||
        schema < 1 ||
        version is! String ||
        version.isEmpty ||
        version.length > 100 ||
        stamp is! String ||
        stamp.length > 40 ||
        !stamp.endsWith('Z') ||
        DateTime.tryParse(stamp) == null ||
        descriptions is! Map<String, dynamic> ||
        descriptions.length != files.length ||
        manifest['fileCount'] != files.length ||
        manifest['imageCount'] !=
            files.keys.where((name) => name.startsWith('images/')).length ||
        (manifest.containsKey('attachmentCount') &&
            manifest['attachmentCount'] !=
                files.keys
                    .where((name) => name.startsWith('attachments/'))
                    .length) ||
        files.keys.any((name) => name.startsWith('attachments/')) &&
            !manifest.containsKey('attachmentCount')) {
      throw const FormatException('Metadados do manifesto inválidos.');
    }
    _validateCounts(manifest['tableCounts']);
    for (final entry in files.entries) {
      final description = descriptions[entry.key];
      if (description is! Map<String, dynamic> ||
          description['size'] != entry.value.length ||
          description['sha256'] is! String ||
          description['sha256'] != await _digest(entry.value)) {
        throw const FormatException(
            'Integridade de arquivo do backup inválida.');
      }
    }
  }

  static Future<String> _digest(List<int> bytes) async =>
      (await Sha256().hash(bytes))
          .bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

  static void _validateCounts(Object? counts) {
    if (counts is! Map ||
        counts.length > 100 ||
        counts.entries.any((entry) =>
            entry.key is! String ||
            !RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(entry.key as String) ||
            entry.value is! int ||
            (entry.value as int) < 0 ||
            (entry.value as int) > 100000000)) {
      throw const FormatException('Contagens de tabelas inválidas.');
    }
  }

  static Future<Uint8List> _readBounded(File file, int limit) async {
    if (await file.length() > limit) {
      throw const FormatException('O backup excede o limite de tamanho.');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length > limit) {
        throw const FormatException('O backup excede o limite de tamanho.');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  static int _entryLimit(String name) {
    if (name == 'manifest.json') return maxManifestBytes;
    if (name == 'organiza.db') return maxDatabaseBytes;
    if (name.startsWith('images/') && name.split('/').length == 2) {
      final filename = name.substring(7);
      if (_imageName.hasMatch(filename) && !_reservedName.hasMatch(filename)) {
        return maxImageBytes;
      }
    }
    if (name.startsWith('attachments/') && name.split('/').length == 2) {
      final filename = name.substring(12);
      if (_attachmentName.hasMatch(filename) &&
          !_reservedName.hasMatch(filename)) {
        return maxImageBytes;
      }
    }
    throw const FormatException('Caminho de arquivo inválido no backup.');
  }

  static Map<String, Uint8List> _decodeZip(Uint8List zip) {
    _preflightZip(zip);
    final archive = ZipDecoder().decodeBytes(zip);
    try {
      final files = <String, Uint8List>{};
      for (final entry in archive) {
        if (!entry.isFile ||
            entry.isSymbolicLink ||
            entry.size > _entryLimit(entry.name)) {
          throw const FormatException('Entrada inválida no backup.');
        }
        final bytes = entry.readBytes();
        if (bytes == null ||
            bytes.length != entry.size ||
            (entry.crc32 != null && getCrc32(bytes) != entry.crc32)) {
          throw const FormatException('Arquivo ZIP corrompido.');
        }
        files[entry.name] = bytes;
      }
      if (!files.containsKey('manifest.json') ||
          !files.containsKey('organiza.db')) {
        throw const FormatException('Banco ou manifesto ausente no backup.');
      }
      return files;
    } finally {
      archive.clearSync();
    }
  }

  /// ZIP32 only: limits are far below ZIP64. Reject ambiguous headers and
  /// duplicate/case-colliding paths before the archive package allocates entries.
  static void _preflightZip(Uint8List zip) {
    if (zip.length < 22 || zip.length > BackupService.maxPayloadBytes) {
      throw const FormatException('Arquivo ZIP inválido.');
    }
    final bytes = ByteData.sublistView(zip);
    int u16(int offset) => bytes.getUint16(offset, Endian.little);
    int u32(int offset) => bytes.getUint32(offset, Endian.little);
    var end = zip.length - 22;
    final earliest = (zip.length - 65557).clamp(0, zip.length);
    while (end >= earliest) {
      if (u32(end) == 0x06054b50 && end + 22 + u16(end + 20) == zip.length) {
        break;
      }
      end--;
    }
    if (end < earliest ||
        u16(end + 4) != 0 ||
        u16(end + 6) != 0 ||
        u16(end + 8) != u16(end + 10) ||
        u16(end + 10) > maxEntries ||
        u16(end + 10) < 2 ||
        u32(end + 16) + u32(end + 12) != end) {
      throw const FormatException('Diretório ZIP inválido ou grande demais.');
    }
    final centralStart = u32(end + 16);
    var offset = centralStart;
    var total = 0;
    final names = <String>{};
    final ranges = <(int, int)>[];
    for (var count = 0; count < u16(end + 10); count++) {
      if (offset + 46 > end || u32(offset) != 0x02014b50) {
        throw const FormatException('Diretório ZIP truncado.');
      }
      final nameLength = u16(offset + 28);
      final extraLength = u16(offset + 30);
      final commentLength = u16(offset + 32);
      if (nameLength < 1 ||
          nameLength > 220 ||
          offset + 46 + nameLength + extraLength + commentLength > end) {
        throw const FormatException('Entrada ZIP truncada.');
      }
      final name =
          utf8.decode(zip.sublist(offset + 46, offset + 46 + nameLength));
      final limit = _entryLimit(name);
      final size = u32(offset + 24);
      final compressed = u32(offset + 20);
      final flags = u16(offset + 8);
      final method = u16(offset + 10);
      final mode = (u32(offset + 38) >> 16) & 0xf000;
      final local = u32(offset + 42);
      if (!names.add(name.toLowerCase()) ||
          size > limit ||
          total + size > maxTotalBytes ||
          flags & 1 != 0 ||
          (method != 0 && method != 8) ||
          (mode != 0 && mode != 0x8000) ||
          u16(offset + 34) != 0 ||
          local + 30 > centralStart ||
          u32(local) != 0x04034b50 ||
          u16(local + 6) != flags ||
          u16(local + 8) != method) {
        throw const FormatException('Entrada ZIP inválida ou grande demais.');
      }
      final localNameLength = u16(local + 26);
      final localExtraLength = u16(local + 28);
      final contentStart = local + 30 + localNameLength + localExtraLength;
      if (contentStart + compressed > centralStart ||
          localNameLength != nameLength ||
          utf8.decode(zip.sublist(local + 30, local + 30 + localNameLength)) !=
              name) {
        throw const FormatException('Cabeçalhos ZIP inconsistentes.');
      }
      ranges.add((local, contentStart + compressed));
      total += size;
      offset += 46 + nameLength + extraLength + commentLength;
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 1; i < ranges.length; i++) {
      if (ranges[i].$1 < ranges[i - 1].$2) {
        throw const FormatException('Entradas ZIP sobrepostas.');
      }
    }
    if (offset != end ||
        !names.contains('manifest.json') ||
        !names.contains('organiza.db')) {
      throw const FormatException('Estrutura do backup incompleta.');
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'local_image_service.dart';

class RestoredBackupImages {
  const RestoredBackupImages(this.snapshot, this.createdFiles);

  final Map<String, dynamic> snapshot;
  final List<File> createdFiles;

  Future<void> deleteCreatedFiles() async {
    for (final file in createdFiles) {
      if (await file.exists()) await file.delete();
    }
  }
}

/// Embeds private images inside the encrypted snapshot payload, never outside it.
class BackupImages {
  const BackupImages._();

  static Future<Map<String, dynamic>> embed(Map<String, Object?> source) async {
    final snapshot = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    final images = <Map<String, String>>[];
    final tables = snapshot['tables'] as Map<String, dynamic>;
    Future<void> add(Map<String, dynamic> row, String column) async {
      final original = row[column];
      if (original is! String || original.isEmpty) return;
      final file = File(original);
      final extension = path.extension(original).toLowerCase();
      if (!await file.exists() ||
          !LocalImageService.allowedExtensions.contains(extension) ||
          await file.length() > LocalImageService.maxBytes) {
        row[column] = null;
        return;
      }
      final token = 'backup-image:${images.length}';
      images.add({
        'token': token,
        'extension': extension,
        'bytes': base64Encode(await file.readAsBytes())
      });
      row[column] = token;
    }

    for (final raw in tables['app_settings'] as List) {
      final row = raw as Map<String, dynamic>;
      if (row['key'] == 'profile_photo_path') {
        await add(row, 'value');
        row['value'] ??= '';
      }
    }
    for (final table in ['shopping_items', 'financial_goals']) {
      for (final raw in tables[table] as List) {
        await add(raw as Map<String, dynamic>, 'image_path');
      }
    }
    snapshot['images'] = images;
    return snapshot;
  }

  static Future<Map<String, dynamic>> restore(Map<String, dynamic> source,
          {Directory? targetDirectory}) async =>
      (await restorePrepared(source, targetDirectory: targetDirectory))
          .snapshot;

  static Future<RestoredBackupImages> restorePrepared(
      Map<String, dynamic> source,
      {Directory? targetDirectory}) async {
    final snapshot = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    final rawImages = snapshot['images'];
    if (rawImages == null) {
      return RestoredBackupImages(snapshot, const []); // Legacy backup v1.
    }
    if (rawImages is! List) {
      throw const FormatException('Imagens inválidas no backup.');
    }
    final target = targetDirectory ??
        Directory(path.join((await getApplicationSupportDirectory()).path,
            'Organiza', 'images'));
    final paths = <String, String>{};
    final prepared = <(File, List<int>)>[];
    for (final raw in rawImages) {
      if (raw is! Map) {
        throw const FormatException('Imagem inválida no backup.');
      }
      final token = raw['token'];
      final extension = raw['extension'];
      final encoded = raw['bytes'];
      if (token is! String ||
          extension is! String ||
          encoded is! String ||
          !LocalImageService.allowedExtensions.contains(extension) ||
          paths.containsKey(token)) {
        throw const FormatException('Metadados de imagem inválidos no backup.');
      }
      final bytes = base64Decode(encoded);
      if (bytes.length > LocalImageService.maxBytes) {
        throw const FormatException(
            'Imagem do backup excede o tamanho permitido.');
      }
      final file =
          File(path.join(target.path, '${const Uuid().v4()}$extension'));
      prepared.add((file, bytes));
      paths[token] = file.path;
    }
    final rawTables = snapshot['tables'];
    if (rawTables is! Map<String, dynamic>) {
      throw const FormatException('Tabelas inválidas no backup.');
    }
    final tables = rawTables;
    void rewrite(Map<String, dynamic> row, String column) {
      final value = row[column];
      if (value is String && value.startsWith('backup-image:')) {
        final restored = paths[value];
        if (restored == null) {
          throw const FormatException('Referência de imagem ausente.');
        }
        row[column] = restored;
      }
    }

    for (final raw in (tables['app_settings'] as List?) ?? const []) {
      final row = raw as Map<String, dynamic>;
      if (row['key'] == 'profile_photo_path') rewrite(row, 'value');
    }
    for (final table in ['shopping_items', 'financial_goals']) {
      for (final raw in (tables[table] as List?) ?? const []) {
        rewrite(raw as Map<String, dynamic>, 'image_path');
      }
    }
    final created = <File>[];
    try {
      await target.create(recursive: true);
      for (final (file, bytes) in prepared) {
        created.add(file);
        await file.writeAsBytes(bytes, flush: true);
      }
    } catch (_) {
      for (final file in created) {
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
    snapshot.remove('images');
    return RestoredBackupImages(snapshot, created);
  }
}

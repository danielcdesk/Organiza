import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// JSON backup transport. Import confirmation and integrity checks belong to UI flows.
class BackupService {
  const BackupService();

  Future<File> exportJson(Map<String, Object?> content) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(path.join(directory.path, 'Organiza', 'exports'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(path.join(folder.path, 'organiza-$stamp.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert({
      'format': 'organiza.json',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'content': content,
    }));
    return file;
  }

  Future<Map<String, dynamic>> validateJson(File file) async {
    final parsed = jsonDecode(await file.readAsString());
    if (parsed is! Map<String, dynamic> ||
        parsed['format'] != 'organiza.json' ||
        parsed['version'] != 1) {
      throw const FormatException(
          'Arquivo de backup inválido ou incompatível.');
    }
    return parsed;
  }
}

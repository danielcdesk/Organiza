import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies selected images into the app's private support folder so the app
/// keeps working offline even if the original file is moved or deleted.
class LocalImageService {
  const LocalImageService._();

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

  static Future<String?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    final extension = path.extension(selected.name).toLowerCase();
    if (!allowedExtensions.contains(extension)) return null;
    if (selected.bytes != null && selected.bytes!.length > maxBytes) {
      return null;
    }
    final sourcePath = selected.path;
    if (selected.bytes == null && sourcePath != null) {
      final source = File(sourcePath);
      if (await source.length() > maxBytes) return null;
    }
    final appDirectory = await getApplicationSupportDirectory();
    final imageDirectory = Directory(
      path.join(appDirectory.path, 'Organiza', 'images'),
    )..createSync(recursive: true);
    final target = File(path.join(
      imageDirectory.path,
      '${const Uuid().v4()}${extension.isEmpty ? '.jpg' : extension}',
    ));
    if (selected.bytes != null) {
      await target.writeAsBytes(selected.bytes!, flush: true);
      return target.path;
    }
    if (sourcePath == null) return null;
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  static bool exists(String? imagePath) =>
      imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();
}

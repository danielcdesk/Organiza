import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'app_storage_paths.dart';

/// Copies selected images into the app's private support folder so the app
/// keeps working offline even if the original file is moved or deleted.
class LocalImageService {
  const LocalImageService._();

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

  static Future<String?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    final extension = path.extension(selected.name).toLowerCase();
    if (!allowedExtensions.contains(extension)) return null;
    if (selected.size > maxBytes ||
        (selected.bytes != null && selected.bytes!.length > maxBytes)) {
      return null;
    }
    final sourcePath = selected.path;
    if (sourcePath != null) return storeFile(File(sourcePath));
    if (selected.bytes != null) {
      await AppStoragePaths.initialize();
      final reference = _newReference(extension);
      final target = fileFor(reference);
      await target.writeAsBytes(selected.bytes!, flush: true);
      return reference;
    }
    return null;
  }

  /// Copies rather than moves; the source remains available after migration.
  static Future<String?> storeFile(File source) async {
    final extension = path.extension(source.path).toLowerCase();
    if (!allowedExtensions.contains(extension)) return null;
    try {
      final stat = await source.stat();
      if (stat.type != FileSystemEntityType.file || stat.size > maxBytes) {
        return null;
      }
      await AppStoragePaths.initialize();
      final reference = _newReference(extension);
      final target = fileFor(reference);
      await source.copy(target.path);
      // Recheck the copy in case another application changed the source.
      if (await target.length() > maxBytes) {
        await target.delete();
        return null;
      }
      return reference;
    } on FileSystemException {
      return null;
    }
  }

  static String _newReference(String extension) =>
      'images/${const Uuid().v4()}$extension';

  static File fileFor(String reference) =>
      AppStoragePaths.resolveImage(reference);

  static bool exists(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    try {
      return fileFor(imagePath).existsSync();
    } on FormatException {
      return false;
    } on FileSystemException {
      return false;
    } on StateError {
      return false;
    }
  }

  /// Missing and unsupported legacy files keep their old references unchanged.
  /// Callers atomically rewrite only the successfully copied references.
  static Future<Map<String, String>> importLegacyImages(
    Iterable<String> references,
  ) async {
    final replacements = <String, String>{};
    for (final reference in references.toSet()) {
      if (!path.isAbsolute(reference) && !path.windows.isAbsolute(reference)) {
        continue;
      }
      final imported = await storeFile(File(reference));
      if (imported != null) replacements[reference] = imported;
    }
    return replacements;
  }
}

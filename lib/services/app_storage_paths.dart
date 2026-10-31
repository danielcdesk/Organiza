import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// The shared private root for the database, portable images and local backups.
class AppStoragePaths {
  const AppStoragePaths._();

  static Directory? _rootDirectory;

  /// Explicit roots let isolated app sessions use their own private directory.
  /// Normal startup initializes the production root only once.
  static Future<void> initialize({Directory? root}) async {
    if (root == null && _rootDirectory != null) return;
    final Directory selected;
    if (root != null) {
      selected = root.absolute;
    } else {
      final local =
          Platform.isWindows ? Platform.environment['LOCALAPPDATA'] : null;
      final support = local != null && local.isNotEmpty
          ? Directory(local)
          : await getApplicationSupportDirectory();
      selected = Directory(path.join(support.path, 'Organiza'));
    }
    await selected.create(recursive: true);
    final images = Directory(path.join(selected.path, 'images'));
    if (FileSystemEntity.typeSync(images.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException(
          'A pasta de imagens não pode ser um link.');
    }
    await images.create(recursive: true);
    final attachments = Directory(path.join(selected.path, 'attachments'));
    if (FileSystemEntity.typeSync(attachments.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException(
          'A pasta de anexos não pode ser um link.');
    }
    await attachments.create(recursive: true);
    _rootDirectory = selected;
  }

  static Directory get rootDirectory =>
      _rootDirectory ??
      (throw StateError('A pasta privada do aplicativo não foi inicializada.'));

  static Directory get imageDirectory =>
      Directory(path.join(rootDirectory.path, 'images'));

  static Directory get attachmentDirectory =>
      Directory(path.join(rootDirectory.path, 'attachments'));

  static File resolveAttachment(String reference) {
    final segments = reference.split('/');
    if (reference.isEmpty ||
        reference.contains('\u0000') ||
        reference.contains('\\') ||
        segments.length != 2 ||
        segments.first != 'attachments' ||
        !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(segments.last) ||
        segments.last == '.' ||
        segments.last == '..') {
      throw const FormatException('Referência de anexo inválida.');
    }
    final file = File(path.join(attachmentDirectory.path, segments.last));
    if (FileSystemEntity.typeSync(attachmentDirectory.path,
                followLinks: false) ==
            FileSystemEntityType.link ||
        FileSystemEntity.typeSync(file.path, followLinks: false) ==
            FileSystemEntityType.link) {
      throw const FormatException('Referência de anexo inválida.');
    }
    return file;
  }

  /// Reads legacy absolute references until startup has imported their images.
  /// New references always consist of `images/<filename>` using POSIX slashes.
  static File resolveImage(String reference) {
    if (reference.isEmpty || reference.contains('\u0000')) {
      throw const FormatException('Referência de imagem inválida.');
    }
    if (path.isAbsolute(reference) || path.windows.isAbsolute(reference)) {
      return File(reference);
    }
    final segments = reference.split('/');
    if (reference.contains('\\') ||
        segments.length != 2 ||
        segments.first != 'images' ||
        !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(segments.last) ||
        segments.last == '.' ||
        segments.last == '..') {
      throw const FormatException('Referência de imagem inválida.');
    }
    final image = File(path.join(imageDirectory.path, segments.last));
    if (FileSystemEntity.typeSync(imageDirectory.path, followLinks: false) ==
            FileSystemEntityType.link ||
        FileSystemEntity.typeSync(image.path, followLinks: false) ==
            FileSystemEntityType.link) {
      throw const FormatException('Referência de imagem inválida.');
    }
    return image;
  }

  @visibleForTesting
  static void resetForTesting() => _rootDirectory = null;
}

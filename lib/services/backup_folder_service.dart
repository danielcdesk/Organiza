import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'app_storage_paths.dart';

/// Writes scheduled backups only into a folder deliberately chosen by the user.
/// Android retains its Storage Access Framework tree permission in native code.
class BackupFolderService {
  const BackupFolderService();

  static const _channel =
      MethodChannel('com.danielcdesk.organiza/backup_folder');
  static final _name = RegExp(r'^organiza-auto-[A-Za-z0-9._-]+\.organizabak$');

  Future<String?> choose() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod<String>('choose');
    }
    final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Escolha a pasta dos backups automáticos');
    if (selected != null) _validateDesktopFolder(selected);
    return selected;
  }

  Future<bool> configured(String? desktopFolder, {String? candidate}) async {
    if (Platform.isAndroid) {
      return await _channel
              .invokeMethod<bool>('configured', {'candidate': candidate}) ??
          false;
    }
    final chosen = candidate ?? desktopFolder;
    if (chosen == null || chosen.isEmpty) return false;
    _validateDesktopFolder(chosen);
    return Directory(chosen).exists();
  }

  Future<void> commit(String selected) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('commit', {'uri': selected});
    } else {
      _validateDesktopFolder(selected);
    }
  }

  Future<void> discard(String selected) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('discard', {'uri': selected});
    }
  }

  static void _validateDesktopFolder(String folder) {
    if (!Platform.isWindows) return;
    final images = path
        .normalize(AppStoragePaths.imageDirectory.absolute.path)
        .toLowerCase();
    final chosen =
        path.normalize(Directory(folder).absolute.path).toLowerCase();
    if (chosen == images || path.isWithin(images, chosen)) {
      throw ArgumentError('Escolha uma pasta fora das imagens do Organiza.');
    }
  }

  Future<void> save(File source, String name, String? desktopFolder) async {
    if (!_name.hasMatch(name)) throw ArgumentError('Nome de backup inválido.');
    if (Platform.isAndroid) {
      await _channel.invokeMethod<String>('save', {
        'name': name,
        'source': source.path,
      });
      return;
    }
    if (desktopFolder == null || desktopFolder.isEmpty) {
      throw StateError('Escolha uma pasta de backup.');
    }
    _validateDesktopFolder(desktopFolder);
    final folder = Directory(desktopFolder);
    if (!await folder.exists()) {
      throw StateError('Pasta de backup indisponível.');
    }
    final target = File(path.join(folder.path, name));
    if (await target.exists()) throw StateError('Backup já existe.');
    final pending = File(path.join(folder.path, '.$name.part'));
    try {
      await source.copy(pending.path);
      await pending.rename(target.path);
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<List<String>> list(String? desktopFolder) async {
    if (Platform.isAndroid) {
      return (await _channel.invokeListMethod<String>('list')) ?? [];
    }
    if (desktopFolder == null || !await Directory(desktopFolder).exists()) {
      return [];
    }
    return Directory(desktopFolder)
        .list(followLinks: false)
        .where((entity) =>
            entity is File && _name.hasMatch(path.basename(entity.path)))
        .map((entity) => path.basename(entity.path))
        .toList();
  }

  Future<void> delete(String name, String? desktopFolder) async {
    if (!_name.hasMatch(name)) throw ArgumentError('Nome de backup inválido.');
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('delete', {'name': name});
      return;
    }
    if (desktopFolder == null) throw StateError('Pasta não configurada.');
    final file = File(path.join(desktopFolder, name));
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.file) {
      await file.delete();
    }
  }
}

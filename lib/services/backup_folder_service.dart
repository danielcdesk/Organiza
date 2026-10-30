import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

/// Writes scheduled backups only into a folder deliberately chosen by the user.
/// Android retains its Storage Access Framework tree permission in native code.
class BackupFolderService {
  const BackupFolderService();

  static const _channel =
      MethodChannel('com.danielcdesk.organiza/backup_folder');
  static final _name = RegExp(r'^organiza-auto-[A-Za-z0-9._-]+\.organizabak$');

  Future<String?> choose() async {
    if (Platform.isAndroid) {
      final chosen = await _channel.invokeMethod<bool>('choose') ?? false;
      return chosen ? 'Pasta escolhida no Android' : null;
    }
    return FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Escolha a pasta dos backups automáticos');
  }

  Future<bool> configured(String? desktopFolder) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<bool>('configured') ?? false;
    }
    return desktopFolder != null &&
        desktopFolder.isNotEmpty &&
        await Directory(desktopFolder).exists();
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'application/organiza_store.dart';
import 'presentation/organiza_app.dart';

RandomAccessFile? _instanceLock;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    if (!await _acquireWindowsInstanceLock()) return;
    assert(_instanceLock != null);
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(960, 640),
      center: true,
      title: 'Organiza',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  final store = await OrganizaStore.create();
  runApp(OrganizaApp(store: store));
}

Future<bool> _acquireWindowsInstanceLock() async {
  final localAppData = Platform.environment['LOCALAPPDATA'];
  final directory = localAppData == null || localAppData.isEmpty
      ? await getApplicationSupportDirectory()
      : Directory(localAppData);
  final folder = Directory(path.join(directory.path, 'Organiza'))
    ..createSync(recursive: true);
  final lockFile = File(path.join(folder.path, 'organiza.lock'));
  final handle = await lockFile.open(mode: FileMode.write);
  try {
    await handle.lock(FileLock.exclusive);
    _instanceLock = handle;
    return true;
  } on FileSystemException {
    await handle.close();
    return false;
  }
}

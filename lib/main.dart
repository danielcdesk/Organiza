import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'application/organiza_store.dart';
import 'presentation/organiza_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
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

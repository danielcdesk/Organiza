import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/services/app_storage_paths.dart';
import 'package:organiza/services/secret_vault.dart';
import 'package:path/path.dart' as path;

void main() {
  test('cofre do Windows protege, atualiza e apaga a senha', () async {
    if (!Platform.isWindows) return;
    final root = await Directory.systemTemp.createTemp('organiza-vault-test-');
    addTearDown(() async {
      AppStoragePaths.resetForTesting();
      await root.delete(recursive: true);
    });
    await AppStoragePaths.initialize(root: root);
    const vault = SystemSecretVault();
    const key = 'organiza.backup.password';
    expect(await vault.read(key), isNull);

    await vault.write(key, 'senha-de-exemplo');
    final encrypted = await File(path.join(root.path, 'backup-password.dpapi'))
        .readAsBytes();
    expect(String.fromCharCodes(encrypted), isNot(contains('senha-de-exemplo')));
    expect(await vault.read(key), 'senha-de-exemplo');

    await vault.write(key, 'nova-senha');
    expect(await vault.read(key), 'nova-senha');
    await vault.delete(key);
    expect(await vault.read(key), isNull);
  });
}

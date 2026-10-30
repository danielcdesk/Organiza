import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/services/backup_folder_service.dart';
import 'package:path/path.dart' as path;

void main() {
  test('pasta escolhida lista e remove só backups automáticos do app', () async {
    if (!Platform.isWindows) return;
    final root = await Directory.systemTemp.createTemp('organiza-folder-test-');
    addTearDown(() => root.delete(recursive: true));
    final source = File(path.join(root.path, 'source'));
    await source.writeAsBytes([1, 2, 3]);
    final unrelated = File(path.join(root.path, 'extrato.organizabak'));
    await unrelated.writeAsBytes([9]);
    const service = BackupFolderService();
    const name = 'organiza-auto-2026-10-30-abc.organizabak';

    expect(await service.configured(root.path), isTrue);
    await service.save(source, name, root.path);
    expect(await service.list(root.path), [name]);
    await service.delete(name, root.path);
    expect(await service.list(root.path), isEmpty);
    expect(await unrelated.readAsBytes(), [9]);
    await expectLater(
        service.delete('extrato.organizabak', root.path), throwsArgumentError);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:organiza/services/app_storage_paths.dart';
import 'package:organiza/services/local_image_service.dart';

void main() {
  late Directory sandbox;
  late Directory privateRoot;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('organiza-image-test-');
    privateRoot = Directory(path.join(sandbox.path, 'private'));
    await AppStoragePaths.initialize(root: privateRoot);
  });

  tearDown(() async {
    AppStoragePaths.resetForTesting();
    await sandbox.delete(recursive: true);
  });

  test('copia imagem e guarda uma referência relativa à raiz privada',
      () async {
    final source = File(path.join(sandbox.path, 'photo.PNG'));
    await source.writeAsBytes([1, 2, 3, 4]);

    final reference = await LocalImageService.storeFile(source);

    expect(reference, matches(r'^images/[a-f0-9-]+\.png$'));
    expect(path.isAbsolute(reference!), isFalse);
    final stored = LocalImageService.fileFor(reference);
    expect(stored.parent.path, path.join(privateRoot.path, 'images'));
    expect(await stored.readAsBytes(), [1, 2, 3, 4]);
    await source.delete();
    expect(LocalImageService.exists(reference), isTrue);
  });

  test('resolve a mesma referência depois de mover a pasta privada', () async {
    final images = Directory(path.join(privateRoot.path, 'images'));
    await File(path.join(images.path, 'portable.jpg')).writeAsBytes([7, 8]);
    final destination = Directory(path.join(sandbox.path, 'restored'));
    await privateRoot.rename(destination.path);
    await AppStoragePaths.initialize(root: destination);

    expect(await LocalImageService.fileFor('images/portable.jpg').readAsBytes(),
        [7, 8]);
    expect(AppStoragePaths.rootDirectory.path, destination.path);
  });

  test('rejeita caminhos relativos que escapam de images', () {
    for (final reference in [
      '../outside.png',
      'images/../../outside.png',
      'images/../outside.png',
      r'images\..\outside.png',
      'images//photo.png',
      './images/photo.png',
      'other/photo.png',
      'images/nested/photo.png',
      'images/photo.png:secret',
      'images/photo\u0000.png',
    ]) {
      expect(() => LocalImageService.fileFor(reference), throwsFormatException,
          reason: reference);
      expect(LocalImageService.exists(reference), isFalse);
    }
  });

  test('rejeita arquivo ausente, extensão não permitida e imagem muito grande',
      () async {
    final unsupported = File(path.join(sandbox.path, 'document.svg'));
    await unsupported.writeAsString('<svg/>');
    final large = File(path.join(sandbox.path, 'large.jpg'));
    final output = await large.open(mode: FileMode.write);
    await output.truncate(LocalImageService.maxBytes + 1);
    await output.close();

    expect(await LocalImageService.storeFile(unsupported), isNull);
    expect(await LocalImageService.storeFile(large), isNull);
    expect(
        await LocalImageService.storeFile(
            File(path.join(sandbox.path, 'missing.png'))),
        isNull);
    expect(AppStoragePaths.imageDirectory.listSync(), isEmpty);
  });

  test('migra referências absolutas por cópia sem perder os originais',
      () async {
    final legacy = File(path.join(sandbox.path, 'legacy.jpeg'));
    await legacy.writeAsBytes([4, 5, 6]);
    expect(LocalImageService.exists(legacy.path), isTrue);

    final replacements = await LocalImageService.importLegacyImages([
      legacy.path,
      legacy.path,
      path.join(sandbox.path, 'missing.png'),
      'images/already-relative.png',
    ]);

    expect(replacements.keys, [legacy.path]);
    final reference = replacements[legacy.path]!;
    expect(reference, startsWith('images/'));
    expect(await LocalImageService.fileFor(reference).readAsBytes(), [4, 5, 6]);
    expect(await legacy.readAsBytes(), [4, 5, 6]);
    expect(AppStoragePaths.imageDirectory.listSync(), hasLength(1));
  });

  test('não importa extensões indevidas nem imagens acima de dez megabytes',
      () async {
    final unsupported = File(path.join(sandbox.path, 'unsafe.txt'));
    await unsupported.writeAsString('text');
    final oversized = File(path.join(sandbox.path, 'oversized.png'));
    final output = await oversized.open(mode: FileMode.write);
    await output.truncate(LocalImageService.maxBytes + 1);
    await output.close();

    expect(
        await LocalImageService.importLegacyImages([
          unsupported.path,
          oversized.path,
        ]),
        isEmpty);
    expect(await unsupported.exists(), isTrue);
    expect(await oversized.exists(), isTrue);
    expect(AppStoragePaths.imageDirectory.listSync(), isEmpty);
  });
}

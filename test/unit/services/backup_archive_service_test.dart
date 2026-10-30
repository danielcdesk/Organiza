import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/services/backup_archive_service.dart';
import 'package:organiza/services/backup_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporary;
  const password = 'senha-segura';
  const service = BackupArchiveService();
  const crypto = BackupService();
  final createdAt = DateTime.utc(2026, 10, 29, 12);

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('organiza-archive-test-');
  });
  tearDown(() async {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  });

  Future<File> protect(List<int> zip,
      {String name = 'input.organizabak'}) async {
    final envelope =
        await crypto.encryptBytes(Uint8List.fromList(zip), password);
    return File(path.join(temporary.path, name))
      ..writeAsStringSync(jsonEncode(envelope));
  }

  Future<List<int>> zipFixture(
      {Map<String, List<int>>? content,
      bool wrongHash = false,
      int? imageCount}) async {
    final entries = content ??
        {
          'organiza.db': [1, 2, 3],
          'images/photo.png': [7, 8, 9]
        };
    final files = <String, Object?>{};
    for (final entry in entries.entries) {
      final digest = await Sha256().hash(entry.value);
      files[entry.key] = {
        'size': entry.value.length,
        'sha256': wrongHash
            ? '0' * 64
            : digest.bytes
                .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                .join()
      };
    }
    final manifest = {
      'format': 'organiza.backup',
      'version': 2,
      'appVersion': '0.9.0+13',
      'schemaVersion': 16,
      'createdAt': createdAt.toIso8601String(),
      'tableCounts': {'accounts': 1},
      'imageCount': imageCount ??
          entries.keys.where((name) => name.startsWith('images/')).length,
      'fileCount': entries.length,
      'files': files
    };
    final archive = Archive()
      ..add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    for (final entry in entries.entries) {
      archive.add(ArchiveFile.bytes(entry.key, entry.value));
    }
    return ZipEncoder().encode(archive);
  }

  test('roundtrip v2 preserva bytes do banco e imagens com manifesto completo',
      () async {
    final database = File(path.join(temporary.path, 'source.db'))
      ..writeAsBytesSync([0, 255, 1, 2]);
    final images = Directory(path.join(temporary.path, 'source-images'))
      ..createSync();
    File(path.join(images.path, 'photo.png')).writeAsBytesSync([9, 8, 7]);
    final destination = File(path.join(temporary.path, 'copy.organizabak'));
    await service.export(
        database: database,
        imageDirectory: images,
        tableCounts: {'accounts': 2},
        schemaVersion: 16,
        password: password,
        destination: destination,
        createdAt: createdAt);
    expect(await destination.exists(), isTrue);
    final envelope =
        jsonDecode(await destination.readAsString()) as Map<String, dynamic>;
    expect(envelope['version'], 2);
    final prepared = await service.prepare(
        destination, password, Directory(path.join(temporary.path, 'staging')));
    expect(prepared.isLegacy, isFalse);
    expect(await prepared.database!.readAsBytes(), [0, 255, 1, 2]);
    expect(
        await File(path.join(prepared.images!.path, 'photo.png')).readAsBytes(),
        [9, 8, 7]);
    expect(prepared.manifest['tableCounts'], {'accounts': 2});
    expect(prepared.manifest['createdAt'], '2026-10-29T12:00:00.000Z');
    expect(prepared.manifest['imageCount'], 1);
    expect((prepared.manifest['files'] as Map)['organiza.db'], {
      'size': 4,
      'sha256':
          '2f87beacb6a71f75e3243ce005faf5d99405e02b5e729c7c9c216ef2e2a0544a',
    });
  });

  test('senha incorreta e adulteração falham sem alterar a pasta de destino',
      () async {
    final source = await protect(await zipFixture());
    final staging = Directory(path.join(temporary.path, 'staging'))
      ..createSync();
    final sentinel = File(path.join(staging.path, 'original'))
      ..writeAsStringSync('original');
    await expectLater(service.prepare(source, 'senha-incorreta', staging),
        throwsA(isA<Exception>()));
    final envelope =
        jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    final box = base64Decode(envelope['box'] as String)..[15] ^= 1;
    envelope['box'] = base64Encode(box);
    source.writeAsStringSync(jsonEncode(envelope));
    await expectLater(
        service.prepare(source, password, staging), throwsA(isA<Exception>()));
    expect(sentinel.readAsStringSync(), 'original');
    expect(staging.listSync(), hasLength(1));
  });

  test('rejeita caminhos absolutos, travessia e arquivos fora do contrato',
      () async {
    for (final name in [
      '../escape.png',
      '/escape.png',
      r'C:\escape.png',
      'images/../escape.png',
      r'images\escape.png',
      'images/secret.txt',
      'images/CON.png'
    ]) {
      final source = await protect(await zipFixture(content: {
        'organiza.db': [1],
        name: [2]
      }));
      final staging = Directory(path.join(temporary.path, 'staging'));
      await expectLater(
          service.prepare(source, password, staging), throwsFormatException,
          reason: name);
      expect(staging.existsSync(), isFalse);
    }
  });

  test('rejeita hashes e contagens inconsistentes antes de escrever arquivos',
      () async {
    for (final zip in [
      await zipFixture(wrongHash: true),
      await zipFixture(imageCount: 99)
    ]) {
      final source = await protect(zip);
      final staging = Directory(path.join(temporary.path, 'staging'));
      await expectLater(
          service.prepare(source, password, staging), throwsFormatException);
      expect(staging.existsSync(), isFalse);
    }
  });

  test('rejeita duplicatas mesmo quando o decodificador ZIP as substituiria',
      () async {
    final zip = Uint8List.fromList(await zipFixture(content: {
      'organiza.db': [1],
      'images/a.png': [2],
      'images/b.png': [3]
    }));
    final search = utf8.encode('images/b.png');
    for (var i = 0; i <= zip.length - search.length; i++) {
      if (List.generate(search.length, (offset) => zip[i + offset]).join(',') ==
          search.join(',')) {
        zip[i + 7] = 'a'.codeUnitAt(0);
      }
    }
    await expectLater(
        service.prepare(await protect(zip), password,
            Directory(path.join(temporary.path, 'staging'))),
        throwsFormatException);
  });

  test('recusa tamanho e número de entradas declarados antes da descompressão',
      () async {
    final original = Uint8List.fromList(await zipFixture());
    final huge = Uint8List.fromList(original);
    final bytes = ByteData.sublistView(huge);
    for (var i = 0; i < huge.length - 46; i++) {
      if (bytes.getUint32(i, Endian.little) == 0x02014b50) {
        bytes.setUint32(i + 24, 200 * 1024 * 1024, Endian.little);
        break;
      }
    }
    await expectLater(
        service.prepare(await protect(huge), password,
            Directory(path.join(temporary.path, 'large'))),
        throwsFormatException);
    final many = Uint8List.fromList(original);
    final directory = ByteData.sublistView(many);
    directory.setUint16(many.length - 22 + 8, 10003, Endian.little);
    directory.setUint16(many.length - 22 + 10, 10003, Endian.little);
    await expectLater(
        service.prepare(await protect(many), password,
            Directory(path.join(temporary.path, 'many'))),
        throwsFormatException);
  });

  test('recusa symlink ZIP e mantém destino existente em falha de exportação',
      () async {
    final archive = Archive()
      ..add(ArchiveFile.bytes('images/photo.png', utf8.encode('../secret'))
        ..symbolicLink = '../secret'
        ..mode = 0xA1FF);
    await expectLater(
        service.prepare(await protect(ZipEncoder().encode(archive)), password,
            Directory(path.join(temporary.path, 'symlink'))),
        throwsFormatException);
    final database = File(path.join(temporary.path, 'source.db'))
      ..writeAsBytesSync([1]);
    final images = Directory(path.join(temporary.path, 'images'))..createSync();
    File(path.join(images.path, 'secret.txt'))
        .writeAsStringSync('not an image');
    final destination = File(path.join(temporary.path, 'existing'))
      ..writeAsStringSync('original');
    await expectLater(
        service.export(
            database: database,
            imageDirectory: images,
            tableCounts: {},
            schemaVersion: 16,
            password: password,
            destination: destination,
            createdAt: createdAt),
        throwsFormatException);
    expect(destination.readAsStringSync(), 'original');
  });

  test('lê backup legado criptografado v1 e wrapper JSON sem criptografia',
      () async {
    final snapshot = <String, dynamic>{
      'schemaVersion': 16,
      'tables': {'accounts': <Map<String, dynamic>>[]}
    };
    final legacy = File(path.join(temporary.path, 'legacy.backup'));
    legacy.writeAsStringSync(
        jsonEncode(await crypto.encryptContent(snapshot, password)));
    final prepared = await service.prepare(
        legacy, password, Directory(path.join(temporary.path, 'legacy')));
    expect(prepared.isLegacy, isTrue);
    expect(prepared.legacySnapshot, snapshot);
    expect(prepared.database, isNull);
    legacy.writeAsStringSync(jsonEncode(
        {'format': 'organiza.json', 'version': 1, 'content': snapshot}));
    expect(
        (await service.prepare(
                legacy, '', Directory(path.join(temporary.path, 'plain'))))
            .legacySnapshot,
        snapshot);
    legacy.writeAsStringSync(jsonEncode(
        {'format': 'organiza.json', 'version': 1, 'content': 'invalid'}));
    await expectLater(
        service.prepare(legacy, '', temporary), throwsFormatException);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/services/app_storage_paths.dart';
import 'package:organiza/services/attachment_storage_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory sandbox;
  const service = AttachmentStorageService();

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('organiza-attachment-');
    await AppStoragePaths.initialize(
        root: Directory(path.join(sandbox.path, 'private')));
  });
  tearDown(() async {
    AppStoragePaths.resetForTesting();
    await sandbox.delete(recursive: true);
  });

  test('valida assinatura, copia para pasta privada e confere hash', () async {
    final pdf = await service.storeBytes('%PDF-1.7 fake'.codeUnits, '.pdf');
    expect(pdf.mimeType, 'application/pdf');
    expect(pdf.relativePath, startsWith('attachments/'));
    expect(
        await service.readVerified(
            relativePath: pdf.relativePath,
            sizeBytes: pdf.sizeBytes,
            sha256: pdf.sha256),
        '%PDF-1.7 fake'.codeUnits);
  });

  test(
      'rejeita extensão/content mismatch, conteúdo desconhecido e caminhos inseguros',
      () async {
    await expectLater(
        service.storeBytes([1, 2, 3], '.pdf'), throwsFormatException);
    await expectLater(service.storeBytes('%PDF-1.7'.codeUnits, '.txt'),
        throwsFormatException);
    for (final value in [
      '../x.pdf',
      r'attachments\x.pdf',
      'attachments/../x.pdf'
    ]) {
      expect(() => service.fileFor(value), throwsFormatException);
    }
  });

  test('reconhece assinaturas permitidas e limita tamanho', () async {
    final samples = <String, List<int>>{
      '.jpg': [0xff, 0xd8, 0xff, 0x00],
      '.jpeg': [0xff, 0xd8, 0xff, 0x00],
      '.png': [137, 80, 78, 71, 13, 10, 26, 10],
      '.webp': [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits],
      '.gif': 'GIF89a'.codeUnits,
      '.pdf': '%PDF-1.7'.codeUnits,
    };
    for (final sample in samples.entries) {
      final stored = await service.storeBytes(sample.value, sample.key);
      expect(stored.sizeBytes, sample.value.length);
    }
    await expectLater(
      service.storeBytes(
        List<int>.filled(AttachmentStorageService.maxBytes + 1, 0),
        '.pdf',
      ),
      throwsFormatException,
    );
  });
}

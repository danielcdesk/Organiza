import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/data/local_repository.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/services/app_storage_paths.dart';
import 'package:organiza/services/backup_coordinator.dart';
import 'package:organiza/services/backup_service.dart';
import 'package:organiza/services/attachment_storage_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory sandbox;
  late LocalRepository repository;
  late BackupCoordinator backups;

  setUp(() async {
    sandbox =
        await Directory.systemTemp.createTemp('organiza-coordinator-test-');
    await AppStoragePaths.initialize(root: sandbox);
    repository = LocalRepository.openAtFile(
        File(path.join(sandbox.path, 'organiza.db')));
    backups = BackupCoordinator(repository);
  });

  tearDown(() async {
    repository.close();
    AppStoragePaths.resetForTesting();
    await sandbox.delete(recursive: true);
  });

  test('exporta, mostra prévia e restaura preferências e imagens', () async {
    repository.insertAccount(Account(
      id: 'conta',
      name: 'Principal',
      openingBalanceInCents: 100000,
      createdAt: DateTime(2026, 10, 1),
    ));
    repository.insertTransaction(TransactionRecord(
      id: 'compra',
      accountId: 'conta',
      type: TransactionType.expense,
      amountInCents: 12345,
      description: 'Compra',
      occurredOn: DateTime(2026, 10, 2),
      createdAt: DateTime(2026, 10, 2),
    ));
    repository.savePreference('profile_name', 'Antes');
    repository.savePreference('profile_photo_path', 'images/foto.png');
    final tag =
        Tag(id: 'tag-casa', name: 'Casa', createdAt: DateTime(2026, 10, 1));
    repository.insertTag(tag);
    repository.setTransactionTags('compra', {tag.id});
    final receiptBytes = '%PDF-1.7'.codeUnits;
    final receiptHash =
        await const AttachmentStorageService().sha256For(receiptBytes);
    final attachment = Attachment(
        id: 'anexo-recibo',
        transactionId: 'compra',
        relativePath: 'attachments/recibo.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 8,
        sha256: receiptHash,
        createdAt: DateTime(2026, 10, 2));
    repository.insertAttachment(attachment);
    final image =
        File(path.join(AppStoragePaths.imageDirectory.path, 'foto.png'));
    await image.writeAsBytes([1, 2, 3]);
    final receipt =
        File(path.join(AppStoragePaths.attachmentDirectory.path, 'recibo.pdf'));
    await receipt.writeAsBytes(receiptBytes);
    await File(
            path.join(AppStoragePaths.attachmentDirectory.path, 'orphan.exe'))
        .writeAsString('unreferenced');
    final archive = File(path.join(sandbox.path, 'backup.organizabak'));
    await backups.export('senha-segura', archive);

    repository.savePreference('profile_name', 'Depois');
    repository.softDelete(
      SoftDeleteEntity.transaction,
      'compra',
      DateTime.utc(2026, 2, 3),
    );
    await image.delete();
    await receipt.delete();
    final preview = await backups.prepare(archive, 'senha-segura');
    expect(preview.counts['app_settings'], greaterThan(0));
    expect(preview.manifest['attachmentCount'], 1);
    expect(repository.loadPreference('profile_name'), 'Depois');
    final safety = await backups.confirm(preview);

    expect(await safety.exists(), isTrue);
    expect(repository.loadPreference('profile_name'), 'Antes');
    expect(
        FinancialRules.currentBalance(
            repository.loadAccounts(), repository.loadTransactions()),
        87655);
    expect(repository.loadPreference('profile_photo_path'), 'images/foto.png');
    expect(await image.readAsBytes(), [1, 2, 3]);
    expect(await receipt.readAsBytes(), '%PDF-1.7'.codeUnits);
    expect(repository.loadTransactionTags('compra').single.id, tag.id);
    expect(repository.loadAttachments('compra').single.id, attachment.id);
    expect(
        AppStoragePaths.attachmentDirectory
            .listSync()
            .where((e) => path.basename(e.path) == 'orphan.exe'),
        isNotEmpty);
  });

  test('conflito de anexo cancela restore sem copiar anexos parciais',
      () async {
    final now = DateTime.utc(2026, 10, 1);
    repository.insertAccount(Account(
        id: 'a',
        name: 'Principal',
        openingBalanceInCents: 10000,
        createdAt: now));
    repository.insertTransaction(TransactionRecord(
        id: 't',
        accountId: 'a',
        type: TransactionType.expense,
        amountInCents: 100,
        description: 'Compra',
        occurredOn: now,
        createdAt: now));
    const storage = AttachmentStorageService();
    final entries = <(String, List<int>, String)>[
      ('first.pdf', '%PDF-first'.codeUnits, 'first'),
      ('second.pdf', '%PDF-second'.codeUnits, 'second'),
    ];
    for (final entry in entries) {
      await File(path.join(AppStoragePaths.attachmentDirectory.path, entry.$1))
          .writeAsBytes(entry.$2);
      repository.insertAttachment(Attachment(
          id: entry.$3,
          transactionId: 't',
          relativePath: 'attachments/${entry.$1}',
          mimeType: 'application/pdf',
          sizeBytes: entry.$2.length,
          sha256: await storage.sha256For(entry.$2),
          createdAt: now));
    }
    final archive =
        File(path.join(sandbox.path, 'restore-conflict.organizabak'));
    await backups.export('senha-segura', archive);
    repository.savePreference('profile_name', 'Atual');
    await File(path.join(AppStoragePaths.attachmentDirectory.path, 'first.pdf'))
        .delete();
    final second =
        File(path.join(AppStoragePaths.attachmentDirectory.path, 'second.pdf'));
    await second.writeAsBytes('%PDF-conflict'.codeUnits);
    final preview = await backups.prepare(archive, 'senha-segura');

    await expectLater(backups.confirm(preview), throwsFormatException);
    expect(
        await File(path.join(
                AppStoragePaths.attachmentDirectory.path, 'first.pdf'))
            .exists(),
        isFalse);
    expect(await second.readAsBytes(), '%PDF-conflict'.codeUnits);
    expect(repository.loadPreference('profile_name'), 'Atual');
  });

  test('export rejeita anexo alterado e não produz backup parcial', () async {
    final now = DateTime.utc(2026, 10, 1);
    repository.insertAccount(Account(
        id: 'a',
        name: 'Principal',
        openingBalanceInCents: 10000,
        createdAt: now));
    repository.insertTransaction(TransactionRecord(
        id: 't',
        accountId: 'a',
        type: TransactionType.expense,
        amountInCents: 100,
        description: 'Compra',
        occurredOn: now,
        createdAt: now));
    final bytes = '%PDF-original'.codeUnits;
    await File(
            path.join(AppStoragePaths.attachmentDirectory.path, 'receipt.pdf'))
        .writeAsBytes(bytes);
    repository.insertAttachment(Attachment(
        id: 'receipt',
        transactionId: 't',
        relativePath: 'attachments/receipt.pdf',
        mimeType: 'application/pdf',
        sizeBytes: bytes.length,
        sha256: '0' * 64,
        createdAt: now));
    final destination = File(path.join(sandbox.path, 'invalid.organizabak'));

    await expectLater(
        backups.export('senha-segura', destination), throwsFormatException);
    expect(await destination.exists(), isFalse);
  });

  test('senha errada não altera dados atuais', () async {
    repository.savePreference('profile_name', 'Original');
    final archive = File(path.join(sandbox.path, 'backup.organizabak'));
    await backups.export('senha-segura', archive);
    repository.savePreference('profile_name', 'Atual');
    await expectLater(
        backups.prepare(archive, 'senha-errada'), throwsFormatException);
    expect(repository.loadPreference('profile_name'), 'Atual');
  });

  test('falha de imagem antes da troca mantém o banco original', () async {
    repository.savePreference('profile_name', 'No backup');
    final image =
        File(path.join(AppStoragePaths.imageDirectory.path, 'foto.png'));
    await image.writeAsBytes([1, 2, 3]);
    final archive = File(path.join(sandbox.path, 'backup.organizabak'));
    await backups.export('senha-segura', archive);
    repository.savePreference('profile_name', 'Atual');
    await image.writeAsBytes([9, 9, 9]);

    final preview = await backups.prepare(archive, 'senha-segura');
    await expectLater(backups.confirm(preview), throwsFormatException);

    expect(repository.loadPreference('profile_name'), 'Atual');
    expect(await image.readAsBytes(), [9, 9, 9]);
    expect(
        await File('${repository.filePath}.pre-restore.bak').exists(), isTrue);
  });

  test('lê e confirma backup criptografado legado v1', () async {
    repository.savePreference('profile_name', 'Legado');
    final archive = File(path.join(sandbox.path, 'antigo.backup'));
    await const BackupService().exportEncrypted(
        repository.exportSnapshot(), 'senha-segura',
        destination: archive);
    repository.savePreference('profile_name', 'Atual');

    final preview = await backups.prepare(archive, 'senha-segura');
    expect(preview.isLegacy, isTrue);
    await backups.confirm(preview);

    expect(repository.loadPreference('profile_name'), 'Legado');
  });
}

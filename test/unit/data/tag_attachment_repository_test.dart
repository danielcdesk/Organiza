import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

void main() {
  test('migração 20→21 mantém dados e cria as três tabelas', () async {
    final folder = await Directory.systemTemp.createTemp('organiza-v21-');
    addTearDown(() => folder.delete(recursive: true));
    final source = AppDatabase.openInMemoryAtVersionForTest(20);
    addTearDown(source.close);
    final now = DateTime.utc(2026, 3, 4);
    source.insertAccount(Account(id: 'account', name: 'Principal',
      openingBalanceInCents: 5000, createdAt: now));
    source.insertTransaction(TransactionRecord(id: 'transaction', accountId: 'account',
      type: TransactionType.expense, amountInCents: 1200, description: 'Mercado',
      occurredOn: now, createdAt: now));
    final file = File(path.join(folder.path, 'organiza.db'));
    await source.createConsistentCopy(file);
    final migrated = AppDatabase.openFile(file);
    addTearDown(migrated.close);
    expect(migrated.schemaVersion, 21);
    expect(migrated.loadTransactions().single.description, 'Mercado');
    expect(migrated.tableCounts['tags'], 0);
    expect(migrated.tableCounts['transaction_tags'], 0);
    expect(migrated.tableCounts['attachments'], 0);
    expect(File('${file.path}.pre-v21.bak').existsSync(), isTrue);
    migrated.validateIntegrity();
  });

  test(
      'tags têm nome único sem diferenciar maiúsculas e vínculos substituíveis',
      () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 3, 4);
    database.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 5000,
      createdAt: now,
    ));
    database.insertTransaction(TransactionRecord(
      id: 'transaction',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 100,
      description: 'Mercado',
      occurredOn: now,
      createdAt: now,
    ));
    final food = Tag(id: 'food', name: 'Mercado', createdAt: now);
    final urgent = Tag(
        id: 'urgent',
        name: 'Importante',
        colorValue: 0xFFAA3300,
        createdAt: now);
    database.insertTag(food);
    database.insertTag(urgent);

    expect(database.loadTags().map((tag) => tag.id), ['urgent', 'food']);
    expect(
      () => database
          .insertTag(Tag(id: 'duplicate', name: 'MERCADO', createdAt: now)),
      throwsA(isA<SqliteException>()),
    );
    database.setTransactionTags('transaction', {'food', 'urgent'});
    expect(database.loadTransactionTags('transaction').map((tag) => tag.id),
        ['urgent', 'food']);
    database.setTransactionTags('transaction', {'urgent'});
    expect(database.loadTransactionTags('transaction').map((tag) => tag.id),
        ['urgent']);
    expect(
      () => database.setTransactionTags('transaction', {'missing'}),
      throwsArgumentError,
    );
    expect(
      () => database.insertAttachment(Attachment(
        id: 'invalid-size',
        transactionId: 'transaction',
        relativePath: 'attachments/invalid.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 0,
        sha256: 'b' * 64,
        createdAt: now,
      )),
      throwsA(isA<SqliteException>()),
    );

    database.deleteTag('urgent');
    expect(database.loadTransactionTags('transaction'), isEmpty);
  });

  test('anexos persistem metadados e vínculos durante exclusão lógica', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 3, 4);
    database.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 5000,
      createdAt: now,
    ));
    database.insertTransaction(TransactionRecord(
      id: 'transaction',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 100,
      description: 'Mercado',
      occurredOn: now,
      createdAt: now,
    ));
    final receipt = Attachment(
      id: 'receipt',
      transactionId: 'transaction',
      relativePath: 'attachments/receipt.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 123,
      sha256: 'a' * 64,
      createdAt: now,
    );
    database.insertAttachment(receipt);

    expect(database.loadAttachments('transaction').single.relativePath,
        receipt.relativePath);
    database.softDelete(SoftDeleteEntity.transaction, 'transaction', now);
    expect(database.loadAttachments('transaction').single.id, receipt.id);
    expect(
        database.restore(SoftDeleteEntity.transaction, 'transaction'), isTrue);

    expect(database.deleteAttachment('receipt'), receipt.relativePath);
    expect(database.loadAttachments('transaction'), isEmpty);
  });

  test('snapshot restaura tags, vínculos e metadados de anexos', () {
    final source = AppDatabase.openInMemory();
    addTearDown(source.close);
    final now = DateTime.utc(2026, 3, 4);
    source.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 5000,
      createdAt: now,
    ));
    source.insertTransaction(TransactionRecord(
      id: 'transaction',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 100,
      description: 'Mercado',
      occurredOn: now,
      createdAt: now,
    ));
    source.insertTag(Tag(id: 'tag', name: 'Casa', createdAt: now));
    source.setTransactionTags('transaction', {'tag'});
    source.insertAttachment(Attachment(
      id: 'attachment',
      transactionId: 'transaction',
      relativePath: 'attachments/a.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 123,
      sha256: 'c' * 64,
      createdAt: now,
    ));
    final snapshot = Map<String, dynamic>.from(source.exportSnapshot());
    final restored = AppDatabase.openInMemory();
    addTearDown(restored.close);

    restored.restoreSnapshot(snapshot);

    expect(restored.loadTags().single.name, 'Casa');
    expect(restored.loadTransactionTags('transaction').single.id, 'tag');
    expect(restored.loadAttachments('transaction').single.id, 'attachment');
    restored.validateIntegrity();
  });
}

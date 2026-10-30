import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/services/backup_service.dart';

void main() {
  test('bytes v2 preservam conteúdo binário e autenticam metadados', () async {
    const service = BackupService();
    final bytes = Uint8List.fromList([0, 255, 80, 75, 1, 2, 3]);
    final envelope = await service.encryptBytes(bytes, 'senha-segura');
    expect(envelope['version'], 2);
    expect(await service.decryptBytes(envelope, 'senha-segura'), bytes);
    final changedDate = Map<String, dynamic>.from(envelope)
      ..['exportedAt'] = '2020-01-01T00:00:00.000Z';
    await expectLater(service.decryptBytes(changedDate, 'senha-segura'),
        throwsA(isA<Exception>()));
    final changed = Map<String, dynamic>.from(envelope)
      ..['contentType'] = 'text/plain';
    await expectLater(service.decryptBytes(changed, 'senha-segura'),
        throwsA(isA<Exception>()));
    await expectLater(service.decryptBytes(envelope, 'senha-incorreta'),
        throwsA(isA<Exception>()));
    final tampered = Map<String, dynamic>.from(envelope);
    final box = base64Decode(tampered['box'] as String)..[15] ^= 1;
    tampered['box'] = base64Encode(box);
    await expectLater(service.decryptBytes(tampered, 'senha-segura'),
        throwsA(isA<Exception>()));
  });

  test('bytes v2 rejeitam KDF alterado e payload além do limite', () async {
    const service = BackupService();
    final envelope = await service.encryptBytes(Uint8List(2), 'senha-segura');
    final expensive = Map<String, dynamic>.from(envelope)
      ..['kdfMemory'] = 999999999;
    await expectLater(
        service.decryptBytes(expensive, 'senha-segura'), throwsFormatException);
    final wrongSalt = Map<String, dynamic>.from(envelope)
      ..['salt'] = base64Encode([1]);
    await expectLater(
        service.decryptBytes(wrongSalt, 'senha-segura'), throwsFormatException);
    final shortBox = Map<String, dynamic>.from(envelope)..['box'] = 'AQ==';
    await expectLater(
        service.decryptBytes(shortBox, 'senha-segura'), throwsFormatException);
    await expectLater(
        service.encryptBytes(
            Uint8List(BackupService.maxPayloadBytes + 1), 'senha-segura'),
        throwsArgumentError);
  });
  test('backup criptografado autentica e rejeita senha incorreta', () async {
    const service = BackupService();
    final envelope = await service.encryptContent(
      const {
        'schemaVersion': 16,
        'tables': {'accounts': <Map<String, Object?>>[]},
      },
      'senha-segura',
    );

    final restored = await service.decryptContent(envelope, 'senha-segura');
    expect(restored['schemaVersion'], 16);
    expect(
      () => service.decryptContent(envelope, 'senha-incorreta'),
      throwsA(anything),
    );
  });

  test('snapshot restaura dados com transação e integridade referencial', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    final now = DateTime(2026, 9, 28);
    database.insertAccount(Account(
      id: 'account-1',
      name: 'Principal',
      openingBalanceInCents: 1000,
      createdAt: now,
    ));
    database.insertCreditCard(CreditCard(
      id: 'card-1',
      name: 'Principal',
      brand: CardBrand.visa,
      lastFour: '4242',
      limitInCents: 500000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xFF245943,
      createdAt: now,
    ));
    database.insertCardPurchase(CardPurchase(
      id: 'purchase-1',
      cardId: 'card-1',
      description: 'Notebook',
      amountInCents: 120000,
      purchasedOn: now,
      installments: 3,
      createdAt: now,
    ));
    database.setCardPurchaseInstallmentsPaid(
      'purchase-1',
      {1, 3},
      now,
    );
    final snapshot = database.exportSnapshot();

    database.insertAccount(Account(
      id: 'account-2',
      name: 'Reserva',
      openingBalanceInCents: 2000,
      createdAt: now,
    ));
    expect(database.loadAccounts(), hasLength(2));

    database.restoreSnapshot(Map<String, dynamic>.from(snapshot));
    expect(database.loadAccounts(), hasLength(1));
    expect(database.loadAccounts().single.name, 'Principal');
    expect(database.loadCardPurchases().single.paidInstallments, {1, 3});
  });

  test('transação local faz rollback quando uma operação falha', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    expect(
      () => database.transaction(() {
        database.insertAccount(Account(
          id: 'account-rollback',
          name: 'Temporária',
          openingBalanceInCents: 0,
          createdAt: DateTime(2026, 9, 28),
        ));
        throw StateError('falha simulada');
      }),
      throwsStateError,
    );
    expect(database.loadAccounts(), isEmpty);
  });
}

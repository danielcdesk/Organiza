import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/services/backup_service.dart';
import 'package:organiza/services/backup_images.dart';

void main() {
  test('imagens de perfil, compra e meta ficam no envelope criptografado',
      () async {
    final temporary =
        Directory.systemTemp.createTempSync('organiza-image-test-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final original = File('${temporary.path}${Platform.pathSeparator}goal.png')
      ..writeAsBytesSync([137, 80, 78, 71, 1, 2, 3]);
    final snapshot = await BackupImages.embed({
      'schemaVersion': 24,
      'tables': {
        'app_settings': [
          {'key': 'profile_photo_path', 'value': original.path}
        ],
        'shopping_items': [
          {'image_path': original.path}
        ],
        'financial_goals': [
          {'image_path': original.path}
        ],
      },
    });
    expect(snapshot.toString(), isNot(contains(original.path)));
    const service = BackupService();
    final envelope = await service.encryptContent(snapshot, 'senha-segura');
    final decrypted = await service.decryptContent(envelope, 'senha-segura');
    final restored = await BackupImages.restore(decrypted,
        targetDirectory:
            Directory('${temporary.path}${Platform.pathSeparator}restored'));
    final tables = restored['tables'] as Map;
    for (final (table, column) in [
      ('app_settings', 'value'),
      ('shopping_items', 'image_path'),
      ('financial_goals', 'image_path')
    ]) {
      final row = (tables[table] as List).single as Map;
      final path = row[column] as String;
      expect(File(path).readAsBytesSync(), original.readAsBytesSync());
      expect(path, isNot(original.path));
    }
  });
  test('backup criptografado autentica e rejeita senha incorreta', () async {
    const service = BackupService();
    final envelope = await service.encryptContent(
      const {
        'schemaVersion': 15,
        'tables': {'accounts': <Map<String, Object?>>[]},
      },
      'senha-segura',
    );

    final restored = await service.decryptContent(envelope, 'senha-segura');
    expect(restored['schemaVersion'], 15);
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

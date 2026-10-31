import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('conta persiste tipo, moeda, arquivo e inclusão no patrimônio', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 3, 1);
    database.insertAccount(Account(
      id: 'account-lifecycle',
      name: 'Reserva',
      openingBalanceInCents: 40000,
      createdAt: createdAt,
      type: AccountType.savings,
      includeInNetWorth: false,
      currency: 'USD',
    ));

    var account = database.loadAccounts().single;
    expect(account.type, AccountType.savings);
    expect(account.archivedAt, isNull);
    expect(account.includeInNetWorth, isFalse);
    expect(account.currency, 'USD');

    final archivedAt = DateTime.utc(2026, 4, 2);
    expect(
        database.setAccountArchived('account-lifecycle', archivedAt), isTrue);
    account = database.loadAccounts().single;
    expect(account.archivedAt, archivedAt);
    expect(account.openingBalanceInCents, 40000);
    expect(database.setAccountArchived('account-lifecycle', null), isTrue);
    expect(database.loadAccounts().single.archivedAt, isNull);

    database.setAccountNetWorthIncluded('account-lifecycle', true);
    expect(database.loadAccounts().single.includeInNetWorth, isTrue);
  });

  test('leitura de conta em schema 19 usa valores padrão compatíveis', () {
    final database = AppDatabase.openInMemoryAtVersionForTest(19);
    addTearDown(database.close);
    database.insertAccount(Account(
      id: 'account-v19',
      name: 'Histórica',
      openingBalanceInCents: 1200,
      createdAt: DateTime.utc(2026, 1, 1),
    ));

    final account = database.loadAccounts().single;
    expect(account.type, AccountType.checking);
    expect(account.archivedAt, isNull);
    expect(account.includeInNetWorth, isTrue);
    expect(account.currency, 'BRL');
  });
}

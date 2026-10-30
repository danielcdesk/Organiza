import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('rollback atomic remove writes parciais de uma operação financeira', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    final now = DateTime(2026, 10, 30);

    expect(
      () => database.transaction(() {
        database.insertAccount(Account(
          id: 'conta-temporaria',
          name: 'Temporária',
          openingBalanceInCents: 50000,
          createdAt: now,
        ));
        database.insertTransaction(TransactionRecord(
          id: 'pagamento-inválido',
          accountId: 'conta-inexistente',
          type: TransactionType.expense,
          amountInCents: 1000,
          description: 'Pagamento de fatura',
          category: 'Pagamento de cartão',
          occurredOn: now,
          createdAt: now,
          systemType: TransactionSystemType.cardPayment,
        ));
      }),
      throwsA(anything),
    );

    expect(database.loadAccounts(), isEmpty);
    expect(database.loadTransactions(), isEmpty);
  });
}

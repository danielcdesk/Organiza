import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('migração 1 para 8 preserva dados e habilita organização financeira',
      () {
    final database = AppDatabase.openInMemoryFromVersion1ForTest();
    addTearDown(database.close);
    final now = DateTime(2026, 9, 10);

    database.insertAccount(
      Account(
        id: 'account-1',
        name: 'Principal',
        openingBalanceInCents: 100000,
        createdAt: now,
      ),
    );
    database.insertCreditCard(
      CreditCard(
        id: 'card-1',
        name: 'Principal',
        brand: CardBrand.visa,
        lastFour: '4242',
        limitInCents: 500000,
        closingDay: 10,
        dueDay: 17,
        colorValue: 0xFF245943,
        createdAt: now,
      ),
    );
    database.insertTransaction(
      TransactionRecord(
        id: 'transaction-1',
        accountId: 'account-1',
        type: TransactionType.expense,
        amountInCents: 12000,
        description: 'Mercado',
        category: 'Alimentação',
        occurredOn: now,
        createdAt: now,
      ),
    );

    database.insertInvestment(
      InvestmentPosition(
        id: 'investment-1',
        name: 'Tesouro Selic',
        type: InvestmentType.fixedIncome,
        investedAmountInCents: 100000,
        currentValueInCents: 102500,
        createdAt: now,
      ),
    );
    database.insertBudget(Budget(
      id: 'budget-1',
      category: 'Alimentação',
      limitInCents: 50000,
      year: now.year,
      month: now.month,
      createdAt: now,
    ));
    database.insertFinancialGoal(FinancialGoal(
      id: 'goal-1',
      name: 'Reserva',
      targetInCents: 1000000,
      savedInCents: 250000,
      deadline: DateTime(2027, 12, 31),
      createdAt: now,
    ));

    expect(database.schemaVersion, 8);
    expect(database.loadAccounts().single.name, 'Principal');
    expect(
        database.loadAccounts().single.institution, AccountInstitution.generic);
    expect(database.loadCreditCards().single.lastFour, '4242');
    expect(database.loadInvestments().single.currentValueInCents, 102500);
    expect(database.loadTransactions().single.category, 'Alimentação');
    expect(database.loadBudgets().single.limitInCents, 50000);
    expect(database.loadTransactions().single.subcategory, 'Geral');
    expect(database.loadSalaryAllocation().essentialsPercent, 50);
    expect(database.loadFinancialGoals().single.savedInCents, 250000);
    expect(database.loadTransactions().single.scheduleType,
        TransactionScheduleType.single);
    expect(database.loadTransactions().single.isSettled, isTrue);
    expect(
      database
          .loadFinanceSubcategories()
          .any((item) => item.name == 'Cafeterias'),
      isTrue,
    );
  });
}

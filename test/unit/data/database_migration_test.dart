import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/domain/app_route.dart';

void main() {
  test('schema 22 guarda histórico de distribuição no snapshot', () {
    final source = AppDatabase.openInMemoryFromVersion1ForTest();
    addTearDown(source.close);
    expect(source.schemaVersion, 22);
    source.transaction(() {
      source.saveSalaryAllocationForMonth(
          const SalaryAllocation(
              essentialsPercent: 60, goalsPercent: 25, freePercent: 15),
          DateTime(2026, 9));
    });
    expect(source.loadSalaryAllocationForMonth(DateTime(2026, 8)), isNull);
    expect(
        source
            .loadSalaryAllocationForMonth(DateTime(2026, 9))!
            .essentialsPercent,
        60);
    final restored = AppDatabase.openInMemory();
    addTearDown(restored.close);
    restored.restoreSnapshot(source.exportSnapshot());
    expect(
        restored
            .loadSalaryAllocationForMonth(DateTime(2026, 9))!
            .essentialsPercent,
        60);
  });
  test('snapshot do schema 22 inclui dívidas e contas recorrentes', () {
    final source = AppDatabase.openInMemoryFromVersion1ForTest();
    addTearDown(source.close);
    final now = DateTime.utc(2026, 9, 10);
    source.insertAccount(Account(
        id: 'a', name: 'Conta', openingBalanceInCents: 0, createdAt: now));
    source.insertDebt(Debt(
        id: 'd',
        name: 'Empréstimo',
        originalPrincipalInCents: 100000,
        outstandingPrincipalInCents: 100000,
        monthlyInterestBasisPoints: 100,
        installmentAmountInCents: 10000,
        firstDueOn: now,
        installmentsRemaining: 12,
        accountId: 'a',
        category: 'Empréstimos',
        isActive: true,
        createdAt: now));
    source.insertTransaction(TransactionRecord(
        id: 't-debt',
        accountId: 'a',
        type: TransactionType.expense,
        amountInCents: 10000,
        description: 'Parcela',
        occurredOn: now,
        createdAt: now,
        debtPaymentId: 'p'));
    source.insertDebtPayment(DebtPayment(
        id: 'p',
        debtId: 'd',
        transactionId: 't-debt',
        principalInCents: 9000,
        interestInCents: 1000,
        paidOn: now));
    source.insertTransaction(TransactionRecord(
        id: 't-bill',
        accountId: 'a',
        type: TransactionType.expense,
        amountInCents: 12000,
        description: 'Energia',
        occurredOn: now,
        createdAt: now,
        recurringObligationId: 'r'));
    source.insertRecurringObligation(RecurringObligation(
        id: 'r',
        name: 'Energia',
        category: 'Moradia',
        accountId: 'a',
        estimatedAmountInCents: 12000,
        billingDay: 10,
        nextDueOn: now,
        isActive: true,
        createdAt: now));
    source.insertRecurringObligationOccurrence('o', 'r', 't-bill', now);
    final destination = AppDatabase.openInMemory();
    addTearDown(destination.close);
    destination.restoreSnapshot(source.exportSnapshot());
    expect(destination.loadDebts().single.name, 'Empréstimo');
    expect(destination.loadRecurringObligations().single.name, 'Energia');
    expect(destination.loadDebtPayments().single.interestInCents, 1000);
    expect(destination.loadTransactions(), hasLength(2));
  });
  test('schema 22 preserva dados e persiste classificação e fonte', () {
    final database = AppDatabase.openInMemoryFromVersion1ForTest();
    addTearDown(database.close);
    expect(database.schemaVersion, 22);
    expect(database.loadDebts(), isEmpty);
    final category = database.loadFinanceCategories().firstWhere((item) =>
        item.name == 'Alimentação' && item.type == TransactionType.expense);
    expect(category.essentiality, ExpenseEssentiality.unclassified);
    database.setFinanceCategoryEssentiality(
        category.id, ExpenseEssentiality.essential);
    expect(
        database
            .loadFinanceCategories()
            .firstWhere((item) => item.id == category.id)
            .essentiality,
        ExpenseEssentiality.essential);
    final now = DateTime.utc(2026, 9, 10);
    database.insertAccount(Account(
        id: 'a', name: 'Conta', openingBalanceInCents: 0, createdAt: now));
    database.insertTransaction(TransactionRecord(
      id: 't',
      accountId: 'a',
      type: TransactionType.income,
      amountInCents: 1234,
      description: 'Pagamento',
      occurredOn: now,
      createdAt: now,
      incomeSource: 'Trabalho',
      essentialityOverride: ExpenseEssentiality.nonEssential,
    ));
    final loaded = database.loadTransactions().single;
    expect(loaded.incomeSource, 'Trabalho');
    expect(loaded.essentialityOverride, ExpenseEssentiality.nonEssential);
    final snapshot = database.exportSnapshot();
    final restored = AppDatabase.openInMemory();
    addTearDown(restored.close);
    restored.restoreSnapshot(snapshot);
    expect(restored.loadTransactions().single.incomeSource, 'Trabalho');
  });
  test('migração 15 para 22 preserva cartão e compra existentes', () {
    final database = AppDatabase.openInMemoryFromVersion15WithCardForTest();
    addTearDown(database.close);
    expect(database.schemaVersion, 22);
    expect(database.loadCreditCards().single.name, 'Cartão antigo');
    expect(database.loadCreditCards().single.lastFour, '4242');
    expect(database.loadCardPurchases().single.description, 'Compra antiga');
    expect(database.loadTransactions().single.occurredOn,
        DateTime.utc(2025, 1, 2));
    expect(database.loadCardPurchases().single.category, 'Outros');
    database.insertCreditCard(CreditCard(
      id: 'card-31',
      name: 'Fechamento 31',
      brand: CardBrand.mastercard,
      lastFour: '3131',
      limitInCents: 100000,
      closingDay: 31,
      dueDay: 31,
      colorValue: 0xFF245943,
      createdAt: DateTime(2026),
    ));
    expect(database.loadCreditCards().last.closingDay, 31);
  });

  test('migração local preserva dados e habilita novos módulos', () {
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

    expect(database.schemaVersion, 22);
    expect(database.loadAccounts().single.name, 'Principal');
    expect(
        database.loadAccounts().single.institution, AccountInstitution.generic);
    expect(database.loadCreditCards().single.lastFour, '4242');
    expect(database.loadInvestments().single.currentValueInCents, 102500);
    expect(database.loadInvestments().single.quotedRateBasisPoints, isNull);
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
    expect(database.loadShoppingItems(), isEmpty);
    expect(database.loadGoalCategories(), contains('Reserva'));
    expect(database.loadMobileQuickPages(), [
      AppRoute.overview,
      AppRoute.finances,
      AppRoute.organization,
      AppRoute.reports,
    ]);
    expect(database.loadFinanceCategories().any((item) => item.name == 'Pets'),
        isTrue);

    database.insertCreditCard(CreditCard(
      id: 'card-31',
      name: 'Fechamento 31',
      brand: CardBrand.mastercard,
      lastFour: '3131',
      limitInCents: 100000,
      closingDay: 31,
      dueDay: 31,
      colorValue: 0xFF245943,
      createdAt: now,
    ));
    database.insertCardPurchase(CardPurchase(
      id: 'purchase-1',
      cardId: 'card-31',
      description: 'Compra antiga',
      amountInCents: 1234,
      purchasedOn: now,
      installments: 2,
      createdAt: now,
      category: 'Alimentação',
      subcategory: 'Mercado',
    ));
    expect(database.loadCreditCards().last.closingDay, 31);
    expect(database.loadCardPurchases().single.category, 'Alimentação');

    database.updateInvestment(InvestmentPosition(
      id: 'investment-1',
      name: 'Poupança',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 100000,
      currentValueInCents: 103500,
      fixedIncomeType: FixedIncomeType.savings,
      quotedRateBasisPoints: 50,
      quotedRatePeriod: InvestmentRatePeriod.monthly,
      yieldPaymentDay: 10,
      createdAt: now,
    ));
    final updated = database.loadInvestments().single;
    expect(updated.name, 'Poupança');
    expect(updated.currentValueInCents, 103500);
    expect(updated.quotedRateBasisPoints, 50);
    expect(updated.quotedRatePeriod, InvestmentRatePeriod.monthly);
    expect(updated.yieldPaymentDay, 10);
  });
}

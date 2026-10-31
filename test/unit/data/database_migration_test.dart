import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
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

    expect(database.schemaVersion, 20);
    expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
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
    expect(database.loadMobileQuickPages(), [0, 1, 6, 8]);
    expect(database.loadFinanceCategories().any((item) => item.name == 'Pets'),
        isTrue);

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

  test('migração 16 preserva compras existentes e cria controle de parcelas',
      () {
    final database = AppDatabase.openInMemoryFromVersion15ForTest();
    addTearDown(database.close);

    expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(database.loadCardPurchases().single.description, 'Notebook');
    expect(database.loadCardPurchases().single.paidInstallments, isEmpty);
    database.setCardPurchaseInstallmentsPaid(
      'purchase-v15',
      {2},
      DateTime(2026, 10, 28),
    );
    expect(database.loadCardPurchases().single.paidInstallments, {2});
  });

  test('migração schema 18 para 20 preserva dados e inicializa auditoria',
      () async {
    final folder =
        await Directory.systemTemp.createTemp('organiza-soft-delete-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File(path.join(folder.path, 'organiza.db'));
    final source = AppDatabase.openInMemoryAtVersionForTest(18);
    addTearDown(source.close);
    final createdAt = DateTime.utc(2026, 1, 2);
    source.insertAccount(Account(
      id: 'account-19',
      name: 'Principal',
      openingBalanceInCents: 100000,
      createdAt: createdAt,
    ));
    source.insertTransaction(TransactionRecord(
      id: 'transaction-19',
      accountId: 'account-19',
      type: TransactionType.expense,
      amountInCents: 1250,
      description: 'Compra teste',
      occurredOn: createdAt,
      createdAt: createdAt,
    ));
    source.insertCreditCard(CreditCard(
      id: 'card-19',
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 500000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff245943,
      createdAt: createdAt,
    ));
    source.insertCardPurchase(CardPurchase(
      id: 'purchase-19',
      cardId: 'card-19',
      description: 'Compra no cartão',
      amountInCents: 9000,
      purchasedOn: createdAt,
      installments: 1,
      createdAt: createdAt,
    ));
    source.insertInvestment(InvestmentPosition(
      id: 'investment-19',
      name: 'Reserva',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 10000,
      currentValueInCents: 10500,
      createdAt: createdAt,
    ));
    source.insertBudget(Budget(
      id: 'budget-19',
      category: 'Alimentação',
      limitInCents: 20000,
      year: createdAt.year,
      month: createdAt.month,
      createdAt: createdAt,
    ));
    source.insertSubscription(Subscription(
      id: 'subscription-19',
      name: 'Internet',
      amountInCents: 5000,
      billingDay: 10,
      category: 'Outros',
      createdAt: createdAt,
    ));
    source.insertFinancialGoal(FinancialGoal(
      id: 'goal-19',
      name: 'Reserva',
      targetInCents: 50000,
      savedInCents: 10000,
      createdAt: createdAt,
    ));
    source.insertShoppingItem(ShoppingItem(
      id: 'shopping-19',
      name: 'Café',
      quantity: 1,
      createdAt: createdAt,
    ));
    source.insertTask(TaskItem(
      id: 'task-19',
      title: 'Revisar orçamento',
      createdAt: createdAt,
    ));

    final countsBefore = source.tableCounts;
    final balanceBefore = FinancialRules.currentBalance(
        source.loadAccounts(), source.loadTransactions());
    await source.createConsistentCopy(file);

    final migrated = AppDatabase.openFile(file);
    addTearDown(migrated.close);
    expect(migrated.schemaVersion, 20);
    expect(migrated.tableCounts, countsBefore);
    expect(
      FinancialRules.currentBalance(
          migrated.loadAccounts(), migrated.loadTransactions()),
      balanceBefore,
    );
    final rowsByTable =
        migrated.exportSnapshot()['tables'] as Map<String, Object?>;
    for (final table in const [
      'transactions',
      'accounts',
      'credit_cards',
      'card_purchases',
      'investments',
      'budgets',
      'subscriptions',
      'financial_goals',
      'shopping_items',
      'tasks',
    ]) {
      final row = (rowsByTable[table] as List).single as Map;
      expect(row['updated_at'], createdAt.toIso8601String(), reason: table);
      expect(row['deleted_at'], isNull, reason: table);
    }
    migrated.validateIntegrity();
    expect(File('${file.path}.pre-v20.bak').existsSync(), isTrue);
  });

  test('schema 19 inicializa e atualiza updated_at por triggers conhecidos',
      () async {
    final folder = await Directory.systemTemp.createTemp('organiza-audit-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File(path.join(folder.path, 'organiza.db'));
    final database = AppDatabase.openInMemoryAtVersionForTest(19);
    addTearDown(database.close);
    final createdAt = DateTime.utc(2000, 1, 1);
    database.insertAccount(Account(
      id: 'account-audit',
      name: 'Principal',
      openingBalanceInCents: 1000,
      createdAt: createdAt,
    ));

    Map<String, Object?> accountRow() => ((database.exportSnapshot()['tables']
            as Map<String, Object?>)['accounts'] as List)
        .single as Map<String, Object?>;

    expect(accountRow()['updated_at'], createdAt.toIso8601String());
    database.updateAccountDetails(
      id: 'account-audit',
      name: 'Principal atualizado',
      institution: AccountInstitution.generic,
    );
    expect(
        DateTime.parse(accountRow()['updated_at'] as String).isAfter(createdAt),
        isTrue);
    database.validateIntegrity();
    final countsBefore = database.tableCounts;
    await database.createConsistentCopy(file);

    final reopened = AppDatabase.openFile(file);
    addTearDown(reopened.close);
    expect(reopened.schemaVersion, 20);
    expect(reopened.tableCounts, countsBefore);

    final raw = sqlite3.open(file.path);
    expect(
      raw
          .select("SELECT name FROM sqlite_master WHERE type = 'trigger'")
          .length,
      20,
    );
    raw.execute('''
      CREATE TRIGGER unexpected_user_trigger AFTER UPDATE ON accounts
      BEGIN SELECT 1; END
    ''');
    raw.close();
    expect(reopened.validateIntegrity, throwsFormatException);
  });

  test('migração schema 19 para 20 preenche campos de conta sem alterar saldo',
      () async {
    final folder =
        await Directory.systemTemp.createTemp('organiza-account-v20-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File(path.join(folder.path, 'organiza.db'));
    final source = AppDatabase.openInMemoryAtVersionForTest(19);
    addTearDown(source.close);
    final createdAt = DateTime.utc(2026, 2, 4);
    source.insertAccount(Account(
      id: 'account-v19',
      name: 'Carteira histórica',
      openingBalanceInCents: 123450,
      createdAt: createdAt,
      institution: AccountInstitution.nubank,
    ));
    source.insertTransaction(TransactionRecord(
      id: 'transaction-v19',
      accountId: 'account-v19',
      type: TransactionType.expense,
      amountInCents: 3450,
      description: 'Compra preservada',
      occurredOn: createdAt,
      createdAt: createdAt,
    ));
    final countsBefore = source.tableCounts;
    final balanceBefore = FinancialRules.currentBalance(
        source.loadAccounts(), source.loadTransactions());
    await source.createConsistentCopy(file);

    final migrated = AppDatabase.openFile(file);
    addTearDown(migrated.close);

    expect(migrated.schemaVersion, 20);
    expect(migrated.tableCounts, countsBefore);
    expect(
      FinancialRules.currentBalance(
          migrated.loadAccounts(), migrated.loadTransactions()),
      balanceBefore,
    );
    final accountRow = ((migrated.exportSnapshot()['tables']
            as Map<String, Object?>)['accounts'] as List)
        .single as Map<String, Object?>;
    expect(accountRow['type'], 'checking');
    expect(accountRow['archived_at'], isNull);
    expect(accountRow['include_in_net_worth'], 1);
    expect(accountRow['currency'], 'BRL');
    expect(accountRow['name'], 'Carteira histórica');
    expect(accountRow['institution'], 'nubank');
    migrated.validateIntegrity();
    expect(File('${file.path}.pre-v20.bak').existsSync(), isTrue);
  });
}

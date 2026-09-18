import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('salário recorrente materializa só a competência vencida e não duplica',
      () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final account = store.accounts.single.id;
    final now = DateTime.now();
    store.addTransaction(
        accountId: account,
        type: TransactionType.income,
        amountInCents: 300000,
        description: '',
        category: 'Salário',
        occurredOn: DateTime(now.year, now.month, 1),
        scheduleType: TransactionScheduleType.recurring);
    expect(store.transactions.length, 1);
    expect(store.transactions.single.description, 'Salário');
    expect(store.transactions.single.isSettled, isFalse);
    store.reload();
    expect(store.transactions.length, 1);
    store.addTransaction(
        accountId: account,
        type: TransactionType.income,
        amountInCents: 50000,
        description: '',
        category: 'Freelance');
    expect(store.salaryThisMonth, 300000);
    expect(store.incomes, 50000);
  });

  test('salário futuro aparece no planejamento antes da movimentação', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final now = DateTime.now();
    final future = DateTime(now.year, now.month + 1, 5);
    store.addTransaction(
        accountId: store.accounts.single.id,
        type: TransactionType.income,
        amountInCents: 250000,
        description: '',
        category: 'Salário',
        occurredOn: future,
        scheduleType: TransactionScheduleType.recurring);
    expect(store.transactions, isEmpty);
    expect(store.salaryThisMonth, 0);
    expect(store.salarySchedules.single.paymentDay, 5);
  });

  test('ajuste de saldo preserva movimentações e preferências móveis', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 10000);
    final account = store.accounts.single.id;
    store.addTransaction(
        accountId: account,
        type: TransactionType.expense,
        amountInCents: 2000,
        description: 'Compra');
    store.setAccountCurrentBalance(account, 15000);
    expect(store.balance, 15000);
    expect(store.transactions.length, 1);
    store.updateMobileQuickPages([0, 1, 4, 7]);
    expect(store.mobileQuickPages, [0, 1, 6, 7]);
  });

  test('assinatura pode ser editada, pausada e reativada', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addSubscription(
        name: 'Teste', amountInCents: 1000, billingDay: 5, category: 'Lazer');
    final id = store.subscriptions.single.id;
    store.updateSubscription(
        id: id,
        name: 'Serviço',
        amountInCents: 1500,
        billingDay: 12,
        category: 'Educação');
    store.setSubscriptionActive(id, false);
    expect(store.subscriptions.single.amountInCents, 1500);
    expect(store.subscriptions.single.isActive, isFalse);
    store.setSubscriptionActive(id, true);
    expect(store.subscriptions.single.isActive, isTrue);
  });

  test('categoria personalizada de meta é persistida', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addGoalCategory('Tecnologia');
    store.addFinancialGoal(
        name: 'Notebook',
        targetInCents: 100000,
        initialSavedInCents: 0,
        category: 'Tecnologia');
    expect(store.financialGoals.single.category, 'Tecnologia');
    expect(store.goalCategories, contains('Tecnologia'));
  });
  test('protege conta com lançamentos e permite excluir após limpar o fluxo',
      () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final accountId = store.accounts.single.id;
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Teste',
    );

    expect(() => store.deleteAccount(accountId), throwsArgumentError);
    store.deleteTransaction(store.transactions.single.id);
    store.deleteAccount(accountId);
    expect(store.accounts, isEmpty);
  });

  test('salva distribuição salarial que totaliza cem por cento', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.updateSalaryAllocation(
      essentialsPercent: 55,
      goalsPercent: 25,
      freePercent: 20,
    );
    expect(store.salaryAllocation.essentialsPercent, 55);
    expect(store.salaryAllocation.goalsPercent, 25);
    expect(store.salaryAllocation.freePercent, 20);
  });

  test('preserva data e subcategoria de um lançamento', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final occurredOn = DateTime(2026, 2, 14);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 8750,
      description: 'Jantar',
      category: 'Alimentação',
      subcategory: 'Restaurantes',
      occurredOn: occurredOn,
    );

    expect(store.transactions.single.subcategory, 'Restaurantes');
    expect(store.transactions.single.occurredOn, occurredOn);
  });

  test('cria meta e limita o aporte ao valor objetivo', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addFinancialGoal(
      name: 'Reserva',
      targetInCents: 100000,
      initialSavedInCents: 30000,
    );

    final goal = store.financialGoals.single;
    store.contributeToFinancialGoal(goal.id, 90000);
    expect(store.financialGoals.single.savedInCents, 100000);
  });

  test('cria categoria e subcategoria personalizadas sem duplicar nomes', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);

    final category = store.addFinanceCategory(
      'Colecionismo',
      TransactionType.expense,
    );
    final subcategory = store.addFinanceSubcategory(
      category.name,
      'Miniaturas',
      TransactionType.expense,
    );

    expect(subcategory.categoryId, category.id);
    expect(
      () => store.addFinanceCategory('colecionismo', TransactionType.expense),
      throwsArgumentError,
    );
  });

  test('edita poupança preservando identidade e taxa mensal informada', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addInvestment(
      name: 'Minha poupança',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 200000,
      currentValueInCents: 201000,
      fixedIncomeType: FixedIncomeType.savings,
    );
    final original = store.investments.single;
    store.updateInvestment(
      id: original.id,
      name: original.name,
      type: original.type,
      investedAmountInCents: original.investedAmountInCents,
      currentValueInCents: 203000,
      fixedIncomeType: FixedIncomeType.savings,
      quotedRateBasisPoints: 50,
      quotedRatePeriod: InvestmentRatePeriod.monthly,
    );
    final updated = store.investments.single;
    expect(updated.id, original.id);
    expect(updated.createdAt, original.createdAt);
    expect(updated.currentValueInCents, 203000);
    expect(updated.quotedRateBasisPoints, 50);
    expect(updated.quotedRatePeriod, InvestmentRatePeriod.monthly);
    expect(
        () => store.updateInvestment(
              id: original.id,
              name: original.name,
              type: original.type,
              investedAmountInCents: 200000,
              currentValueInCents: 203000,
              quotedRateBasisPoints: 50,
            ),
        throwsArgumentError);
  });

  test('parcelamento divide o total e mantém o saldo futuro como pendente', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 100000);

    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 10000,
      description: 'Curso',
      scheduleType: TransactionScheduleType.installment,
      repeatCount: 3,
      occurredOn: DateTime(2026, 9, 10),
    );

    expect(store.transactions, hasLength(3));
    expect(
      store.transactions
          .map((item) => item.amountInCents)
          .reduce((a, b) => a + b),
      10000,
    );
    final september = store.transactions.singleWhere(
      (item) => item.occurredOn.month == 9,
    );
    expect(september.isSettled, isTrue);
    expect(
      store.transactions
          .where((item) => item.occurredOn.month != 9)
          .every((item) => !item.isSettled),
      isTrue,
    );
    expect(store.balance, 96666);
  });

  test('recorrência cria lançamentos mensais com a primeira ocorrência paga',
      () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);

    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.income,
      amountInCents: 500000,
      description: 'Salário',
      scheduleType: TransactionScheduleType.recurring,
      repeatCount: 4,
      occurredOn: DateTime(2026, 9, 5),
    );

    expect(store.transactions, hasLength(4));
    expect(
      store.transactions.map((item) => item.occurredOn.month).toSet(),
      equals({9, 10, 11, 12}),
    );
    expect(store.balance, 500000);
  });

  test('exclui tarefa sem afetar as demais', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addTask('Comprar material');
    store.addTask('Revisar orçamento');
    final removed = store.tasks.firstWhere(
      (item) => item.title == 'Comprar material',
    );

    store.deleteTask(removed.id);

    expect(store.tasks.map((item) => item.title), ['Revisar orçamento']);
    expect(() => store.deleteTask(removed.id), throwsArgumentError);
  });

  test('lista de compras persiste quantidade, prioridade, baixa e exclusão',
      () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 100000);
    store.addShoppingItem(
      name: 'Fones',
      quantity: 2,
      estimatedUnitPriceInCents: 12500,
      priority: ShoppingPriority.high,
    );
    final item = store.shoppingItems.single;
    expect(item.estimatedTotalInCents, 25000);
    expect(item.priority, ShoppingPriority.high);
    expect(store.balance, 100000);

    store.setShoppingItemPurchased(item.id, true);
    expect(store.shoppingItems.single.isPurchased, isTrue);
    expect(store.balance, 100000);

    store.deleteShoppingItem(item.id);
    expect(store.shoppingItems, isEmpty);
    expect(() => store.addShoppingItem(name: '', quantity: 1),
        throwsArgumentError);
  });
}

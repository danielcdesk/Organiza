import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
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

  test('registra e desfaz parcelas pagas do cartão sem lançar despesa', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 100000);
    final accountId = store.accounts.single.id;
    store.addCreditCard(
      name: 'Principal',
      brand: CardBrand.visa,
      lastFour: '4242',
      limitInCents: 500000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xFF245943,
    );
    store.addCardPurchase(
      cardId: store.creditCards.single.id,
      description: 'Notebook',
      amountInCents: 120000,
      installments: 3,
    );
    final purchase = store.cardPurchases.single;
    final openingBalance = store.balance;

    store.setCardPurchaseInstallmentsPaid(purchase.id, {1, 3});

    expect(store.cardPurchases.single.paidInstallments, {1, 3});
    expect(store.transactions, isEmpty);
    expect(store.balance, openingBalance);
    store.reload();
    expect(store.cardPurchases.single.paidInstallments, {1, 3});

    store.setCardPurchaseInstallmentsPaid(purchase.id, {3});
    expect(store.cardPurchases.single.paidInstallments, {3});
    expect(store.accounts.single.openingBalanceInCents, 100000);
    expect(store.balance, openingBalance);
    expect(() => store.setCardPurchaseInstallmentsPaid(purchase.id, {4}),
        throwsArgumentError);
    expect(() => store.setCardPurchaseInstallmentsPaid('missing', {1}),
        throwsArgumentError);
    expect(store.cardPurchases.single.paidInstallments, {3});
    expect(store.transactions, isEmpty);
    expect(store.accounts.single.id, accountId);
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
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 10, 12)));
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
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 10, 12)));
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

  test('renda do perfil tem prioridade no planejamento', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.income,
      amountInCents: 900000,
      description: 'Freelance',
      category: 'Freelance',
    );
    store.saveProfile(name: 'Pessoa', incomeInCents: 450000);

    expect(store.salaryThisMonth, 450000);
    expect(store.transactions, hasLength(1));
  });

  test('planejamento reconhece salário avulso e recorrente sem duplicar', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 10, 14, 12)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final accountId = store.accounts.single.id;
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.income,
      amountInCents: 300000,
      description: 'Salário extra',
      category: 'Salário',
      occurredOn: DateTime(2026, 10, 5),
    );
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.income,
      amountInCents: 200000,
      description: 'Salário mensal',
      category: 'Salário',
      occurredOn: DateTime(2026, 10, 1),
      scheduleType: TransactionScheduleType.recurring,
    );
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.income,
      amountInCents: 900000,
      description: 'Freelance',
      category: 'Freelance',
      occurredOn: DateTime(2026, 10, 8),
    );
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.income,
      amountInCents: 100000,
      description: 'Salário anterior',
      category: 'Salário',
      occurredOn: DateTime(2026, 9, 5),
    );
    expect(store.salarySchedules, hasLength(1));
    expect(store.salaryThisMonth, 500000);
    store.saveProfile(name: 'Pessoa', incomeInCents: 450000);
    expect(store.salaryThisMonth, 450000);
    store.saveProfile(name: 'Pessoa', incomeInCents: 0);
    expect(store.salaryThisMonth, 500000);
  });

  test('divisão salarial personalizada acompanha gasto e persiste', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 10, 14, 12)));
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa', incomeInCents: 500000);
    store.addAccount('Principal', 0);
    store.addSalaryAllocationBucket(
      name: 'Viagens',
      percent: 10,
      iconKey: 'sparkles',
      colorValue: 0xFF7454C8,
      linkedCategories: const ['Lazer'],
    );
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 12000,
      description: '',
      category: 'Lazer',
      occurredOn: DateTime(2026, 10, 2),
    );
    final bucket = store.salaryAllocationBuckets.last;

    expect(store.allocationLimitInCents(bucket), 50000);
    expect(store.allocationSpentInCents(bucket), 12000);
    expect(
        store.allocationSpentInCents(store.salaryAllocationBuckets
            .firstWhere((item) => item.id == 'free')),
        0);
    store.reload();
    expect(store.salaryAllocationBuckets.last.name, 'Viagens');
  });

  test('edita todos os campos de lançamento e item de desejo', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Origem', 100000);
    store.addAccount('Destino', 0);
    store.addTransaction(
      accountId: store.accounts.first.id,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Antes',
    );
    final transaction = store.transactions.single;
    store.updateTransaction(TransactionRecord(
      id: transaction.id,
      accountId: store.accounts.last.id,
      type: TransactionType.income,
      amountInCents: 2500,
      description: 'Depois',
      occurredOn: DateTime(2026, 10, 1),
      createdAt: transaction.createdAt,
      category: 'Freelance',
      subcategory: 'Projeto',
    ));
    expect(store.transactions.single.accountId, store.accounts.last.id);
    expect(store.transactions.single.type, TransactionType.income);
    expect(store.transactions.single.subcategory, 'Projeto');

    store.addShoppingItem(name: 'Notebook', quantity: 1);
    final item = store.shoppingItems.single;
    store.updateShoppingItem(
      id: item.id,
      name: 'Notebook leve',
      quantity: 2,
      estimatedUnitPriceInCents: 350000,
      priority: ShoppingPriority.high,
      isPurchased: false,
      description: 'Para estudos',
    );
    expect(store.shoppingItems.single.name, 'Notebook leve');
    expect(store.shoppingItems.single.estimatedTotalInCents, 700000);
  });

  test('edição de série altera somente ocorrências futuras quando escolhida',
      () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 10, 12)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 30000,
      description: 'Curso',
      scheduleType: TransactionScheduleType.installment,
      repeatCount: 3,
      occurredOn: DateTime(2026, 9, 10),
    );
    final october =
        store.transactions.singleWhere((item) => item.occurredOn.month == 10);
    store.updateTransaction(
      TransactionRecord(
        id: october.id,
        accountId: october.accountId,
        type: october.type,
        amountInCents: 12000,
        description: 'Curso reajustado',
        occurredOn: october.occurredOn,
        createdAt: october.createdAt,
        category: 'Educação',
        subcategory: 'Cursos',
        scheduleType: october.scheduleType,
        seriesId: october.seriesId,
        installmentNumber: october.installmentNumber,
        installmentCount: october.installmentCount,
        isSettled: october.isSettled,
      ),
      applyToFuture: true,
    );

    expect(
        store.transactions
            .singleWhere((item) => item.occurredOn.month == 9)
            .amountInCents,
        10000);
    expect(
        store.transactions.where((item) => item.occurredOn.month >= 10).every(
            (item) =>
                item.amountInCents == 12000 && item.category == 'Educação'),
        isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:clock/clock.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/domain/app_route.dart';
import 'package:organiza/domain/financial_rules.dart';

void main() {
  test('classificação e fonte sobrevivem edição de lançamento', () {
    final store = OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 10)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final category = store.financeCategories.firstWhere(
        (item) => item.name == 'Alimentação' && item.type == TransactionType.expense);
    store.setFinanceCategoryEssentiality(category.id, ExpenseEssentiality.essential);
    expect(store.financeCategories.firstWhere((item) => item.id == category.id).essentiality,
        ExpenseEssentiality.essential);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Mercado',
      category: 'Alimentação',
      incomeSource: 'Benefício',
      essentialityOverride: ExpenseEssentiality.nonEssential,
    );
    final id = store.transactions.single.id;
    store.updateTransactionDetails(id, 1100, 'Mercado maior');
    expect(store.transactions.single.incomeSource, 'Benefício');
    expect(store.transactions.single.essentialityOverride,
        ExpenseEssentiality.nonEssential);
  });
  test(
      'compra cria fatura, pagamento sai da conta uma vez e estorno é reversível',
      () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 2, 20)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 100000);
    store.addCreditCard(
        name: 'Visa',
        brand: CardBrand.visa,
        lastFour: '4242',
        limitInCents: 500000,
        closingDay: 10,
        dueDay: 17,
        colorValue: 0xFF245943);
    final card = store.creditCards.single;
    store.addCardPurchase(
        cardId: card.id,
        description: 'Mercado',
        amountInCents: 12000,
        installments: 1,
        purchasedOn: DateTime(2026, 1, 5),
        category: 'Alimentação',
        subcategory: 'Mercado');
    final invoice = store.cardInvoices.single;
    expect(invoice.status, CardInvoiceStatus.closed);
    expect(store.reportTransactions.single.category, 'Alimentação');
    final before = store.balance;
    store.payCardInvoice(invoice.id, store.accounts.single.id);
    expect(store.balance, before - 12000);
    expect(store.reportTransactions, hasLength(1));
    expect(store.cardInvoices.single.status, CardInvoiceStatus.paid);
    store.reverseCardInvoicePayment(invoice.id);
    expect(store.balance, before);
    expect(store.cardInvoices.single.status, CardInvoiceStatus.closed);
  });

  test('não aceita excluir cartão com compra/fatura e aceita dias até 31', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 2, 20)));
    addTearDown(store.dispose);
    store.addCreditCard(
        name: 'Visa',
        brand: CardBrand.visa,
        lastFour: '4242',
        limitInCents: 500000,
        closingDay: 31,
        dueDay: 31,
        colorValue: 0xFF245943);
    final card = store.creditCards.single;
    store.addCardPurchase(
        cardId: card.id,
        description: 'Compra',
        amountInCents: 12000,
        installments: 1,
        purchasedOn: DateTime(2026, 1, 30));
    expect(() => store.deleteCreditCard(card.id), throwsStateError);
  });
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
    store.updateMobileQuickPages([
      AppRoute.overview,
      AppRoute.finances,
      AppRoute.organization,
      AppRoute.goals,
    ]);
    expect(store.mobileQuickPages, [
      AppRoute.overview,
      AppRoute.finances,
      AppRoute.organization,
      AppRoute.goals,
    ]);
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
    expect(store.transactions.single.occurredOn, DateTime.utc(2026, 2, 14));
  });

  test('edita e desfaz exclusão das parcelas com centavos redistribuídos', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 1, 1)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 1200,
      description: 'Compra',
      scheduleType: TransactionScheduleType.installment,
      repeatCount: 12,
      occurredOn: DateTime(2026, 1, 31),
    );
    final seventh =
        store.transactions.firstWhere((item) => item.installmentNumber == 7);
    store.updateTransactionSeries(
      id: seventh.id,
      amountInCents: 1000,
      description: 'Atualizada',
      category: 'Casa',
      subcategory: 'Móveis',
      accountId: store.accounts.single.id,
      destinationAccountId: null,
      occurredOn: seventh.occurredOn,
      scope: TransactionSeriesScope.fromHere,
    );
    final remaining = store.transactions
        .where((item) => item.installmentNumber >= 7)
        .toList()
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
    expect(remaining.map((item) => item.amountInCents),
        [167, 167, 167, 167, 166, 166]);
    expect(remaining.map((item) => item.amountInCents).reduce((a, b) => a + b),
        1000);
    expect(
        remaining.every(
            (item) => item.category == 'Casa' && item.subcategory == 'Móveis'),
        isTrue);
    final removed = store.deleteTransaction(seventh.id,
        scope: TransactionSeriesScope.fromHere);
    expect(store.transactions, hasLength(6));
    store.restoreDeletedTransactions(removed);
    expect(store.transactions, hasLength(12));
  });

  test('salário excluído por padrão remove só uma ocorrência e pode desfazer',
      () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 3, 20)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.income,
      amountInCents: 100000,
      description: 'Salário',
      category: 'Salário',
      scheduleType: TransactionScheduleType.recurring,
      occurredOn: DateTime(2026, 1, 10),
    );
    final occurrence = store.transactions.single;
    final removed = store.deleteTransaction(occurrence.id);
    expect(store.salarySchedules, hasLength(1));
    expect(
        store.transactions
            .where((item) => item.seriesId == occurrence.seriesId),
        isEmpty);
    store.reload();
    expect(
        store.transactions
            .where((item) => item.seriesId == occurrence.seriesId),
        isEmpty);
    store.restoreDeletedTransactions(removed);
    expect(
        store.transactions
            .where((item) => item.seriesId == occurrence.seriesId),
        hasLength(1));
  });

  test('saldo negativo é permitido e respeita limite absoluto', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 1, 1)));
    addTearDown(store.dispose);
    store.addAccount('Cheque especial', -5000);
    expect(store.balance, -5000);
    store.setAccountCurrentBalance(store.accounts.single.id, -25000);
    expect(store.balance, -25000);
    expect(
        () => store.setAccountCurrentBalance(
            store.accounts.single.id, -100000000000),
        throwsArgumentError);
  });

  testWidgets('retomar app após meia-noite materializa salário usando Clock',
      (tester) async {
    var now = DateTime(2026, 1, 30, 23, 50);
    final store = OrganizaStore.inMemory(clock: Clock(() => now));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.income,
      amountInCents: 100000,
      description: 'Salário',
      category: 'Salário',
      scheduleType: TransactionScheduleType.recurring,
      occurredOn: DateTime(2026, 1, 31),
    );
    expect(store.transactions, isEmpty);
    now = DateTime(2026, 1, 31, 0, 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(store.transactions, hasLength(1));
    expect(store.transactions.single.occurredOn, DateTime.utc(2026, 1, 31));
  });

  test('editar transferência continua neutra no saldo consolidado', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 1, 3)));
    addTearDown(store.dispose);
    store.addAccount('Origem', 10000);
    store.addAccount('Destino', 0);
    store.addTransaction(
      accountId: store.accounts[0].id,
      destinationAccountId: store.accounts[1].id,
      type: TransactionType.transfer,
      amountInCents: 3000,
      description: 'Transferência',
      occurredOn: DateTime(2026, 1, 1),
    );
    store.updateTransactionSeries(
      id: store.transactions.single.id,
      amountInCents: 4500,
      description: 'Ajuste',
      category: 'Outros',
      subcategory: 'Geral',
      accountId: store.accounts[0].id,
      destinationAccountId: store.accounts[1].id,
      occurredOn: DateTime(2026, 1, 2),
    );
    expect(store.balance, 10000);
    expect(store.transactions.single.isSettled, isTrue);
    expect(store.transactions.single.amountInCents, 4500);
    expect(
        store.accounts.map((account) =>
            FinancialRules.accountBalance(account, store.transactions)),
        [5500, 4500]);
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
      occurredOn: DateTime(DateTime.now().year, DateTime.now().month, 10),
    );

    expect(store.transactions, hasLength(3));
    expect(
      store.transactions
          .map((item) => item.amountInCents)
          .reduce((a, b) => a + b),
      10000,
    );
    final september = store.transactions.singleWhere(
      (item) => item.installmentNumber == 1,
    );
    expect(september.isSettled, isTrue);
    expect(
      store.transactions
          .where((item) => item.installmentNumber != 1)
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

    final firstMonth = DateTime(DateTime.now().year, DateTime.now().month, 5);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.income,
      amountInCents: 500000,
      description: 'Salário',
      scheduleType: TransactionScheduleType.recurring,
      repeatCount: 4,
      occurredOn: firstMonth,
    );

    expect(store.transactions, hasLength(4));
    expect(
      store.transactions.map((item) => item.occurredOn.month).toSet(),
      equals({
        firstMonth.month,
        DateTime(firstMonth.year, firstMonth.month + 1).month,
        DateTime(firstMonth.year, firstMonth.month + 2).month,
        DateTime(firstMonth.year, firstMonth.month + 3).month
      }),
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

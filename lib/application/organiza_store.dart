import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';

class OrganizaStore extends ChangeNotifier {
  OrganizaStore._(this._repository);

  final LocalRepository _repository;
  final _uuid = const Uuid();
  List<Account> accounts = [];
  List<TransactionRecord> transactions = [];
  List<TaskItem> tasks = [];
  List<CreditCard> creditCards = [];
  List<CardPurchase> cardPurchases = [];
  List<InvestmentPosition> investments = [];
  List<Budget> budgets = [];
  List<Subscription> subscriptions = [];
  List<FinancialGoal> financialGoals = [];
  List<FinanceCategory> financeCategories = [];
  List<FinanceSubcategory> financeSubcategories = [];
  SalaryAllocation salaryAllocation = SalaryAllocation.defaults;

  static Future<OrganizaStore> create() async {
    final store = OrganizaStore._(await LocalRepository.open());
    store.reload();
    return store;
  }

  static OrganizaStore inMemory() {
    final store = OrganizaStore._(LocalRepository.inMemory());
    store.reload();
    return store;
  }

  void reload() {
    accounts = _repository.loadAccounts();
    transactions = _repository.loadTransactions();
    tasks = _repository.loadTasks();
    creditCards = _repository.loadCreditCards();
    cardPurchases = _repository.loadCardPurchases();
    investments = _repository.loadInvestments();
    budgets = _repository.loadBudgets();
    subscriptions = _repository.loadSubscriptions();
    salaryAllocation = _repository.loadSalaryAllocation();
    financialGoals = _repository.loadFinancialGoals();
    financeCategories = _repository.loadFinanceCategories();
    financeSubcategories = _repository.loadFinanceSubcategories();
    notifyListeners();
  }

  int get balance => FinancialRules.currentBalance(accounts, transactions);
  int get incomes => FinancialRules.monthTotal(
      transactions, DateTime.now(), TransactionType.income);
  int get expenses => FinancialRules.monthTotal(
      transactions, DateTime.now(), TransactionType.expense);
  int get availableToSpend => balance;

  void addAccount(
    String name,
    int openingBalanceInCents, {
    AccountInstitution institution = AccountInstitution.generic,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome da conta.');
    _repository.insertAccount(Account(
      id: _id(),
      name: cleanName,
      openingBalanceInCents: openingBalanceInCents,
      createdAt: DateTime.now(),
      institution: institution,
    ));
    reload();
  }

  void addTransaction({
    required String accountId,
    required TransactionType type,
    required int amountInCents,
    required String description,
    String? destinationAccountId,
    String category = 'Outros',
    String subcategory = 'Geral',
    DateTime? occurredOn,
    TransactionScheduleType scheduleType = TransactionScheduleType.single,
    int repeatCount = 1,
  }) {
    if (!FinancialRules.isValidAmount(amountInCents)) {
      throw ArgumentError('Informe um valor válido.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Informe uma descrição.');
    }
    if (type == TransactionType.transfer &&
        (destinationAccountId == null || destinationAccountId == accountId)) {
      throw ArgumentError('Escolha uma conta de destino diferente.');
    }
    if (type == TransactionType.transfer &&
        scheduleType != TransactionScheduleType.single) {
      throw ArgumentError('Transferências agendadas ainda não são permitidas.');
    }
    if (scheduleType != TransactionScheduleType.single &&
        (repeatCount < 2 || repeatCount > 60)) {
      throw ArgumentError('Use entre 2 e 60 repetições.');
    }
    final count =
        scheduleType == TransactionScheduleType.single ? 1 : repeatCount;
    final baseDate = occurredOn ?? DateTime.now();
    final seriesId = count == 1 ? null : _id();
    for (var index = 0; index < count; index++) {
      final value = scheduleType == TransactionScheduleType.installment
          ? _installmentValue(amountInCents, count, index)
          : amountInCents;
      final date = _addMonths(baseDate, index);
      _repository.insertTransaction(TransactionRecord(
        id: _id(),
        accountId: accountId,
        destinationAccountId: destinationAccountId,
        type: type,
        amountInCents: value,
        description: description.trim(),
        category: category.trim().isEmpty ? 'Outros' : category.trim(),
        subcategory: subcategory.trim().isEmpty ? 'Geral' : subcategory.trim(),
        occurredOn: date,
        createdAt: DateTime.now(),
        scheduleType: scheduleType,
        seriesId: seriesId,
        installmentNumber: index + 1,
        installmentCount: count,
        isSettled: !_dateOnly(date).isAfter(_dateOnly(DateTime.now())),
      ));
    }
    reload();
  }

  void addTask(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Informe o título da tarefa.');
    }
    _repository.insertTask(
        TaskItem(id: _id(), title: title.trim(), createdAt: DateTime.now()));
    reload();
  }

  void toggleTask(TaskItem task, bool value) {
    _repository.setTaskDone(task.id, value);
    reload();
  }

  void addCreditCard({
    required String name,
    required CardBrand brand,
    required String lastFour,
    required int limitInCents,
    required int closingDay,
    required int dueDay,
    required int colorValue,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do cartão.');
    if (!RegExp(r'^\d{4}$').hasMatch(lastFour)) {
      throw ArgumentError('Informe os quatro últimos dígitos.');
    }
    if (!FinancialRules.isValidAmount(limitInCents)) {
      throw ArgumentError('Informe um limite válido.');
    }
    if (closingDay < 1 || closingDay > 28 || dueDay < 1 || dueDay > 28) {
      throw ArgumentError(
          'Fechamento e vencimento devem estar entre os dias 1 e 28.');
    }
    _repository.insertCreditCard(CreditCard(
      id: _id(),
      name: cleanName,
      brand: brand,
      lastFour: lastFour,
      limitInCents: limitInCents,
      closingDay: closingDay,
      dueDay: dueDay,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    ));
    reload();
  }

  void addCardPurchase({
    required String cardId,
    required String description,
    required int amountInCents,
    required int installments,
  }) {
    if (creditCards.every((card) => card.id != cardId)) {
      throw ArgumentError('Cartão não encontrado.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Informe a descrição da compra.');
    }
    if (!FinancialRules.isValidAmount(amountInCents)) {
      throw ArgumentError('Informe um valor válido.');
    }
    if (installments < 1 || installments > 48) {
      throw ArgumentError('O número de parcelas deve estar entre 1 e 48.');
    }
    _repository.insertCardPurchase(CardPurchase(
      id: _id(),
      cardId: cardId,
      description: description.trim(),
      amountInCents: amountInCents,
      purchasedOn: DateTime.now(),
      installments: installments,
      createdAt: DateTime.now(),
    ));
    reload();
  }

  void addInvestment({
    required String name,
    required InvestmentType type,
    required int investedAmountInCents,
    required int currentValueInCents,
    FixedIncomeType? fixedIncomeType,
    String? institutionName,
    DateTime? maturityDate,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do ativo.');
    if (!FinancialRules.isValidAmount(investedAmountInCents)) {
      throw ArgumentError('Informe um valor investido válido.');
    }
    if (currentValueInCents < 0 || currentValueInCents >= 100000000000) {
      throw ArgumentError('Informe um saldo atual válido.');
    }
    _repository.insertInvestment(InvestmentPosition(
      id: _id(),
      name: cleanName,
      type: type,
      investedAmountInCents: investedAmountInCents,
      currentValueInCents: currentValueInCents,
      fixedIncomeType:
          type == InvestmentType.fixedIncome ? fixedIncomeType : null,
      institutionName: institutionName?.trim().isEmpty == true
          ? null
          : institutionName?.trim(),
      maturityDate: type == InvestmentType.fixedIncome ? maturityDate : null,
      createdAt: DateTime.now(),
    ));
    reload();
  }

  void addBudget({
    required String category,
    required int limitInCents,
    DateTime? period,
  }) {
    final cleanCategory = category.trim();
    if (cleanCategory.isEmpty) throw ArgumentError('Informe uma categoria.');
    if (!FinancialRules.isValidAmount(limitInCents)) {
      throw ArgumentError('Informe um limite válido.');
    }
    final date = period ?? DateTime.now();
    if (budgets.any((item) =>
        item.category.toLowerCase() == cleanCategory.toLowerCase() &&
        item.year == date.year &&
        item.month == date.month)) {
      throw ArgumentError(
          'Já existe um orçamento para essa categoria neste mês.');
    }
    _repository.insertBudget(Budget(
      id: _id(),
      category: cleanCategory,
      limitInCents: limitInCents,
      year: date.year,
      month: date.month,
      createdAt: DateTime.now(),
    ));
    reload();
  }

  void deleteAccount(String accountId) {
    if (accounts.every((account) => account.id != accountId)) {
      throw ArgumentError('Conta não encontrada.');
    }
    if (transactions.any((item) =>
        item.accountId == accountId ||
        item.destinationAccountId == accountId)) {
      throw ArgumentError(
          'Remova ou mova as transações desta conta antes de excluí-la.');
    }
    _repository.deleteAccount(accountId);
    reload();
  }

  void addSubscription({
    required String name,
    required int amountInCents,
    required int billingDay,
    required String category,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome da assinatura.');
    if (!FinancialRules.isValidAmount(amountInCents)) {
      throw ArgumentError('Informe um valor válido.');
    }
    if (billingDay < 1 || billingDay > 31) {
      throw ArgumentError('O dia de cobrança deve estar entre 1 e 31.');
    }
    _repository.insertSubscription(Subscription(
      id: _id(),
      name: cleanName,
      amountInCents: amountInCents,
      billingDay: billingDay,
      category: category.trim().isEmpty ? 'Outros' : category.trim(),
      createdAt: DateTime.now(),
    ));
    reload();
  }

  void deleteTransaction(String id) {
    _repository.deleteTransaction(id);
    reload();
  }

  void deleteBudget(String id) {
    _repository.deleteBudget(id);
    reload();
  }

  void deleteSubscription(String id) {
    _repository.deleteSubscription(id);
    reload();
  }

  void addFinancialGoal({
    required String name,
    required int targetInCents,
    required int initialSavedInCents,
    DateTime? deadline,
    String iconKey = 'savings',
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome da meta.');
    if (!FinancialRules.isValidAmount(targetInCents)) {
      throw ArgumentError('Informe um objetivo válido.');
    }
    if (initialSavedInCents < 0 || initialSavedInCents > targetInCents) {
      throw ArgumentError('O valor inicial deve ficar entre zero e a meta.');
    }
    _repository.insertFinancialGoal(FinancialGoal(
      id: _id(),
      name: cleanName,
      targetInCents: targetInCents,
      savedInCents: initialSavedInCents,
      deadline: deadline,
      iconKey: iconKey,
      createdAt: DateTime.now(),
    ));
    reload();
  }

  void contributeToFinancialGoal(String id, int amountInCents) {
    if (!FinancialRules.isValidAmount(amountInCents)) {
      throw ArgumentError('Informe um aporte válido.');
    }
    final goal = financialGoals.where((item) => item.id == id).firstOrNull;
    if (goal == null) throw ArgumentError('Meta não encontrada.');
    final next =
        (goal.savedInCents + amountInCents).clamp(0, goal.targetInCents);
    _repository.updateFinancialGoalSaved(id, next);
    reload();
  }

  void deleteFinancialGoal(String id) {
    _repository.deleteFinancialGoal(id);
    reload();
  }

  void deleteInvestment(String id) {
    _repository.deleteInvestment(id);
    reload();
  }

  FinanceCategory addFinanceCategory(String name, TransactionType type) {
    if (type == TransactionType.transfer) {
      throw ArgumentError('Categorias são usadas em receitas e despesas.');
    }
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Informe o nome da categoria.');
    if (financeCategories.any((item) =>
        item.type == type && item.name.toLowerCase() == clean.toLowerCase())) {
      throw ArgumentError('Essa categoria já existe.');
    }
    _repository.insertFinanceCategory(FinanceCategory(
      id: _id(),
      name: clean,
      type: type,
      createdAt: DateTime.now(),
    ));
    reload();
    return financeCategories.firstWhere((item) =>
        item.type == type && item.name.toLowerCase() == clean.toLowerCase());
  }

  FinanceSubcategory addFinanceSubcategory(
      String categoryName, String name, TransactionType type) {
    FinanceCategory? category;
    for (final item in financeCategories) {
      if (item.type == type &&
          item.name.toLowerCase() == categoryName.toLowerCase()) {
        category = item;
        break;
      }
    }
    if (category == null) throw ArgumentError('Categoria não encontrada.');
    final selectedCategory = category;
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Informe o nome da subcategoria.');
    if (financeSubcategories.any((item) =>
        item.categoryId == selectedCategory.id &&
        item.name.toLowerCase() == clean.toLowerCase())) {
      throw ArgumentError('Essa subcategoria já existe.');
    }
    _repository.insertFinanceSubcategory(FinanceSubcategory(
      id: _id(),
      categoryId: selectedCategory.id,
      name: clean,
      createdAt: DateTime.now(),
    ));
    reload();
    return financeSubcategories.firstWhere((item) =>
        item.categoryId == selectedCategory.id &&
        item.name.toLowerCase() == clean.toLowerCase());
  }

  void setTransactionSettled(String id, bool value) {
    _repository.setTransactionSettled(id, value);
    reload();
  }

  void updateSalaryAllocation({
    required int essentialsPercent,
    required int goalsPercent,
    required int freePercent,
  }) {
    if (essentialsPercent < 0 ||
        goalsPercent < 0 ||
        freePercent < 0 ||
        essentialsPercent + goalsPercent + freePercent != 100) {
      throw ArgumentError('A distribuição do salário precisa totalizar 100%.');
    }
    _repository.saveSalaryAllocation(SalaryAllocation(
      essentialsPercent: essentialsPercent,
      goalsPercent: goalsPercent,
      freePercent: freePercent,
    ));
    reload();
  }

  String _id() => _uuid.v4();

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _addMonths(DateTime value, int months) {
    final normalized = DateTime(value.year, value.month + months);
    final lastDay = DateTime(normalized.year, normalized.month + 1, 0).day;
    return DateTime(
        normalized.year, normalized.month, value.day.clamp(1, lastDay));
  }

  static int _installmentValue(int total, int count, int zeroBasedIndex) {
    final base = total ~/ count;
    final remainder = total % count;
    return base + (zeroBasedIndex < remainder ? 1 : 0);
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }
}

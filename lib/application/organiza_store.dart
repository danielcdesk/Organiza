import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import '../services/backup_service.dart';

class OrganizaStore extends ChangeNotifier {
  OrganizaStore._(this._repository, Clock? clock)
      : _clock = clock ?? const Clock();

  final LocalRepository _repository;
  final Clock _clock;
  final _uuid = const Uuid();
  Timer? _salaryRefreshTimer;

  DateTime get _now => _clock.now();
  Clock get clock => _clock;

  void _scheduleNextDayRefresh() {
    _salaryRefreshTimer?.cancel();
    final now = _now;
    final next = DateTime(now.year, now.month, now.day + 1, 0, 1);
    _salaryRefreshTimer = Timer(next.difference(now), () {
      reload();
      _scheduleNextDayRefresh();
    });
  }

  List<Account> accounts = [];
  List<TransactionRecord> transactions = [];
  List<TaskItem> tasks = [];
  List<ShoppingItem> shoppingItems = [];
  List<CreditCard> creditCards = [];
  List<CardPurchase> cardPurchases = [];
  List<InvestmentPosition> investments = [];
  List<Budget> budgets = [];
  List<Subscription> subscriptions = [];
  List<FinancialGoal> financialGoals = [];
  List<FinanceCategory> financeCategories = [];
  List<FinanceSubcategory> financeSubcategories = [];
  List<SalarySchedule> salarySchedules = [];
  List<String> goalCategories = [];
  List<int> mobileQuickPages = [0, 1, 6, 8];
  SalaryAllocation salaryAllocation = SalaryAllocation.defaults;
  String get themePreference => _repository.loadPreference('theme') ?? 'dark';
  bool get hideValuesPreference =>
      _repository.loadPreference('hide_values') == 'true';
  String get shoppingViewPreference =>
      _repository.loadPreference('shopping_view') == 'cards' ? 'cards' : 'list';
  String get profileName => _repository.loadPreference('profile_name') ?? '';
  int get profileIncomeInCents =>
      int.tryParse(_repository.loadPreference('profile_income_cents') ?? '') ??
      0;
  String? get profilePhotoPath {
    final value = _repository.loadPreference('profile_photo_path');
    return value == null || value.isEmpty ? null : value;
  }

  void saveThemePreference(String value) {
    if (!const ['light', 'dark', 'system'].contains(value)) {
      throw ArgumentError('Tema inválido.');
    }
    _repository.savePreference('theme', value);
  }

  void saveHideValuesPreference(bool value) =>
      _repository.savePreference('hide_values', value.toString());

  void saveShoppingViewPreference(String value) {
    if (!const ['list', 'cards'].contains(value)) {
      throw ArgumentError('Modo de lista inválido.');
    }
    _repository.savePreference('shopping_view', value);
    notifyListeners();
  }

  void saveProfile({
    required String name,
    required int incomeInCents,
    String? photoPath,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe seu nome.');
    if (incomeInCents < 0) throw ArgumentError('Informe uma renda válida.');
    _repository.savePreference('profile_name', cleanName);
    _repository.savePreference('profile_income_cents', '$incomeInCents');
    _repository.savePreference('profile_photo_path', photoPath ?? '');
    notifyListeners();
  }

  static Future<OrganizaStore> create({Clock? clock}) async {
    final store = OrganizaStore._(await LocalRepository.open(), clock);
    store.reload();
    store._scheduleNextDayRefresh();
    return store;
  }

  static OrganizaStore inMemory({Clock? clock}) {
    final store = OrganizaStore._(LocalRepository.inMemory(), clock);
    store.reload();
    return store;
  }

  Future<File> exportEncryptedBackup(String password) => const BackupService()
      .exportEncrypted(_repository.exportSnapshot(), password);

  Future<File> restoreEncryptedBackup(File file, String password) async {
    final snapshot =
        await const BackupService().decryptEncrypted(file, password);
    final safetyCopy = await exportEncryptedBackup(password);
    _repository.restoreSnapshot(snapshot);
    reload();
    return safetyCopy;
  }

  void reload() {
    accounts = _repository.loadAccounts();
    transactions = _repository.loadTransactions();
    salarySchedules = _repository.loadSalarySchedules();
    _materializeDueSalaries();
    tasks = _repository.loadTasks();
    shoppingItems = _repository.loadShoppingItems();
    creditCards = _repository.loadCreditCards();
    cardPurchases = _repository.loadCardPurchases();
    investments = _repository.loadInvestments();
    budgets = _repository.loadBudgets();
    subscriptions = _repository.loadSubscriptions();
    salaryAllocation = _repository.loadSalaryAllocation();
    financialGoals = _repository.loadFinancialGoals();
    financeCategories = _repository.loadFinanceCategories();
    financeSubcategories = _repository.loadFinanceSubcategories();
    goalCategories = _repository.loadGoalCategories();
    mobileQuickPages = _repository.loadMobileQuickPages();
    notifyListeners();
  }

  int get balance => FinancialRules.currentBalance(accounts, transactions);
  int get incomes =>
      FinancialRules.monthTotal(transactions, _now, TransactionType.income);
  int get expenses =>
      FinancialRules.monthTotal(transactions, _now, TransactionType.expense);
  int get availableToSpend => balance;
  int get salaryThisMonth {
    final now = _now;
    final recorded = transactions
        .where((item) =>
            item.type == TransactionType.income &&
            item.category.toLowerCase() == 'salário' &&
            item.occurredOn.year == now.year &&
            item.occurredOn.month == now.month)
        .fold(0, (sum, item) => sum + item.amountInCents);
    final expected = salarySchedules
        .where((schedule) =>
            !DateTime(schedule.firstDueOn.year, schedule.firstDueOn.month)
                .isAfter(DateTime(now.year, now.month)) &&
            !transactions.any((item) =>
                item.seriesId == schedule.id &&
                item.occurredOn.year == now.year &&
                item.occurredOn.month == now.month))
        .fold(0, (sum, schedule) => sum + schedule.amountInCents);
    return recorded + expected;
  }

  void _materializeDueSalaries() {
    final today = _dateOnly(_now);
    var inserted = false;
    _repository.transaction(() {
      for (final schedule in salarySchedules) {
        for (var month = 0; month < 1200; month++) {
          final calendarMonth = DateTime(
              schedule.firstDueOn.year, schedule.firstDueOn.month + month);
          final last =
              DateTime(calendarMonth.year, calendarMonth.month + 1, 0).day;
          final due = DateTime(calendarMonth.year, calendarMonth.month,
              schedule.paymentDay.clamp(1, last));
          if (_dateOnly(due).isAfter(today)) break;
          final exists = transactions.any((item) =>
              item.seriesId == schedule.id &&
              item.occurredOn.year == due.year &&
              item.occurredOn.month == due.month);
          if (exists) continue;
          _repository.insertTransaction(TransactionRecord(
            id: _id(),
            accountId: schedule.accountId,
            type: TransactionType.income,
            amountInCents: schedule.amountInCents,
            description: schedule.description,
            category: 'Salário',
            subcategory: schedule.subcategory,
            occurredOn: due,
            createdAt: _now,
            scheduleType: TransactionScheduleType.recurring,
            seriesId: schedule.id,
            isSettled: false,
          ));
          inserted = true;
        }
      }
    });
    if (inserted) transactions = _repository.loadTransactions();
  }

  void addAccount(
    String name,
    int openingBalanceInCents, {
    AccountInstitution institution = AccountInstitution.generic,
    String? customInstitutionName,
    String? customIconKey,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome da conta.');
    final cleanInstitutionName = customInstitutionName?.trim();
    if (institution == AccountInstitution.custom &&
        (cleanInstitutionName == null || cleanInstitutionName.isEmpty)) {
      throw ArgumentError('Informe o nome do banco.');
    }
    _repository.insertAccount(Account(
      id: _id(),
      name: cleanName,
      openingBalanceInCents: openingBalanceInCents,
      createdAt: _now,
      institution: institution,
      customInstitutionName:
          cleanInstitutionName?.isEmpty == true ? null : cleanInstitutionName,
      customIconKey: customIconKey,
    ));
    reload();
  }

  void updateAccount({
    required String id,
    required String name,
    required int currentBalanceInCents,
    required AccountInstitution institution,
    String? customInstitutionName,
    String? customIconKey,
  }) {
    final account = accounts.where((item) => item.id == id).firstOrNull;
    if (account == null) throw ArgumentError('Conta não encontrada.');
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome da conta.');
    if (currentBalanceInCents < 0 || currentBalanceInCents >= 100000000000) {
      throw ArgumentError('Informe um saldo válido.');
    }
    final cleanInstitutionName = customInstitutionName?.trim();
    if (institution == AccountInstitution.custom &&
        (cleanInstitutionName == null || cleanInstitutionName.isEmpty)) {
      throw ArgumentError('Informe o nome do banco.');
    }
    final actual = FinancialRules.accountBalance(account, transactions);
    _repository.transaction(() {
      _repository.updateAccountDetails(
        id: id,
        name: cleanName,
        institution: institution,
        customInstitutionName:
            cleanInstitutionName?.isEmpty == true ? null : cleanInstitutionName,
        customIconKey: customIconKey,
      );
      _repository.updateAccountOpeningBalance(
          id, account.openingBalanceInCents + currentBalanceInCents - actual);
    });
    reload();
  }

  void setAccountCurrentBalance(String id, int targetCents) {
    final account = accounts.where((item) => item.id == id).firstOrNull;
    if (account == null) throw ArgumentError('Conta não encontrada.');
    if (targetCents < 0 || targetCents >= 100000000000) {
      throw ArgumentError('Informe um saldo válido.');
    }
    final actual = FinancialRules.accountBalance(account, transactions);
    _repository.updateAccountOpeningBalance(
        id, account.openingBalanceInCents + targetCents - actual);
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
    if (type == TransactionType.transfer &&
        (destinationAccountId == null || destinationAccountId == accountId)) {
      throw ArgumentError('Escolha uma conta de destino diferente.');
    }
    if (type == TransactionType.transfer &&
        scheduleType != TransactionScheduleType.single) {
      throw ArgumentError('Transferências agendadas ainda não são permitidas.');
    }
    final recurringSalary = type == TransactionType.income &&
        category.trim().toLowerCase() == 'salário' &&
        scheduleType == TransactionScheduleType.recurring;
    if (!recurringSalary &&
        scheduleType != TransactionScheduleType.single &&
        (repeatCount < 2 || repeatCount > 60)) {
      throw ArgumentError('Use entre 2 e 60 repetições.');
    }
    final count =
        scheduleType == TransactionScheduleType.single ? 1 : repeatCount;
    final baseDate = occurredOn ?? _now;
    final cleanDescription = description.trim().isEmpty
        ? (type == TransactionType.transfer
            ? 'Transferência'
            : subcategory.trim().isNotEmpty && subcategory != 'Geral'
                ? subcategory.trim()
                : category.trim().isEmpty
                    ? 'Outros'
                    : category.trim())
        : description.trim();
    if (recurringSalary) {
      final now = _now;
      final startMonth = baseDate.isBefore(DateTime(now.year, now.month))
          ? DateTime(now.year, now.month)
          : DateTime(baseDate.year, baseDate.month);
      final last = DateTime(startMonth.year, startMonth.month + 1, 0).day;
      _repository.insertSalarySchedule(SalarySchedule(
          id: _id(),
          accountId: accountId,
          amountInCents: amountInCents,
          description: cleanDescription,
          subcategory: subcategory,
          firstDueOn: DateTime(
              startMonth.year, startMonth.month, baseDate.day.clamp(1, last)),
          paymentDay: baseDate.day,
          createdAt: _now));
      reload();
      return;
    }
    final seriesId = count == 1 ? null : _id();
    _repository.transaction(() {
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
          description: cleanDescription,
          category: category.trim().isEmpty ? 'Outros' : category.trim(),
          subcategory:
              subcategory.trim().isEmpty ? 'Geral' : subcategory.trim(),
          occurredOn: date,
          createdAt: _now,
          scheduleType: scheduleType,
          seriesId: seriesId,
          installmentNumber: index + 1,
          installmentCount: count,
          isSettled: !_dateOnly(date).isAfter(_dateOnly(_now)),
        ));
      }
    });
    reload();
  }

  void addTask(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Informe o título da tarefa.');
    }
    _repository
        .insertTask(TaskItem(id: _id(), title: title.trim(), createdAt: _now));
    reload();
  }

  void toggleTask(TaskItem task, bool value) {
    _repository.setTaskDone(task.id, value);
    reload();
  }

  void deleteTask(String id) {
    if (tasks.every((task) => task.id != id)) {
      throw ArgumentError('Tarefa não encontrada.');
    }
    _repository.deleteTask(id);
    reload();
  }

  void addShoppingItem({
    required String name,
    required int quantity,
    int? estimatedUnitPriceInCents,
    ShoppingPriority priority = ShoppingPriority.normal,
    String? imagePath,
    String? description,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do item.');
    if (quantity < 1 || quantity > 9999) {
      throw ArgumentError('A quantidade deve ficar entre 1 e 9999.');
    }
    if (estimatedUnitPriceInCents != null &&
        (estimatedUnitPriceInCents < 0 ||
            estimatedUnitPriceInCents >= 100000000000)) {
      throw ArgumentError('Informe um valor estimado válido.');
    }
    _repository.insertShoppingItem(ShoppingItem(
      id: _id(),
      name: cleanName,
      quantity: quantity,
      estimatedUnitPriceInCents: estimatedUnitPriceInCents,
      priority: priority,
      imagePath: imagePath,
      description: description?.trim() ?? '',
      createdAt: _now,
    ));
    reload();
  }

  void setShoppingItemImage(String id, String? imagePath) {
    if (shoppingItems.every((item) => item.id != id)) {
      throw ArgumentError('Item não encontrado.');
    }
    _repository.setShoppingItemImage(id, imagePath);
    reload();
  }

  void setShoppingItemPurchased(String id, bool value) {
    if (shoppingItems.every((item) => item.id != id)) {
      throw ArgumentError('Item não encontrado.');
    }
    _repository.setShoppingItemPurchased(id, value);
    reload();
  }

  void deleteShoppingItem(String id) {
    if (shoppingItems.every((item) => item.id != id)) {
      throw ArgumentError('Item não encontrado.');
    }
    _repository.deleteShoppingItem(id);
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
      createdAt: _now,
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
      purchasedOn: _now,
      installments: installments,
      createdAt: _now,
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
    int? quotedRateBasisPoints,
    InvestmentRatePeriod? quotedRatePeriod,
    int? yieldPaymentDay,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do ativo.');
    if (!FinancialRules.isValidAmount(investedAmountInCents)) {
      throw ArgumentError('Informe um valor investido válido.');
    }
    if (currentValueInCents < 0 || currentValueInCents >= 100000000000) {
      throw ArgumentError('Informe um saldo atual válido.');
    }
    _validateQuotedRate(quotedRateBasisPoints, quotedRatePeriod);
    _validateYieldDay(yieldPaymentDay);
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
      quotedRateBasisPoints: quotedRateBasisPoints,
      quotedRatePeriod: quotedRatePeriod,
      yieldPaymentDay: yieldPaymentDay,
      createdAt: _now,
    ));
    reload();
  }

  void updateInvestment({
    required String id,
    required String name,
    required InvestmentType type,
    required int investedAmountInCents,
    required int currentValueInCents,
    FixedIncomeType? fixedIncomeType,
    String? institutionName,
    DateTime? maturityDate,
    int? quotedRateBasisPoints,
    InvestmentRatePeriod? quotedRatePeriod,
    int? yieldPaymentDay,
  }) {
    final previous = investments.where((item) => item.id == id).firstOrNull;
    if (previous == null) throw ArgumentError('Investimento não encontrado.');
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do ativo.');
    if (!FinancialRules.isValidAmount(investedAmountInCents)) {
      throw ArgumentError('Informe um valor investido válido.');
    }
    if (currentValueInCents < 0 || currentValueInCents >= 100000000000) {
      throw ArgumentError('Informe um saldo atual válido.');
    }
    _validateQuotedRate(quotedRateBasisPoints, quotedRatePeriod);
    _validateYieldDay(yieldPaymentDay);
    _repository.updateInvestment(InvestmentPosition(
      id: id,
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
      quotedRateBasisPoints: quotedRateBasisPoints,
      quotedRatePeriod: quotedRatePeriod,
      yieldPaymentDay: yieldPaymentDay,
      createdAt: previous.createdAt,
    ));
    reload();
  }

  void _validateQuotedRate(int? basisPoints, InvestmentRatePeriod? period) {
    if ((basisPoints == null) != (period == null) ||
        (basisPoints != null &&
            (basisPoints < -10000 || basisPoints > 100000))) {
      throw ArgumentError('Informe uma taxa entre -100% e 1000% e o período.');
    }
  }

  void _validateYieldDay(int? day) {
    if (day != null && (day < 1 || day > 31)) {
      throw ArgumentError('O dia do rendimento deve estar entre 1 e 31.');
    }
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
    final date = period ?? _now;
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
      createdAt: _now,
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
    if (salarySchedules.any((item) => item.accountId == accountId)) {
      throw ArgumentError('Exclua o salário recorrente desta conta antes.');
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
      createdAt: _now,
    ));
    reload();
  }

  void deleteTransaction(String id) {
    final item = transactions.where((entry) => entry.id == id).firstOrNull;
    _repository.transaction(() {
      if (item?.category.toLowerCase() == 'salário' &&
          item?.seriesId != null &&
          salarySchedules.any((entry) => entry.id == item!.seriesId)) {
        _repository.deleteSalarySchedule(item!.seriesId!);
      }
      _repository.deleteTransaction(id);
    });
    reload();
  }

  void cancelSalarySchedule(String id) {
    if (salarySchedules.every((item) => item.id != id)) {
      throw ArgumentError('Salário recorrente não encontrado.');
    }
    _repository.deleteSalarySchedule(id);
    reload();
  }

  void updateTransactionDetails(String id, int cents, String description) {
    final item = transactions.where((item) => item.id == id).firstOrNull;
    if (item == null) throw ArgumentError('Lançamento não encontrado.');
    if (!FinancialRules.isValidAmount(cents)) {
      throw ArgumentError('Informe um valor válido.');
    }
    _repository.updateTransactionDetails(id, cents,
        description.trim().isEmpty ? item.category : description.trim());
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
    String category = 'Reserva',
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
      category: category,
      createdAt: _now,
    ));
    reload();
  }

  void addGoalCategory(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Informe uma categoria.');
    if (goalCategories
        .any((item) => item.toLowerCase() == clean.toLowerCase())) {
      throw ArgumentError('Essa categoria já existe.');
    }
    _repository.insertGoalCategory(clean);
    reload();
  }

  void updateMobileQuickPages(List<int> pages) {
    final normalized = pages.map((item) => item == 4 ? 6 : item).toList();
    if (normalized.length != 4 ||
        normalized.toSet().length != 4 ||
        normalized.any((item) => item < 0 || item > 11 || item == 9)) {
      throw ArgumentError('Escolha quatro atalhos diferentes.');
    }
    _repository.saveMobileQuickPages(normalized);
    reload();
  }

  void updateSubscription(
      {required String id,
      required String name,
      required int amountInCents,
      required int billingDay,
      required String category}) {
    final previous = subscriptions.where((item) => item.id == id).firstOrNull;
    if (previous == null) throw ArgumentError('Assinatura não encontrada.');
    if (name.trim().isEmpty ||
        !FinancialRules.isValidAmount(amountInCents) ||
        billingDay < 1 ||
        billingDay > 31) {
      throw ArgumentError('Informe nome, valor e dia de cobrança válidos.');
    }
    _repository.updateSubscription(Subscription(
        id: id,
        name: name.trim(),
        amountInCents: amountInCents,
        billingDay: billingDay,
        category: category,
        createdAt: previous.createdAt,
        isActive: previous.isActive));
    reload();
  }

  void setSubscriptionActive(String id, bool active) {
    if (subscriptions.every((item) => item.id != id)) {
      throw ArgumentError('Assinatura não encontrada.');
    }
    _repository.setSubscriptionActive(id, active);
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
      createdAt: _now,
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
      createdAt: _now,
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
    _salaryRefreshTimer?.cancel();
    _repository.close();
    super.dispose();
  }
}

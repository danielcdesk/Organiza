import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../domain/financial_rules.dart';
import '../domain/debt_rules.dart';
import '../domain/recurring_obligation_rules.dart';
import '../domain/credit_card_rules.dart';
import '../domain/business_date.dart';
import '../domain/models.dart';
import '../domain/app_route.dart';
import '../services/backup_service.dart';
import '../services/backup_images.dart';
import '../services/notifications/local_notification_service.dart';
import '../services/notifications/reminder_schedule.dart';

class OrganizaStore extends ChangeNotifier with WidgetsBindingObserver {
  OrganizaStore._(this._repository, Clock? clock,
      {LocalNotificationService? notificationService})
      : _clock = clock ?? const Clock(),
        _notificationService = notificationService;

  final LocalRepository _repository;
  final Clock _clock;
  final LocalNotificationService? _notificationService;
  final _uuid = const Uuid();
  Timer? _salaryRefreshTimer;
  bool _scheduleRefreshTimer = false;

  DateTime get _now => _clock.now();
  Clock get clock => _clock;

  void _scheduleNextDayRefresh() {
    _salaryRefreshTimer?.cancel();
    final now = _now;
    final next = DateTime(now.year, now.month, now.day + 1, 0, 1);
    _salaryRefreshTimer = Timer(next.difference(now), () {
      reload();
      if (_scheduleRefreshTimer) _scheduleNextDayRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // reload uses the injected Clock for due occurrences and invoice state.
      reload();
      if (_scheduleRefreshTimer) _scheduleNextDayRefresh();
    }
  }

  List<Account> accounts = [];
  List<TransactionRecord> transactions = [];
  List<TaskItem> tasks = [];
  List<ShoppingItem> shoppingItems = [];
  List<CreditCard> creditCards = [];
  List<CardPurchase> cardPurchases = [];
  List<CardInvoice> cardInvoices = [];
  List<TransactionRecord> cardInstallmentTransactions = [];
  List<TransactionRecord> get reportTransactions => [
        ...transactions.where(
            (item) => item.cardInvoiceId == null && item.debtPaymentId == null),
        ...cardInstallmentTransactions,
        for (final payment in debtPayments)
          if (payment.interestInCents > 0)
            TransactionRecord(
              id: 'debt-interest-${payment.id}',
              accountId: debts
                  .firstWhere((debt) => debt.id == payment.debtId)
                  .accountId,
              type: TransactionType.expense,
              amountInCents: payment.interestInCents,
              description:
                  'Juros: ${debts.firstWhere((debt) => debt.id == payment.debtId).name}',
              category: debts
                  .firstWhere((debt) => debt.id == payment.debtId)
                  .category,
              occurredOn: payment.paidOn,
              createdAt: payment.paidOn,
            ),
      ];
  List<Debt> debts = [];
  List<DebtPayment> debtPayments = [];
  List<RecurringObligation> recurringObligations = [];
  List<InvestmentPosition> investments = [];
  List<Budget> budgets = [];
  List<Subscription> subscriptions = [];
  List<FinancialGoal> financialGoals = [];
  List<FinanceCategory> financeCategories = [];
  List<FinanceSubcategory> financeSubcategories = [];
  List<SalarySchedule> salarySchedules = [];
  List<String> goalCategories = [];
  List<AppRoute> mobileQuickPages = const [
    AppRoute.overview,
    AppRoute.finances,
    AppRoute.organization,
    AppRoute.reports,
  ];
  SalaryAllocation salaryAllocation = SalaryAllocation.defaults;
  bool get distributionConfigured =>
      _repository.loadPreference('allocation_configured') == 'true' ||
      salaryAllocation.essentialsPercent != 50 ||
      salaryAllocation.goalsPercent != 30 ||
      salaryAllocation.freePercent != 20;
  SalaryAllocation? allocationForMonth(DateTime month) =>
      _repository.loadSalaryAllocationForMonth(month);
  String get themePreference => _repository.loadPreference('theme') ?? 'dark';
  bool get hideValuesPreference =>
      _repository.loadPreference('hide_values') == 'true';
  bool get remindersEnabled =>
      _repository.loadPreference('reminders_enabled') == 'true';
  int get reminderDaysAhead =>
      int.tryParse(_repository.loadPreference('reminder_days') ?? '') ?? 1;
  int get reminderHour =>
      int.tryParse(_repository.loadPreference('reminder_hour') ?? '') ?? 9;
  int get reminderMinute =>
      int.tryParse(_repository.loadPreference('reminder_minute') ?? '') ?? 0;
  bool get appLockEnabled =>
      _repository.loadPreference('app_lock_enabled') == 'true';
  int get appLockTimeoutMinutes =>
      int.tryParse(_repository.loadPreference('app_lock_timeout') ?? '') ?? 0;
  bool get lockOnWindowHide =>
      _repository.loadPreference('lock_on_window_hide') == 'true';
  String get shoppingViewPreference =>
      _repository.loadPreference('shopping_view') == 'cards' ? 'cards' : 'list';
  String get profileName => _repository.loadPreference('profile_name') ?? '';
  int get profileIncomeInCents =>
      int.tryParse(_repository.loadPreference('profile_income_cents') ?? '') ??
      0;

  /// Budgeting base, not a cash-flow entry. A profile amount must not be
  /// added to the same salary's scheduled or recorded transactions.
  int get planningIncomeInCents =>
      profileIncomeInCents > 0 ? profileIncomeInCents : salaryThisMonth;
  int get emergencyReserveTargetMonths =>
      int.tryParse(_repository.loadPreference('reserve_target_months') ?? '') ??
      6;
  int get emergencyReserveBalanceInCents =>
      int.tryParse(_repository.loadPreference('reserve_balance_cents') ?? '') ??
      0;
  Set<String> get emergencyReserveExcludedCategoryIds {
    final saved = _repository.loadPreference('reserve_excluded_categories');
    if (saved == null || saved.isEmpty) return const {};
    try {
      return (jsonDecode(saved) as List).whereType<String>().toSet();
    } on FormatException {
      return const {};
    }
  }

  void updateEmergencyReserveSettings({
    int? targetMonths,
    int? reserveBalanceInCents,
    Set<String>? excludedCategoryIds,
  }) {
    if (targetMonths != null && (targetMonths < 1 || targetMonths > 120)) {
      throw ArgumentError('Informe entre 1 e 120 meses para a reserva.');
    }
    if (reserveBalanceInCents != null && reserveBalanceInCents < 0) {
      throw ArgumentError('Informe um saldo de reserva válido.');
    }
    if (excludedCategoryIds != null &&
        excludedCategoryIds.any(
            (id) => financeCategories.every((category) => category.id != id))) {
      throw ArgumentError('Categoria não encontrada.');
    }
    _repository.transaction(() {
      if (targetMonths != null) {
        _repository.savePreference('reserve_target_months', '$targetMonths');
      }
      if (reserveBalanceInCents != null) {
        _repository.savePreference(
            'reserve_balance_cents', '$reserveBalanceInCents');
      }
      if (excludedCategoryIds != null) {
        _repository.savePreference('reserve_excluded_categories',
            jsonEncode(excludedCategoryIds.toList()..sort()));
      }
    });
    notifyListeners();
  }

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

  void saveHideValuesPreference(bool value) {
    _repository.savePreference('hide_values', value.toString());
    unawaited(_rescheduleReminders());
  }

  Future<bool> setRemindersEnabled(bool enabled) async {
    if (enabled &&
        _notificationService != null &&
        !await _notificationService.requestPermission()) {
      return false;
    }
    _repository.savePreference('reminders_enabled', enabled.toString());
    await _rescheduleReminders();
    notifyListeners();
    return true;
  }

  Future<void> updateReminderPreferences(
      {int? daysAhead, int? hour, int? minute}) async {
    if (daysAhead != null && ![0, 1, 3].contains(daysAhead)) {
      throw ArgumentError('Antecedência inválida.');
    }
    if (hour != null && (hour < 0 || hour > 23)) {
      throw ArgumentError('Horário inválido.');
    }
    if (minute != null && (minute < 0 || minute > 59)) {
      throw ArgumentError('Horário inválido.');
    }
    if (daysAhead != null) {
      _repository.savePreference('reminder_days', '$daysAhead');
    }
    if (hour != null) _repository.savePreference('reminder_hour', '$hour');
    if (minute != null) {
      _repository.savePreference('reminder_minute', '$minute');
    }
    await _rescheduleReminders();
    notifyListeners();
  }

  void updateAppLockPreferences(
      {required bool enabled,
      required int timeoutMinutes,
      required bool onWindowHide}) {
    if (![0, 1, 5, 15, 30].contains(timeoutMinutes)) {
      throw ArgumentError('Intervalo de bloqueio inválido.');
    }
    _repository.savePreference('app_lock_enabled', enabled.toString());
    _repository.savePreference('app_lock_timeout', '$timeoutMinutes');
    _repository.savePreference('lock_on_window_hide', onWindowHide.toString());
    notifyListeners();
  }

  void setAppLockEnabled(bool enabled) => updateAppLockPreferences(
        enabled: enabled,
        timeoutMinutes: appLockTimeoutMinutes,
        onWindowHide: lockOnWindowHide,
      );

  void setAppLockTimeout(int minutes) => updateAppLockPreferences(
        enabled: appLockEnabled,
        timeoutMinutes: minutes,
        onWindowHide: lockOnWindowHide,
      );

  void setLockOnWindowHide(bool value) => updateAppLockPreferences(
        enabled: appLockEnabled,
        timeoutMinutes: appLockTimeoutMinutes,
        onWindowHide: value,
      );

  Future<void> _rescheduleReminders() async {
    final service = _notificationService;
    if (service == null) return;
    if (!remindersEnabled) {
      await service.cancelAll();
      return;
    }
    try {
      final reminders = ReminderSchedule(clock: _clock).calculate(
        transactions: transactions,
        invoices: cardInvoices,
        subscriptions: subscriptions,
        daysAhead: reminderDaysAhead,
        hour: reminderHour,
        minute: reminderMinute,
        hideValues: hideValuesPreference,
      );
      await service.reschedule(reminders);
    } on Object {
      // Notification availability is optional; it must never prevent app use.
    }
  }

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
    WidgetsFlutterBinding.ensureInitialized();
    final store = OrganizaStore._(await LocalRepository.open(), clock,
        notificationService: LocalNotificationService());
    WidgetsBinding.instance.addObserver(store);
    store._scheduleRefreshTimer = true;
    store.reload();
    store._scheduleNextDayRefresh();
    return store;
  }

  static OrganizaStore inMemory({Clock? clock}) {
    WidgetsFlutterBinding.ensureInitialized();
    final store = OrganizaStore._(LocalRepository.inMemory(), clock);
    WidgetsBinding.instance.addObserver(store);
    store.reload();
    return store;
  }

  Future<File> exportEncryptedBackup(String password) async =>
      const BackupService().exportEncrypted(
          await BackupImages.embed(_repository.exportSnapshot()), password);

  Future<File> restoreEncryptedBackup(File file, String password) async {
    final snapshot =
        await const BackupService().decryptEncrypted(file, password);
    final safetyCopy = await exportEncryptedBackup(password);
    final images = await BackupImages.restorePrepared(snapshot);
    try {
      _repository.restoreSnapshot(images.snapshot);
    } catch (_) {
      await images.deleteCreatedFiles();
      rethrow;
    }
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
    _rebuildCardInvoices();
    cardInvoices = _repository.loadCardInvoices();
    cardInstallmentTransactions = _repository.loadCardInstallmentTransactions();
    investments = _repository.loadInvestments();
    debts = _repository.loadDebts();
    debtPayments = _repository.loadDebtPayments();
    recurringObligations = _repository.loadRecurringObligations();
    budgets = _repository.loadBudgets();
    subscriptions = _repository.loadSubscriptions();
    salaryAllocation = _repository.loadSalaryAllocation();
    financialGoals = _repository.loadFinancialGoals();
    financeCategories = _repository.loadFinanceCategories();
    financeSubcategories = _repository.loadFinanceSubcategories();
    goalCategories = _repository.loadGoalCategories();
    mobileQuickPages = _repository.loadMobileQuickPages();
    if (remindersEnabled) unawaited(_rescheduleReminders());
    notifyListeners();
  }

  void _rebuildCardInvoices() {
    final now = BusinessDate.from(_now);
    _repository.transaction(() {
      _repository.clearUnpaidInvoiceItems();
      _repository.deleteEmptyUnpaidInvoices();
      _repository.closeExpiredCardInvoices(now);
      for (final purchase in cardPurchases) {
        final card =
            creditCards.where((item) => item.id == purchase.cardId).firstOrNull;
        if (card == null) continue;
        for (var index = 1; index <= purchase.installments; index++) {
          if (_repository.hasCardInvoiceItem(purchase.id, index)) continue;
          final closing =
              CreditCardRules.installmentClosingDate(card, purchase, index);
          final previous = DateTime.utc(
              closing.year,
              closing.month - 1,
              card.closingDay
                  .clamp(1, DateTime.utc(closing.year, closing.month, 0).day));
          final status = now.isAfter(closing)
              ? CardInvoiceStatus.closed
              : CardInvoiceStatus.open;
          final invoiceId = _repository.ensureCardInvoice(
            id: _id(),
            cardId: card.id,
            cycleStart: previous.add(const Duration(days: 1)),
            closingDate: closing,
            dueDate: CreditCardRules.invoiceDueDate(card, closing),
            status: status,
            createdAt: _now,
          );
          _repository.insertCardInvoiceItem(
            id: _id(),
            invoiceId: invoiceId,
            purchaseId: purchase.id,
            installmentNumber: index,
            amountInCents: CreditCardRules.installmentAmount(purchase, index),
          );
        }
      }
    });
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
            !DateTime.utc(schedule.firstDueOn.year, schedule.firstDueOn.month)
                .isAfter(DateTime.utc(now.year, now.month)) &&
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
          final calendarMonth = DateTime.utc(
              schedule.firstDueOn.year, schedule.firstDueOn.month + month);
          final last =
              DateTime.utc(calendarMonth.year, calendarMonth.month + 1, 0).day;
          final due = DateTime.utc(calendarMonth.year, calendarMonth.month,
              schedule.paymentDay.clamp(1, last));
          if (_dateOnly(due).isAfter(today)) break;
          final exists = transactions.any((item) =>
              item.seriesId == schedule.id &&
              item.occurredOn.year == due.year &&
              item.occurredOn.month == due.month);
          if (exists) continue;
          if (_repository.isSalaryOccurrenceSkipped(schedule.id, due)) continue;
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
            incomeSource: schedule.incomeSource,
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
    if (openingBalanceInCents.abs() >= 100000000000) {
      throw ArgumentError(
          'O saldo deve ficar entre -R\$ 1 bilhão e R\$ 1 bilhão.');
    }
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
    if (currentBalanceInCents.abs() >= 100000000000) {
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
    if (targetCents.abs() >= 100000000000) {
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
    String? incomeSource,
    ExpenseEssentiality? essentialityOverride,
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
      final businessBase = BusinessDate.from(baseDate);
      final startMonth =
          businessBase.isBefore(DateTime.utc(now.year, now.month))
              ? DateTime.utc(now.year, now.month)
              : DateTime.utc(businessBase.year, businessBase.month);
      final last = DateTime.utc(startMonth.year, startMonth.month + 1, 0).day;
      _repository.insertSalarySchedule(SalarySchedule(
          id: _id(),
          accountId: accountId,
          amountInCents: amountInCents,
          description: cleanDescription,
          subcategory: subcategory,
          firstDueOn: DateTime.utc(
              startMonth.year, startMonth.month, baseDate.day.clamp(1, last)),
          paymentDay: baseDate.day,
          createdAt: _now,
          incomeSource: incomeSource?.trim().isEmpty == true
              ? null
              : incomeSource?.trim()));
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
          incomeSource: incomeSource?.trim().isEmpty == true
              ? null
              : incomeSource?.trim(),
          essentialityOverride: essentialityOverride,
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
    String? issuer,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do cartão.');
    if (!RegExp(r'^\d{4}$').hasMatch(lastFour)) {
      throw ArgumentError('Informe os quatro últimos dígitos.');
    }
    if (!FinancialRules.isValidAmount(limitInCents)) {
      throw ArgumentError('Informe um limite válido.');
    }
    if (closingDay < 1 || closingDay > 31 || dueDay < 1 || dueDay > 31) {
      throw ArgumentError(
          'Fechamento e vencimento devem estar entre os dias 1 e 31.');
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
      issuer: issuer?.trim().isEmpty == true ? null : issuer?.trim(),
      createdAt: _now,
    ));
    reload();
  }

  void addCardPurchase({
    required String cardId,
    required String description,
    required int amountInCents,
    required int installments,
    DateTime? purchasedOn,
    String category = 'Outros',
    String subcategory = 'Geral',
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
      purchasedOn: _dateOnly(purchasedOn ?? _now),
      installments: installments,
      createdAt: _now,
      category: category,
      subcategory: subcategory,
    ));
    reload();
  }

  void editCardPurchase({
    required String id,
    required String cardId,
    required String description,
    required int amountInCents,
    required int installments,
    required DateTime purchasedOn,
    required String category,
    required String subcategory,
  }) {
    _repository.assertCardPurchaseHasNoPaidInvoice(id);
    if (creditCards.every((card) => card.id != cardId)) {
      throw ArgumentError('Cartão não encontrado.');
    }
    if (description.trim().isEmpty ||
        !FinancialRules.isValidAmount(amountInCents)) {
      throw ArgumentError('Informe uma descrição e um valor válidos.');
    }
    if (installments < 1 || installments > 48) {
      throw ArgumentError('O número de parcelas deve estar entre 1 e 48.');
    }
    _repository.transaction(() {
      _repository.clearUnpaidInvoiceItems();
      _repository.deleteCardPurchase(id);
      _repository.insertCardPurchase(CardPurchase(
        id: id,
        cardId: cardId,
        description: description.trim(),
        amountInCents: amountInCents,
        purchasedOn: _dateOnly(purchasedOn),
        installments: installments,
        createdAt: cardPurchases.firstWhere((item) => item.id == id).createdAt,
        category: category,
        subcategory: subcategory,
      ));
    });
    reload();
  }

  void deleteCardPurchase(String id) {
    _repository.assertCardPurchaseHasNoPaidInvoice(id);
    _repository.transaction(() {
      _repository.clearUnpaidInvoiceItems();
      _repository.deleteCardPurchase(id);
    });
    reload();
  }

  void editCreditCard(CreditCard card) {
    _repository.updateCreditCard(card);
    reload();
  }

  void deleteCreditCard(String id) {
    _repository.deleteCreditCard(id);
    reload();
  }

  void payCardInvoice(String invoiceId, String accountId, {DateTime? paidOn}) {
    final paymentDate = _dateOnly(paidOn ?? _now);
    if (paymentDate.isAfter(_dateOnly(_now))) {
      throw ArgumentError('A data do pagamento não pode ser futura.');
    }
    final invoice =
        cardInvoices.where((item) => item.id == invoiceId).firstOrNull;
    if (invoice == null) throw ArgumentError('Fatura não encontrada.');
    if (invoice.status != CardInvoiceStatus.closed) {
      throw StateError('A fatura só pode ser paga após o fechamento.');
    }
    if (invoice.totalInCents <= 0) {
      throw StateError('A fatura não tem valor para pagar.');
    }
    if (accounts.every((account) => account.id != accountId)) {
      throw ArgumentError('Conta não encontrada.');
    }
    final card = creditCards.firstWhere((item) => item.id == invoice.cardId);
    final transactionId = _id();
    final transaction = TransactionRecord(
      id: transactionId,
      accountId: accountId,
      type: TransactionType.expense,
      amountInCents: invoice.totalInCents,
      description: 'Pagamento fatura ${card.name}',
      category: 'Pagamento de fatura',
      subcategory: card.name,
      occurredOn: paymentDate,
      createdAt: _now,
      cardInvoiceId: invoice.id,
    );
    _repository.transaction(() {
      _repository.insertTransaction(transaction);
      _repository.markCardInvoicePaid(
          id: _id(),
          invoiceId: invoice.id,
          transactionId: transactionId,
          paidOn: paymentDate,
          amountInCents: invoice.totalInCents);
    });
    reload();
  }

  void reverseCardInvoicePayment(String invoiceId) {
    final invoice =
        cardInvoices.where((item) => item.id == invoiceId).firstOrNull;
    if (invoice?.status != CardInvoiceStatus.paid) {
      throw StateError('A fatura não possui pagamento para estornar.');
    }
    _repository
        .transaction(() => _repository.reverseCardInvoicePayment(invoiceId));
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
    if (debts.any((item) => item.accountId == accountId) ||
        recurringObligations.any((item) => item.accountId == accountId)) {
      throw ArgumentError(
          'Exclua as dívidas e contas recorrentes desta conta antes.');
    }
    _repository.deleteAccount(accountId);
    reload();
  }

  void addSubscription({
    required String name,
    required int amountInCents,
    required int billingDay,
    required String category,
    String? iconKey,
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
      iconKey: iconKey,
      createdAt: _now,
    ));
    reload();
  }

  List<TransactionRecord> deleteTransaction(
    String id, {
    TransactionSeriesScope scope = TransactionSeriesScope.occurrence,
  }) {
    final item = transactions.where((entry) => entry.id == id).firstOrNull;
    if (item == null) throw ArgumentError('Lançamento não encontrado.');
    if (item.cardInvoiceId != null) {
      throw StateError('Estorne o pagamento da fatura pela área de cartões.');
    }
    if (item.debtPaymentId != null || item.recurringObligationId != null) {
      throw StateError(
          'Desfaça o pagamento na área de dívidas e contas recorrentes.');
    }
    final isSalaryOccurrence = item.category.toLowerCase() == 'salário' &&
        item.seriesId != null &&
        salarySchedules.any((entry) => entry.id == item.seriesId);
    if (isSalaryOccurrence && scope != TransactionSeriesScope.occurrence) {
      throw StateError(
          'Para encerrar os próximos salários, use a ação explícita de cancelar a recorrência.');
    }
    final removed = item.seriesId == null ||
            scope == TransactionSeriesScope.occurrence ||
            isSalaryOccurrence
        ? [item]
        : transactions.where((candidate) {
            if (candidate.seriesId != item.seriesId) return false;
            return scope == TransactionSeriesScope.entireSeries ||
                candidate.installmentNumber >= item.installmentNumber;
          }).toList();
    _repository.transaction(() {
      if (isSalaryOccurrence) {
        _repository.skipSalaryOccurrence(
            _id(), item.seriesId!, item.occurredOn, _now);
      }
      _repository.deleteTransactionRows(removed.map((row) => row.id));
    });
    reload();
    return removed;
  }

  void restoreDeletedTransactions(List<TransactionRecord> removed) {
    if (removed.isEmpty) return;
    _repository.transaction(() {
      for (final item in removed) {
        if (item.cardInvoiceId != null) continue;
        if (item.seriesId != null &&
            salarySchedules.any((schedule) => schedule.id == item.seriesId)) {
          _repository.unskipSalaryOccurrence(item.seriesId!, item.occurredOn);
        }
        _repository.insertTransaction(item);
      }
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
    updateTransactionSeries(
      id: id,
      amountInCents: cents,
      description: description.trim().isEmpty ? item.category : description,
      category: item.category,
      subcategory: item.subcategory,
      accountId: item.accountId,
      destinationAccountId: item.destinationAccountId,
      occurredOn: item.occurredOn,
      scope: TransactionSeriesScope.occurrence,
    );
  }

  void updateTransactionSeries({
    required String id,
    required int amountInCents,
    required String description,
    required String category,
    required String subcategory,
    required String accountId,
    required String? destinationAccountId,
    required DateTime occurredOn,
    String? incomeSource,
    ExpenseEssentiality? essentialityOverride,
    TransactionSeriesScope scope = TransactionSeriesScope.occurrence,
  }) {
    final selected = transactions.where((item) => item.id == id).firstOrNull;
    if (selected == null) throw ArgumentError('Lançamento não encontrado.');
    if (selected.cardInvoiceId != null) {
      throw StateError(
          'O pagamento da fatura deve ser alterado na área de cartões.');
    }
    if (selected.debtPaymentId != null ||
        selected.recurringObligationId != null) {
      throw StateError(
          'Desfaça o pagamento na área de dívidas e contas recorrentes.');
    }
    if (!FinancialRules.isValidAmount(amountInCents)) {
      throw ArgumentError('Informe um valor válido.');
    }
    if (accounts.every((item) => item.id != accountId)) {
      throw ArgumentError('Selecione uma conta válida.');
    }
    if (selected.type == TransactionType.transfer &&
        (destinationAccountId == null ||
            destinationAccountId == accountId ||
            accounts.every((item) => item.id != destinationAccountId))) {
      throw ArgumentError('Escolha uma conta de destino diferente.');
    }
    final isSalary = selected.category.toLowerCase() == 'salário' &&
        selected.seriesId != null &&
        salarySchedules.any((schedule) => schedule.id == selected.seriesId);
    final targets =
        selected.seriesId == null || scope == TransactionSeriesScope.occurrence
            ? [selected]
            : transactions.where((candidate) {
                if (candidate.seriesId != selected.seriesId) return false;
                return scope == TransactionSeriesScope.entireSeries ||
                    candidate.installmentNumber >= selected.installmentNumber;
              }).toList()
          ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
    if (targets.isEmpty) return;
    final cleanDescription =
        description.trim().isEmpty ? selected.category : description.trim();
    final cleanCategory = isSalary
        ? 'Salário'
        : category.trim().isEmpty
            ? 'Outros'
            : category.trim();
    final cleanSubcategory =
        subcategory.trim().isEmpty ? 'Geral' : subcategory.trim();
    final baseDate = _dateOnly(occurredOn);
    final updates = <TransactionRecord>[];
    for (var index = 0; index < targets.length; index++) {
      final current = targets[index];
      final amount =
          selected.scheduleType == TransactionScheduleType.installment
              ? _installmentValue(amountInCents, targets.length, index)
              : amountInCents;
      final date = selected.seriesId == null ||
              scope == TransactionSeriesScope.occurrence
          ? baseDate
          : _addMonths(
              baseDate, _monthOffset(current.occurredOn, selected.occurredOn));
      updates.add(TransactionRecord(
        id: current.id,
        accountId: accountId,
        destinationAccountId: destinationAccountId,
        type: current.type,
        amountInCents: amount,
        description: cleanDescription,
        occurredOn: date,
        createdAt: current.createdAt,
        category: cleanCategory,
        subcategory: cleanSubcategory,
        scheduleType: current.scheduleType,
        seriesId: current.seriesId,
        installmentNumber: current.installmentNumber,
        installmentCount: current.installmentCount,
        isSettled: !_dateOnly(date).isAfter(_dateOnly(_now)),
        incomeSource: incomeSource ?? current.incomeSource,
        essentialityOverride:
            essentialityOverride ?? current.essentialityOverride,
      ));
    }
    _repository.transaction(() {
      if (isSalary && scope != TransactionSeriesScope.occurrence) {
        final schedule =
            salarySchedules.firstWhere((item) => item.id == selected.seriesId);
        final firstDue = scope == TransactionSeriesScope.entireSeries
            ? _addMonths(baseDate,
                -_monthOffset(selected.occurredOn, schedule.firstDueOn))
            : baseDate;
        _repository.updateSalarySchedule(SalarySchedule(
          id: schedule.id,
          accountId: accountId,
          amountInCents: amountInCents,
          description: cleanDescription,
          subcategory: cleanSubcategory,
          firstDueOn: firstDue,
          paymentDay: firstDue.day,
          createdAt: schedule.createdAt,
          incomeSource: incomeSource ?? schedule.incomeSource,
        ));
      }
      for (final update in updates) {
        _repository.updateTransactionRecord(update);
      }
    });
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
    int colorValue = 0xFFFF9800,
    String note = '',
    String? imagePath,
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
      colorValue: colorValue,
      note: note.trim(),
      imagePath: imagePath,
      createdAt: _now,
    ));
    reload();
  }

  void updateFinancialGoal({
    required String id,
    required String name,
    required int targetInCents,
    required String iconKey,
    required String category,
    DateTime? deadline,
    int colorValue = 0xFFFF9800,
    String note = '',
    String? imagePath,
    bool removeImage = false,
  }) {
    final previous = financialGoals.where((item) => item.id == id).firstOrNull;
    if (previous == null) throw ArgumentError('Meta não encontrada.');
    if (name.trim().isEmpty ||
        !FinancialRules.isValidAmount(targetInCents) ||
        targetInCents < previous.savedInCents) {
      throw ArgumentError(
          'O objetivo deve ser válido e não menor que o valor já guardado.');
    }
    _repository.updateFinancialGoal(FinancialGoal(
      id: id,
      name: name.trim(),
      targetInCents: targetInCents,
      savedInCents: previous.savedInCents,
      deadline: deadline,
      iconKey: iconKey,
      category: category,
      colorValue: colorValue,
      note: note.trim(),
      imagePath: removeImage ? null : imagePath ?? previous.imagePath,
      createdAt: previous.createdAt,
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

  void updateMobileQuickPages(List<AppRoute> pages) {
    if (pages.length != 4 ||
        pages.toSet().length != 4 ||
        pages.any((route) => !route.quick)) {
      throw ArgumentError('Escolha quatro atalhos diferentes.');
    }
    _repository.saveMobileQuickPages(pages);
    reload();
  }

  void updateSubscription(
      {required String id,
      required String name,
      required int amountInCents,
      required int billingDay,
      required String category,
      String? iconKey}) {
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
        iconKey: iconKey,
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

  void addDebt({
    required String name,
    required int principalInCents,
    required int monthlyInterestBasisPoints,
    required int installmentAmountInCents,
    required DateTime firstDueOn,
    required int installments,
    required String accountId,
    String category = 'Empréstimos',
  }) {
    if (name.trim().isEmpty ||
        principalInCents <= 0 ||
        installmentAmountInCents <= 0 ||
        installments < 1 ||
        installments > 360 ||
        monthlyInterestBasisPoints < 0 ||
        monthlyInterestBasisPoints > 10000 ||
        accounts.every((account) => account.id != accountId)) {
      throw ArgumentError('Dados da dívida inválidos.');
    }
    DebtRules.splitInstallment(
      outstandingPrincipalInCents: principalInCents,
      installmentAmountInCents: installmentAmountInCents,
      monthlyInterestBasisPoints: monthlyInterestBasisPoints,
    );
    _repository.insertDebt(Debt(
      id: _id(),
      name: name.trim(),
      originalPrincipalInCents: principalInCents,
      outstandingPrincipalInCents: principalInCents,
      monthlyInterestBasisPoints: monthlyInterestBasisPoints,
      installmentAmountInCents: installmentAmountInCents,
      firstDueOn: BusinessDate.from(firstDueOn),
      installmentsRemaining: installments,
      accountId: accountId,
      category: category.trim().isEmpty ? 'Empréstimos' : category.trim(),
      isActive: true,
      createdAt: _now,
    ));
    reload();
  }

  void editDebt(Debt debt) {
    if (debts.every((item) => item.id != debt.id)) {
      throw ArgumentError('Dívida não encontrada.');
    }
    _repository.updateDebt(debt);
    reload();
  }

  void deleteDebt(String id) {
    if (debtPayments.any((item) => item.debtId == id)) {
      throw StateError('Estorne as parcelas antes de excluir a dívida.');
    }
    _repository.deleteDebt(id);
    reload();
  }

  void recordDebtInstallment(String debtId, {DateTime? paidOn}) {
    final debt = debts.where((item) => item.id == debtId).firstOrNull;
    if (debt == null ||
        !debt.isActive ||
        debt.installmentsRemaining <= 0 ||
        debt.outstandingPrincipalInCents <= 0) {
      throw StateError('Dívida sem parcela disponível.');
    }
    final part = DebtRules.splitInstallment(
      outstandingPrincipalInCents: debt.outstandingPrincipalInCents,
      installmentAmountInCents: debt.installmentAmountInCents,
      monthlyInterestBasisPoints: debt.monthlyInterestBasisPoints,
    );
    final paymentId = _id();
    final transactionId = _id();
    final date = BusinessDate.from(paidOn ?? _now);
    if (date.isAfter(BusinessDate.from(_now))) {
      throw ArgumentError('Não é possível pagar uma parcela em data futura.');
    }
    _repository.transaction(() {
      _repository.insertTransaction(TransactionRecord(
        id: transactionId,
        accountId: debt.accountId,
        type: TransactionType.expense,
        amountInCents: part.paymentInCents,
        description: 'Parcela: ${debt.name}',
        category: debt.category,
        occurredOn: date,
        createdAt: _now,
        debtPaymentId: paymentId,
      ));
      _repository.insertDebtPayment(DebtPayment(
        id: paymentId,
        debtId: debt.id,
        transactionId: transactionId,
        principalInCents: part.principalInCents,
        interestInCents: part.interestInCents,
        paidOn: date,
      ));
      _repository.updateDebt(Debt(
        id: debt.id,
        name: debt.name,
        originalPrincipalInCents: debt.originalPrincipalInCents,
        outstandingPrincipalInCents:
            debt.outstandingPrincipalInCents - part.principalInCents,
        monthlyInterestBasisPoints: debt.monthlyInterestBasisPoints,
        installmentAmountInCents: debt.installmentAmountInCents,
        firstDueOn: debt.firstDueOn,
        installmentsRemaining: debt.installmentsRemaining - 1,
        accountId: debt.accountId,
        category: debt.category,
        isActive: debt.isActive &&
            debt.outstandingPrincipalInCents > part.principalInCents,
        createdAt: debt.createdAt,
      ));
    });
    reload();
  }

  void undoDebtInstallment(String paymentId) {
    final payment =
        debtPayments.where((item) => item.id == paymentId).firstOrNull;
    if (payment == null) throw ArgumentError('Parcela não encontrada.');
    if (debtPayments.firstWhere((item) => item.debtId == payment.debtId).id !=
        paymentId) {
      throw StateError('Estorne primeiro a parcela mais recente.');
    }
    final debt = debts.firstWhere((item) => item.id == payment.debtId);
    _repository.transaction(() {
      _repository.deleteDebtPayment(paymentId);
      _repository.deleteTransaction(payment.transactionId);
      _repository.updateDebt(Debt(
        id: debt.id,
        name: debt.name,
        originalPrincipalInCents: debt.originalPrincipalInCents,
        outstandingPrincipalInCents:
            debt.outstandingPrincipalInCents + payment.principalInCents,
        monthlyInterestBasisPoints: debt.monthlyInterestBasisPoints,
        installmentAmountInCents: debt.installmentAmountInCents,
        firstDueOn: debt.firstDueOn,
        installmentsRemaining: debt.installmentsRemaining + 1,
        accountId: debt.accountId,
        category: debt.category,
        isActive: true,
        createdAt: debt.createdAt,
      ));
    });
    reload();
  }

  void addRecurringObligation({
    required String name,
    required String category,
    required String accountId,
    required int estimatedAmountInCents,
    required int billingDay,
    required DateTime nextDueOn,
  }) {
    if (name.trim().isEmpty ||
        estimatedAmountInCents <= 0 ||
        billingDay < 1 ||
        billingDay > 31 ||
        accounts.every((account) => account.id != accountId)) {
      throw ArgumentError('Dados da conta recorrente inválidos.');
    }
    _repository.insertRecurringObligation(RecurringObligation(
      id: _id(),
      name: name.trim(),
      category: category.trim().isEmpty ? 'Outros' : category.trim(),
      accountId: accountId,
      estimatedAmountInCents: estimatedAmountInCents,
      billingDay: billingDay,
      nextDueOn: RecurringObligationRules.monthlyDue(nextDueOn,
          billingDay: billingDay, monthOffset: 0),
      isActive: true,
      createdAt: _now,
    ));
    reload();
  }

  void editRecurringObligation(RecurringObligation obligation) {
    if (recurringObligations.every((item) => item.id != obligation.id) ||
        obligation.name.trim().isEmpty ||
        obligation.estimatedAmountInCents <= 0 ||
        obligation.billingDay < 1 ||
        obligation.billingDay > 31) {
      throw ArgumentError('Dados da conta recorrente inválidos.');
    }
    _repository.updateRecurringObligation(obligation);
    reload();
  }

  void deleteRecurringObligation(String id) {
    _repository.deleteRecurringObligation(id);
    reload();
  }

  void confirmRecurringObligation(String id, {int? amountInCents}) {
    final obligation =
        recurringObligations.where((item) => item.id == id).firstOrNull;
    if (obligation == null || !obligation.isActive) {
      throw StateError('Conta recorrente inativa ou ausente.');
    }
    final amount = amountInCents ?? obligation.estimatedAmountInCents;
    if (!FinancialRules.isValidAmount(amount)) {
      throw ArgumentError('Informe um valor válido.');
    }
    final transactionId = _id();
    final date = BusinessDate.from(_now);
    _repository.transaction(() {
      _repository.insertTransaction(TransactionRecord(
        id: transactionId,
        accountId: obligation.accountId,
        type: TransactionType.expense,
        amountInCents: amount,
        description: obligation.name,
        category: obligation.category,
        occurredOn: date,
        createdAt: _now,
        recurringObligationId: obligation.id,
      ));
      _repository.insertRecurringObligationOccurrence(
          _id(), obligation.id, transactionId, obligation.nextDueOn);
      _repository.updateRecurringObligation(RecurringObligation(
        id: obligation.id,
        name: obligation.name,
        category: obligation.category,
        accountId: obligation.accountId,
        estimatedAmountInCents: obligation.estimatedAmountInCents,
        billingDay: obligation.billingDay,
        nextDueOn: RecurringObligationRules.monthlyDue(obligation.nextDueOn,
            billingDay: obligation.billingDay, monthOffset: 1),
        isActive: obligation.isActive,
        createdAt: obligation.createdAt,
      ));
    });
    reload();
  }

  void undoRecurringObligationConfirmation(String transactionId) {
    final transaction = transactions
        .where((item) =>
            item.id == transactionId && item.recurringObligationId != null)
        .firstOrNull;
    if (transaction == null) {
      throw ArgumentError('Confirmação não encontrada.');
    }
    final obligation = recurringObligations
        .where((item) => item.id == transaction.recurringObligationId)
        .firstOrNull;
    if (obligation == null) {
      throw StateError('A conta recorrente já foi removida.');
    }
    if (_repository.latestRecurringObligationTransactionId(obligation.id) !=
        transactionId) {
      throw StateError('Desfaça primeiro a confirmação mais recente.');
    }
    _repository.transaction(() {
      _repository.deleteRecurringObligationOccurrence(transactionId);
      _repository.deleteTransaction(transactionId);
      _repository.updateRecurringObligation(RecurringObligation(
        id: obligation.id,
        name: obligation.name,
        category: obligation.category,
        accountId: obligation.accountId,
        estimatedAmountInCents: obligation.estimatedAmountInCents,
        billingDay: obligation.billingDay,
        nextDueOn: RecurringObligationRules.monthlyDue(obligation.nextDueOn,
            billingDay: obligation.billingDay, monthOffset: -1),
        isActive: obligation.isActive,
        createdAt: obligation.createdAt,
      ));
    });
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

  void setFinanceCategoryEssentiality(
      String categoryId, ExpenseEssentiality value) {
    if (financeCategories.every((item) => item.id != categoryId)) {
      throw ArgumentError('Categoria não encontrada.');
    }
    _repository.setFinanceCategoryEssentiality(categoryId, value);
    reload();
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
    final allocation = SalaryAllocation(
      essentialsPercent: essentialsPercent,
      goalsPercent: goalsPercent,
      freePercent: freePercent,
    );
    _repository.transaction(() {
      _repository.saveSalaryAllocation(allocation);
      _repository.saveSalaryAllocationForMonth(allocation, _now);
      _repository.savePreference('allocation_configured', 'true');
    });
    reload();
  }

  String _id() => _uuid.v4();

  static DateTime _dateOnly(DateTime value) => BusinessDate.from(value);

  static DateTime _addMonths(DateTime value, int months) {
    return BusinessDate.addMonths(value, months);
  }

  static int _monthOffset(DateTime date, DateTime from) =>
      (date.year - from.year) * 12 + date.month - from.month;

  static int _installmentValue(int total, int count, int zeroBasedIndex) {
    final base = total ~/ count;
    final remainder = total % count;
    return base + (zeroBasedIndex < remainder ? 1 : 0);
  }

  @override
  void dispose() {
    _salaryRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _repository.close();
    super.dispose();
  }
}

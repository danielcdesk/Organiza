import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import '../services/backup_service.dart';
import '../services/backup_coordinator.dart';
import '../services/app_storage_paths.dart';
import '../services/local_image_service.dart';
import '../services/backup_folder_service.dart';
import '../services/secret_vault.dart';
import '../domain/backup_schedule.dart';
import 'package:path/path.dart' as path;

class OrganizaStore extends ChangeNotifier {
  OrganizaStore._(this._repository, Clock? clock)
      : _clock = clock ?? const Clock();

  final LocalRepository _repository;
  final Clock _clock;
  final _uuid = const Uuid();
  Timer? _salaryRefreshTimer;
  Timer? _backupTimer;
  bool _backupRunning = false;
  Completer<void>? _backupFinished;
  static const _backupFolder = BackupFolderService();
  static const _vault = SystemSecretVault();
  static const _backupPasswordKey = 'organiza.backup.password';

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
  List<SalaryAllocationBucket> salaryAllocationBuckets = [];
  String get themePreference => _repository.loadPreference('theme') ?? 'dark';
  String get accentPreference =>
      _repository.loadPreference('accent_color') ?? 'organiza';
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

  bool get automaticBackupEnabled =>
      _repository.loadPreference('backup_enabled') == 'true';
  bool get backupOnClose =>
      _repository.loadPreference('backup_on_close') == 'true';
  int get backupIntervalDays =>
      int.tryParse(_repository.loadPreference('backup_interval_days') ?? '') ??
      7;
  int get backupRetention =>
      int.tryParse(_repository.loadPreference('backup_retention') ?? '') ?? 3;
  String? get lastBackupAt => _repository.loadPreference('backup_last_success');
  bool get backupOverdue => BackupSchedule.isDue(_now,
      enabled: automaticBackupEnabled,
      intervalDays: (backupIntervalDays * 2).clamp(1, 365),
      lastSuccess: DateTime.tryParse(lastBackupAt ?? ''));
  String? get backupError => _repository.loadPreference('backup_last_error');
  String? get _desktopBackupFolder =>
      _repository.loadPreference('backup_desktop_folder');

  Future<String?> chooseAutomaticBackupFolder() => _backupFolder.choose();

  Future<void> discardAutomaticBackupFolder(String selected) =>
      _backupFolder.discard(selected);

  Future<void> configureAutomaticBackup({
    required bool enabled,
    required int intervalDays,
    required int retention,
    required bool onClose,
    String? password,
    String? selectedFolder,
  }) async {
    if (intervalDays < 1 ||
        intervalDays > 365 ||
        retention < 1 ||
        retention > 30) {
      throw ArgumentError('Intervalo ou retenção fora dos limites.');
    }
    if (enabled) {
      if (!await _backupFolder.configured(_desktopBackupFolder,
          candidate: selectedFolder)) {
        throw StateError('Escolha primeiro a pasta dos backups.');
      }
      if (password != null) {
        if (password.length < 8) throw ArgumentError('Senha muito curta.');
        await _vault.write(_backupPasswordKey, password);
      } else if (await _vault.read(_backupPasswordKey) == null) {
        throw StateError('Informe a senha do backup.');
      }
      if (selectedFolder != null) {
        await _backupFolder.commit(selectedFolder);
        if (!Platform.isAndroid) {
          _repository.savePreference('backup_desktop_folder', selectedFolder);
        }
      }
    }
    _repository.savePreference('backup_enabled', '$enabled');
    _repository.savePreference('backup_interval_days', '$intervalDays');
    _repository.savePreference('backup_retention', '$retention');
    _repository.savePreference('backup_on_close', '$onClose');
    if (!enabled) await _vault.delete(_backupPasswordKey);
    notifyListeners();
    if (enabled) unawaited(runAutomaticBackup());
  }

  Future<void> runAutomaticBackup(
      {bool closing = false, bool force = false}) async {
    if (_backupRunning) {
      if (closing) await _backupFinished?.future;
      return;
    }
    if (!automaticBackupEnabled) return;
    final last = DateTime.tryParse(lastBackupAt ?? '');
    if (!force &&
        !BackupSchedule.isDue(_now,
            enabled: true,
            intervalDays: backupIntervalDays,
            lastSuccess: last,
            closing: closing,
            backupOnClose: backupOnClose)) {
      return;
    }
    _backupRunning = true;
    _backupFinished = Completer<void>();
    File? temporary;
    try {
      final password = await _vault.read(_backupPasswordKey);
      if (password == null) {
        throw StateError('Senha do backup não está no cofre seguro.');
      }
      if (!await _backupFolder.configured(_desktopBackupFolder)) {
        throw StateError('Pasta de backup indisponível.');
      }
      final name =
          'organiza-auto-${_now.toUtc().toIso8601String().replaceAll(':', '-')}-${_uuid.v4()}.organizabak';
      final pending = File(path.join(
          AppStoragePaths.rootDirectory.path, 'backup-pending.organizabak'));
      // A previous process can leave this encrypted scratch file behind.
      if (await pending.exists()) await pending.delete();
      temporary = await exportEncryptedBackup(password, destination: pending);
      await _backupFolder.save(temporary, name, _desktopBackupFolder);
      _repository.savePreference('backup_last_success', _now.toIso8601String());
      _repository.savePreference('backup_last_error', '');
      final existing = await _backupFolder.list(_desktopBackupFolder)
        ..sort();
      for (final old in existing.reversed.skip(backupRetention)) {
        await _backupFolder.delete(old, _desktopBackupFolder);
      }
    } on Object catch (error) {
      _repository.savePreference('backup_last_error', '$error');
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      _backupRunning = false;
      _backupFinished?.complete();
      _backupFinished = null;
      notifyListeners();
    }
  }

  void saveThemePreference(String value) {
    if (!const ['light', 'dark', 'system'].contains(value)) {
      throw ArgumentError('Tema inválido.');
    }
    _repository.savePreference('theme', value);
  }

  void saveAccentPreference(String value) {
    if (!const {
      'organiza',
      'blue',
      'green',
      'purple',
      'pink',
      'red',
      'teal',
      'neutral'
    }.contains(value)) {
      throw ArgumentError('Cor de destaque inválida.');
    }
    _repository.savePreference('accent_color', value);
    notifyListeners();
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
    await AppStoragePaths.initialize();
    final oldPaths = <String>{
      if (store.profilePhotoPath != null) store.profilePhotoPath!,
      ...store._repository
          .loadShoppingItems()
          .map((item) => item.imagePath)
          .whereType<String>(),
    };
    store._repository.rewriteImagePaths(
        await LocalImageService.importLegacyImages(oldPaths));
    store.reload();
    store._scheduleNextDayRefresh();
    store._backupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      unawaited(store.runAutomaticBackup());
    });
    unawaited(store.runAutomaticBackup());
    return store;
  }

  static OrganizaStore inMemory({Clock? clock}) {
    final store = OrganizaStore._(LocalRepository.inMemory(), clock);
    store.reload();
    return store;
  }

  Future<File> exportEncryptedBackup(String password,
      {File? destination}) async {
    if (_repository.filePath == null) {
      return const BackupService()
          .exportEncrypted(_repository.exportSnapshot(), password);
    }
    await AppStoragePaths.initialize();
    final file = destination ??
        File(path.join(AppStoragePaths.rootDirectory.path, 'backups',
            'organiza-${_now.toUtc().toIso8601String().replaceAll(':', '-')}.organizabak'));
    return BackupCoordinator(_repository).export(password, file);
  }

  Future<BackupPreview> prepareBackup(File file, String password) =>
      BackupCoordinator(_repository).prepare(file, password);

  Future<File> confirmBackup(BackupPreview preview) async {
    if (_backupRunning) {
      await preview.dispose();
      throw StateError('Aguarde o backup automático terminar.');
    }
    final safety = await BackupCoordinator(_repository).confirm(preview);
    // Folder permissions and the vault secret belong to this installation.
    // A restored preference must never silently run a scheduled backup elsewhere.
    _repository.savePreference('backup_enabled', 'false');
    _repository.savePreference('backup_desktop_folder', '');
    reload();
    return safety;
  }

  Future<File> restoreEncryptedBackup(File file, String password) async {
    if (_repository.filePath != null) {
      final preview = await prepareBackup(file, password);
      return confirmBackup(preview);
    }
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
    salaryAllocationBuckets = _loadSalaryAllocationBuckets();
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
    final profileIncome = profileIncomeInCents;
    if (profileIncome > 0) return profileIncome;

    final month = DateTime(_now.year, _now.month);
    final currentSchedules = salarySchedules.where((schedule) =>
        !DateTime(schedule.firstDueOn.year, schedule.firstDueOn.month)
            .isAfter(month));
    final scheduleIds = currentSchedules.map((schedule) => schedule.id).toSet();
    final scheduledIncome = currentSchedules.fold<int>(
        0, (sum, schedule) => sum + schedule.amountInCents);
    final oneOffIncome = transactions.where((item) {
      final category = item.category.trim().toLowerCase();
      return item.type == TransactionType.income &&
          (category == 'salário' || category == 'salario') &&
          item.occurredOn.year == month.year &&
          item.occurredOn.month == month.month &&
          !scheduleIds.contains(item.seriesId);
    }).fold<int>(0, (sum, item) => sum + item.amountInCents);
    return scheduledIncome + oneOffIncome;
  }

  int get allocatedSalaryPercent => salaryAllocationBuckets.fold(
      0, (total, bucket) => total + bucket.percent);

  int allocationLimitInCents(SalaryAllocationBucket bucket) =>
      (salaryThisMonth * bucket.percent / 100).round();

  int allocationSpentInCents(SalaryAllocationBucket bucket,
      {DateTime? period}) {
    final date = period ?? _now;
    final names = {
      bucket.name.toLowerCase(),
      ...bucket.linkedCategories.map((name) => name.toLowerCase()),
    };
    return transactions
        .where((item) =>
            item.type == TransactionType.expense &&
            item.isSettled &&
            item.occurredOn.year == date.year &&
            item.occurredOn.month == date.month &&
            names.contains(item.category.toLowerCase()))
        .fold(0, (total, item) => total + item.amountInCents);
  }

  void addSalaryAllocationBucket({
    required String name,
    required int percent,
    String iconKey = 'category',
    int colorValue = 0xFF4F6BED,
    List<String> linkedCategories = const [],
  }) {
    final clean = name.trim();
    if (clean.isEmpty || percent < 0 || percent > 100) {
      throw ArgumentError('Informe nome e porcentagem entre 0% e 100%.');
    }
    if (salaryAllocationBuckets
        .any((item) => item.name.toLowerCase() == clean.toLowerCase())) {
      throw ArgumentError('Essa divisão já existe.');
    }
    final expenseCategoryExists = financeCategories.any((item) =>
        item.type == TransactionType.expense &&
        item.name.toLowerCase() == clean.toLowerCase());
    if (!expenseCategoryExists) {
      addFinanceCategory(clean, TransactionType.expense);
    }
    final claims = linkedCategories.isEmpty ? [clean] : linkedCategories;
    _releaseAllocationCategories(null, clean, claims);
    salaryAllocationBuckets = [
      ...salaryAllocationBuckets,
      SalaryAllocationBucket(
        id: _id(),
        name: clean,
        percent: percent,
        iconKey: iconKey,
        colorValue: colorValue,
        sortOrder: salaryAllocationBuckets.length,
        linkedCategories: claims,
      ),
    ];
    _saveSalaryAllocationBuckets();
  }

  void updateSalaryAllocationBucket(SalaryAllocationBucket updated) {
    if (updated.name.trim().isEmpty ||
        updated.percent < 0 ||
        updated.percent > 100) {
      throw ArgumentError('Informe nome e porcentagem entre 0% e 100%.');
    }
    if (salaryAllocationBuckets.every((item) => item.id != updated.id)) {
      throw ArgumentError('Divisão não encontrada.');
    }
    if (salaryAllocationBuckets.any((item) =>
        item.id != updated.id &&
        item.name.toLowerCase() == updated.name.trim().toLowerCase())) {
      throw ArgumentError('Essa divisão já existe.');
    }
    _releaseAllocationCategories(
        updated.id, updated.name.trim(), updated.linkedCategories);
    salaryAllocationBuckets = salaryAllocationBuckets
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    _saveSalaryAllocationBuckets();
  }

  void _releaseAllocationCategories(
      String? ownerId, String ownerName, List<String> names) {
    final claimed = names.map((name) => name.toLowerCase()).toSet();
    claimed.add(ownerName.toLowerCase());
    if (salaryAllocationBuckets.any((item) =>
        item.id != ownerId && claimed.contains(item.name.toLowerCase()))) {
      throw ArgumentError(
          'Uma categoria com o nome de outra divisão não pode ser vinculada.');
    }
    salaryAllocationBuckets = salaryAllocationBuckets
        .map((item) => item.id == ownerId
            ? item
            : item.copyWith(
                linkedCategories: item.linkedCategories
                    .where((name) => !claimed.contains(name.toLowerCase()))
                    .toList()))
        .toList();
  }

  void deleteSalaryAllocationBucket(String id) {
    final bucket =
        salaryAllocationBuckets.where((item) => item.id == id).firstOrNull;
    if (bucket == null) throw ArgumentError('Divisão não encontrada.');
    if (bucket.isSystem) {
      throw ArgumentError(
          'As divisões padrão podem ser editadas, mas não excluídas.');
    }
    salaryAllocationBuckets =
        salaryAllocationBuckets.where((item) => item.id != id).toList();
    _saveSalaryAllocationBuckets();
  }

  void reorderSalaryAllocationBucket(int oldIndex, int newIndex) {
    final next = List<SalaryAllocationBucket>.of(salaryAllocationBuckets);
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    salaryAllocationBuckets = [
      for (var index = 0; index < next.length; index++)
        next[index].copyWith(sortOrder: index),
    ];
    _saveSalaryAllocationBuckets();
  }

  List<SalaryAllocationBucket> _loadSalaryAllocationBuckets() {
    final raw = _repository.loadPreference('salary_allocation_buckets');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final buckets = decoded.map((entry) {
          final map = entry as Map<String, dynamic>;
          return SalaryAllocationBucket(
            id: map['id'] as String,
            name: map['name'] as String,
            percent: map['percent'] as int,
            iconKey: map['iconKey'] as String? ?? 'category',
            colorValue: map['colorValue'] as int? ?? 0xFF4F6BED,
            sortOrder: map['sortOrder'] as int? ?? 0,
            linkedCategories:
                (map['linkedCategories'] as List<dynamic>? ?? const [])
                    .map((value) => value.toString())
                    .toList(),
            isSystem: map['isSystem'] as bool? ?? false,
          );
        }).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (buckets.isNotEmpty) return buckets;
      } catch (_) {
        // Keep the app usable by falling back to the legacy 50/30/20 values.
      }
    }
    return [
      SalaryAllocationBucket(
        id: 'essentials',
        name: 'Essenciais',
        percent: salaryAllocation.essentialsPercent,
        iconKey: 'home',
        colorValue: 0xFF3D7A67,
        sortOrder: 0,
        linkedCategories: const [
          'Alimentação',
          'Moradia',
          'Transporte',
          'Saúde',
          'Contas e serviços',
          'Pets'
        ],
        isSystem: true,
      ),
      SalaryAllocationBucket(
        id: 'goals',
        name: 'Objetivos',
        percent: salaryAllocation.goalsPercent,
        iconKey: 'target',
        colorValue: 0xFF4F6BED,
        sortOrder: 1,
        linkedCategories: const ['Educação', 'Investimentos'],
        isSystem: true,
      ),
      SalaryAllocationBucket(
        id: 'free',
        name: 'Livre',
        percent: salaryAllocation.freePercent,
        iconKey: 'sparkles',
        colorValue: 0xFFB64F21,
        sortOrder: 2,
        linkedCategories: const ['Lazer', 'Compras', 'Outros'],
        isSystem: true,
      ),
    ];
  }

  void _saveSalaryAllocationBuckets() {
    _repository.savePreference('salary_allocation_buckets',
        _salaryBucketJson(salaryAllocationBuckets));
    notifyListeners();
  }

  String _salaryBucketJson(List<SalaryAllocationBucket> buckets) {
    final payload = buckets
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'percent': item.percent,
              'iconKey': item.iconKey,
              'colorValue': item.colorValue,
              'sortOrder': item.sortOrder,
              'linkedCategories': item.linkedCategories,
              'isSystem': item.isSystem,
            })
        .toList();
    return jsonEncode(payload);
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

  void updateShoppingItem({
    required String id,
    required String name,
    required int quantity,
    int? estimatedUnitPriceInCents,
    required ShoppingPriority priority,
    required bool isPurchased,
    String? imagePath,
    String description = '',
  }) {
    final previous = shoppingItems.where((item) => item.id == id).firstOrNull;
    if (previous == null) throw ArgumentError('Item não encontrado.');
    final clean = name.trim();
    if (clean.isEmpty || quantity < 1 || quantity > 9999) {
      throw ArgumentError('Revise o nome e a quantidade.');
    }
    if (estimatedUnitPriceInCents != null &&
        (estimatedUnitPriceInCents < 0 ||
            estimatedUnitPriceInCents >= 100000000000)) {
      throw ArgumentError('Informe um valor estimado válido.');
    }
    _repository.updateShoppingItem(ShoppingItem(
      id: id,
      name: clean,
      quantity: quantity,
      estimatedUnitPriceInCents: estimatedUnitPriceInCents,
      priority: priority,
      isPurchased: isPurchased,
      imagePath: imagePath,
      description: description.trim(),
      createdAt: previous.createdAt,
    ));
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

  void setCardPurchaseInstallmentsPaid(
    String purchaseId,
    Set<int> paidInstallments,
  ) {
    final purchase = cardPurchases.where((item) => item.id == purchaseId);
    if (purchase.isEmpty) throw ArgumentError('Compra não encontrada.');
    final installmentCount = purchase.first.installments;
    if (paidInstallments
        .any((number) => number < 1 || number > installmentCount)) {
      throw ArgumentError('Parcela inválida para esta compra.');
    }
    _repository.setCardPurchaseInstallmentsPaid(
      purchaseId,
      paidInstallments,
      _now,
    );
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

  void updateTransaction(TransactionRecord updated,
      {bool applyToFuture = false}) {
    final previous =
        transactions.where((item) => item.id == updated.id).firstOrNull;
    if (previous == null) throw ArgumentError('Lançamento não encontrado.');
    if (!FinancialRules.isValidAmount(updated.amountInCents)) {
      throw ArgumentError('Informe um valor válido.');
    }
    if (accounts.every((account) => account.id != updated.accountId)) {
      throw ArgumentError('Conta não encontrada.');
    }
    if (updated.type == TransactionType.transfer &&
        (updated.destinationAccountId == null ||
            updated.destinationAccountId == updated.accountId ||
            accounts.every(
                (account) => account.id != updated.destinationAccountId))) {
      throw ArgumentError('Escolha uma conta de destino diferente.');
    }
    final description = updated.description.trim().isEmpty
        ? (updated.subcategory == 'Geral'
            ? updated.category
            : updated.subcategory)
        : updated.description.trim();
    final affected = applyToFuture && previous.seriesId != null
        ? transactions
            .where((item) =>
                item.seriesId == previous.seriesId &&
                !item.occurredOn.isBefore(previous.occurredOn))
            .toList()
        : [previous];
    final dateShift = updated.occurredOn.difference(previous.occurredOn);
    _repository.transaction(() {
      for (final item in affected) {
        _repository.updateTransaction(TransactionRecord(
          id: item.id,
          accountId: updated.accountId,
          destinationAccountId: updated.type == TransactionType.transfer
              ? updated.destinationAccountId
              : null,
          type: updated.type,
          amountInCents: updated.amountInCents,
          description: description,
          occurredOn: item.occurredOn.add(dateShift),
          createdAt: item.createdAt,
          category: updated.type == TransactionType.transfer
              ? 'Transferência'
              : updated.category,
          subcategory: updated.type == TransactionType.transfer
              ? 'Entre contas'
              : updated.subcategory,
          categoryId:
              updated.type == item.type && updated.category == item.category
                  ? item.categoryId
                  : null,
          subcategoryId: updated.type == item.type &&
                  updated.category == item.category &&
                  updated.subcategory == item.subcategory
              ? item.subcategoryId
              : null,
          scheduleType: item.scheduleType,
          seriesId: item.seriesId,
          installmentNumber: item.installmentNumber,
          installmentCount: item.installmentCount,
          isSettled:
              item.id == previous.id ? updated.isSettled : item.isSettled,
        ));
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
        categoryId: category == previous.category ? previous.categoryId : null,
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

  void renameFinanceCategory(String id, String newName) {
    final original =
        financeCategories.where((item) => item.id == id).firstOrNull;
    if (original == null) throw ArgumentError('Categoria não encontrada.');
    final clean = newName.trim();
    if (clean.isEmpty) throw ArgumentError('Informe o nome da categoria.');
    final updatedBuckets = original.type == TransactionType.expense
        ? salaryAllocationBuckets
            .map((bucket) => bucket.copyWith(
                  linkedCategories: bucket.linkedCategories
                      .map((name) =>
                          name.toLowerCase() == original.name.toLowerCase()
                              ? clean
                              : name)
                      .toList(),
                ))
            .toList()
        : salaryAllocationBuckets;
    _repository.transaction(() {
      _repository.renameFinanceCategory(id, clean);
      _repository.savePreference(
          'salary_allocation_buckets', _salaryBucketJson(updatedBuckets));
    });
    reload();
  }

  void archiveFinanceCategory(String id) {
    final category =
        financeCategories.where((item) => item.id == id).firstOrNull;
    if (category == null || category.isSystem) {
      throw ArgumentError(
          'Somente categorias personalizadas podem ser arquivadas.');
    }
    _repository.archiveFinanceCategory(id, at: _now);
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
    _repository.saveSalaryAllocation(SalaryAllocation(
      essentialsPercent: essentialsPercent,
      goalsPercent: goalsPercent,
      freePercent: freePercent,
    ));
    salaryAllocationBuckets = salaryAllocationBuckets.map((bucket) {
      final percent = switch (bucket.id) {
        'essentials' => essentialsPercent,
        'goals' => goalsPercent,
        'free' => freePercent,
        _ => bucket.percent,
      };
      return bucket.copyWith(percent: percent);
    }).toList();
    _saveSalaryAllocationBuckets();
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
    _backupTimer?.cancel();
    _repository.close();
    super.dispose();
  }
}

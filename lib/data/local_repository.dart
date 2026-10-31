import 'dart:io';

import '../database/app_database.dart';
import '../domain/models.dart';

/// Data boundary used by application services; UI and domain never import SQLite.
class LocalRepository {
  LocalRepository._(this._database) : _filePath = _database.filePath;
  AppDatabase _database;
  final String? _filePath;
  bool _closed = false;

  static Future<LocalRepository> open() async =>
      LocalRepository._(await AppDatabase.open());

  static LocalRepository openAtFile(File file) =>
      LocalRepository._(AppDatabase.openFile(file));

  static LocalRepository inMemory() =>
      LocalRepository._(AppDatabase.openInMemory());

  String? get filePath => _filePath;
  Map<String, int> get tableCounts => _database.tableCounts;
  Future<void> createConsistentCopy(File destination) =>
      _database.createConsistentCopy(destination);
  void validateIntegrity() => _database.validateIntegrity();
  void rewriteImagePaths(Map<String, String> replacements) =>
      _database.rewriteImagePaths(replacements);

  void closeForReplacement() {
    if (_filePath == null) {
      throw StateError(
          'O banco em memória não pode ser substituído por arquivo.');
    }
    close();
  }

  void reopenAfterReplacement() {
    if (_filePath == null || !_closed) {
      throw StateError('Feche o banco persistente antes de reabri-lo.');
    }
    final reopened = AppDatabase.openFile(File(_filePath));
    _database = reopened;
    _closed = false;
  }

  List<Account> loadAccounts() => _database.loadAccounts();
  List<Tag> loadTags() => _database.loadTags();
  List<Tag> loadTransactionTags(String transactionId) =>
      _database.loadTransactionTags(transactionId);
  Map<String, List<Tag>> loadAllTransactionTags() =>
      _database.loadAllTransactionTags();
  void insertTag(Tag tag) => _database.insertTag(tag);
  void updateTag(Tag tag) => _database.updateTag(tag);
  bool deleteTag(String id) => _database.deleteTag(id);
  void setTransactionTags(String transactionId, Set<String> tagIds) =>
      _database.setTransactionTags(transactionId, tagIds);
  List<Attachment> loadAttachments(String transactionId) =>
      _database.loadAttachments(transactionId);
  void insertAttachment(Attachment attachment) =>
      _database.insertAttachment(attachment);
  String? deleteAttachment(String id) => _database.deleteAttachment(id);
  List<TransactionRecord> loadTransactions() => _database.loadTransactions();
  List<TaskItem> loadTasks() => _database.loadTasks();
  List<ShoppingItem> loadShoppingItems() => _database.loadShoppingItems();
  List<CreditCard> loadCreditCards() => _database.loadCreditCards();
  List<CardPurchase> loadCardPurchases() => _database.loadCardPurchases();
  List<CardInvoice> loadCardInvoices() => _database.loadCardInvoices();
  List<CardInvoicePayment> loadCardInvoicePayments() =>
      _database.loadCardInvoicePayments();
  List<InvestmentPosition> loadInvestments() => _database.loadInvestments();
  List<Budget> loadBudgets() => _database.loadBudgets();
  List<Subscription> loadSubscriptions() => _database.loadSubscriptions();
  List<SalarySchedule> loadSalarySchedules() => _database.loadSalarySchedules();
  List<String> loadGoalCategories() => _database.loadGoalCategories();
  List<int> loadMobileQuickPages() => _database.loadMobileQuickPages();
  String? loadPreference(String key) => _database.loadPreference(key);
  void savePreference(String key, String value) =>
      _database.savePreference(key, value);
  void saveMobileQuickPages(List<int> pages) =>
      _database.saveMobileQuickPages(pages);
  void insertSalarySchedule(SalarySchedule item) =>
      _database.insertSalarySchedule(item);
  void deleteSalarySchedule(String id) => _database.deleteSalarySchedule(id);
  void insertGoalCategory(String name) => _database.insertGoalCategory(name);
  void updateAccountOpeningBalance(String id, int cents) =>
      _database.updateAccountOpeningBalance(id, cents);
  void updateAccountDetails({
    required String id,
    required String name,
    required AccountInstitution institution,
    AccountType type = AccountType.checking,
    String currency = 'BRL',
    String? customInstitutionName,
    String? customIconKey,
  }) =>
      _database.updateAccountDetails(
        id: id,
        name: name,
        institution: institution,
        type: type,
        currency: currency,
        customInstitutionName: customInstitutionName,
        customIconKey: customIconKey,
      );
  bool setAccountArchived(String id, DateTime? archivedAt) =>
      _database.setAccountArchived(id, archivedAt);
  bool setAccountNetWorthIncluded(String id, bool included) =>
      _database.setAccountNetWorthIncluded(id, included);
  void updateSubscription(Subscription item) =>
      _database.updateSubscription(item);
  void setSubscriptionActive(String id, bool active) =>
      _database.setSubscriptionActive(id, active);
  SalaryAllocation loadSalaryAllocation() => _database.loadSalaryAllocation();
  Map<String, Object?> exportSnapshot() => _database.exportSnapshot();
  void restoreSnapshot(Map<String, dynamic> snapshot) =>
      _database.restoreSnapshot(snapshot);
  List<FinancialGoal> loadFinancialGoals() => _database.loadFinancialGoals();
  List<FinanceCategory> loadFinanceCategories() =>
      _database.loadFinanceCategories();
  List<FinanceSubcategory> loadFinanceSubcategories() =>
      _database.loadFinanceSubcategories();
  void insertAccount(Account item) => _database.insertAccount(item);
  void insertTransaction(TransactionRecord item) =>
      _database.insertTransaction(item);
  void insertTask(TaskItem item) => _database.insertTask(item);
  void setTaskDone(String id, bool value) => _database.setTaskDone(id, value);
  void insertShoppingItem(ShoppingItem item) =>
      _database.insertShoppingItem(item);
  void setShoppingItemPurchased(String id, bool value) =>
      _database.setShoppingItemPurchased(id, value);
  void updateShoppingItem(ShoppingItem item) =>
      _database.updateShoppingItem(item);
  void setShoppingItemImage(String id, String? imagePath) =>
      _database.setShoppingItemImage(id, imagePath);
  void insertCreditCard(CreditCard item) => _database.insertCreditCard(item);
  void insertCardPurchase(CardPurchase item) =>
      _database.insertCardPurchase(item);
  void insertCardInvoice(CardInvoice item) => _database.insertCardInvoice(item);
  void updateCardInvoiceStatus(
          String id, CardInvoiceStatus status, DateTime updatedAt) =>
      _database.updateCardInvoiceStatus(id, status, updatedAt);
  void insertCardInvoicePayment(CardInvoicePayment item) =>
      _database.insertCardInvoicePayment(item);
  void deleteCardInvoicePayment(String id) =>
      _database.deleteCardInvoicePayment(id);
  void setCardPurchaseInstallmentsPaid(
    String purchaseId,
    Set<int> paidInstallments,
    DateTime paidOn,
  ) =>
      _database.setCardPurchaseInstallmentsPaid(
        purchaseId,
        paidInstallments,
        paidOn,
      );
  void insertInvestment(InvestmentPosition item) =>
      _database.insertInvestment(item);
  void updateInvestment(InvestmentPosition item) =>
      _database.updateInvestment(item);
  void insertBudget(Budget item) => _database.insertBudget(item);
  void insertSubscription(Subscription item) =>
      _database.insertSubscription(item);
  void insertFinancialGoal(FinancialGoal item) =>
      _database.insertFinancialGoal(item);
  void insertFinanceCategory(FinanceCategory item) =>
      _database.insertFinanceCategory(item);
  void renameFinanceCategory(String id, String newName) =>
      _database.renameFinanceCategory(id, newName);
  void archiveFinanceCategory(String id, {DateTime? at}) =>
      _database.archiveFinanceCategory(id, at: at);
  void insertFinanceSubcategory(FinanceSubcategory item) =>
      _database.insertFinanceSubcategory(item);
  void setTransactionSettled(String id, bool value) =>
      _database.setTransactionSettled(id, value);
  void updateFinancialGoalSaved(String id, int savedInCents) =>
      _database.updateFinancialGoalSaved(id, savedInCents);
  void updateTransactionDetails(String id, int cents, String description) =>
      _database.updateTransactionDetails(id, cents, description);
  void updateTransaction(TransactionRecord item) =>
      _database.updateTransaction(item);
  bool softDelete(SoftDeleteEntity entity, String id, DateTime deletedAtUtc) =>
      _database.softDelete(entity, id, deletedAtUtc);
  bool restore(SoftDeleteEntity entity, String id) =>
      _database.restore(entity, id);
  void saveSalaryAllocation(SalaryAllocation item) =>
      _database.saveSalaryAllocation(item);
  void transaction(void Function() operation) =>
      _database.transaction(operation);
  void close() {
    if (_closed) return;
    _database.close();
    _closed = true;
  }
}

import '../database/app_database.dart';
import '../domain/models.dart';
import '../domain/app_route.dart';

/// Data boundary used by application services; UI and domain never import SQLite.
class LocalRepository {
  LocalRepository._(this._database);
  final AppDatabase _database;

  static Future<LocalRepository> open() async =>
      LocalRepository._(await AppDatabase.open());

  static LocalRepository inMemory() =>
      LocalRepository._(AppDatabase.openInMemory());

  List<Account> loadAccounts() => _database.loadAccounts();
  List<TransactionRecord> loadTransactions() => _database.loadTransactions();
  List<TaskItem> loadTasks() => _database.loadTasks();
  List<ShoppingItem> loadShoppingItems() => _database.loadShoppingItems();
  List<CreditCard> loadCreditCards() => _database.loadCreditCards();
  List<CardPurchase> loadCardPurchases() => _database.loadCardPurchases();
  List<CardInvoice> loadCardInvoices() => _database.loadCardInvoices();
  List<TransactionRecord> loadCardInstallmentTransactions() =>
      _database.loadCardInstallmentTransactions();
  List<InvestmentPosition> loadInvestments() => _database.loadInvestments();
  List<Budget> loadBudgets() => _database.loadBudgets();
  List<Subscription> loadSubscriptions() => _database.loadSubscriptions();
  List<SalarySchedule> loadSalarySchedules() => _database.loadSalarySchedules();
  List<String> loadGoalCategories() => _database.loadGoalCategories();
  List<AppRoute> loadMobileQuickPages() => _database.loadMobileQuickPages();
  String? loadPreference(String key) => _database.loadPreference(key);
  void savePreference(String key, String value) =>
      _database.savePreference(key, value);
  void saveMobileQuickPages(List<AppRoute> pages) =>
      _database.saveMobileQuickPages(pages);
  void insertSalarySchedule(SalarySchedule item) =>
      _database.insertSalarySchedule(item);
  void deleteSalarySchedule(String id) => _database.deleteSalarySchedule(id);
  void updateSalarySchedule(SalarySchedule item) =>
      _database.updateSalarySchedule(item);
  bool isSalaryOccurrenceSkipped(String scheduleId, DateTime date) =>
      _database.isSalaryOccurrenceSkipped(scheduleId, date);
  void skipSalaryOccurrence(
          String id, String scheduleId, DateTime date, DateTime createdAt) =>
      _database.skipSalaryOccurrence(id, scheduleId, date, createdAt);
  void unskipSalaryOccurrence(String scheduleId, DateTime date) =>
      _database.unskipSalaryOccurrence(scheduleId, date);
  void insertGoalCategory(String name) => _database.insertGoalCategory(name);
  void updateAccountOpeningBalance(String id, int cents) =>
      _database.updateAccountOpeningBalance(id, cents);
  void updateAccountDetails({
    required String id,
    required String name,
    required AccountInstitution institution,
    String? customInstitutionName,
    String? customIconKey,
  }) =>
      _database.updateAccountDetails(
        id: id,
        name: name,
        institution: institution,
        customInstitutionName: customInstitutionName,
        customIconKey: customIconKey,
      );
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
  void deleteTask(String id) => _database.deleteTask(id);
  void insertShoppingItem(ShoppingItem item) =>
      _database.insertShoppingItem(item);
  void setShoppingItemPurchased(String id, bool value) =>
      _database.setShoppingItemPurchased(id, value);
  void setShoppingItemImage(String id, String? imagePath) =>
      _database.setShoppingItemImage(id, imagePath);
  void deleteShoppingItem(String id) => _database.deleteShoppingItem(id);
  void insertCreditCard(CreditCard item) => _database.insertCreditCard(item);
  void insertCardPurchase(CardPurchase item) =>
      _database.insertCardPurchase(item);
  void updateCreditCard(CreditCard item) => _database.updateCreditCard(item);
  void deleteCreditCard(String id) => _database.deleteCreditCard(id);
  void updateCardPurchase(CardPurchase item) =>
      _database.updateCardPurchase(item);
  void deleteCardPurchase(String id) => _database.deleteCardPurchase(id);
  void clearUnpaidInvoiceItems() => _database.clearUnpaidInvoiceItems();
  void deleteEmptyUnpaidInvoices() => _database.deleteEmptyUnpaidInvoices();
  void closeExpiredCardInvoices(DateTime today) =>
      _database.closeExpiredCardInvoices(today);
  String ensureCardInvoice({
    required String id,
    required String cardId,
    required DateTime cycleStart,
    required DateTime closingDate,
    required DateTime dueDate,
    required CardInvoiceStatus status,
    required DateTime createdAt,
  }) =>
      _database.ensureCardInvoice(
        id: id,
        cardId: cardId,
        cycleStart: cycleStart,
        closingDate: closingDate,
        dueDate: dueDate,
        status: status,
        createdAt: createdAt,
      );
  void insertCardInvoiceItem({
    required String id,
    required String invoiceId,
    required String purchaseId,
    required int installmentNumber,
    required int amountInCents,
  }) =>
      _database.insertCardInvoiceItem(
        id: id,
        invoiceId: invoiceId,
        purchaseId: purchaseId,
        installmentNumber: installmentNumber,
        amountInCents: amountInCents,
      );
  bool hasCardInvoiceItem(String purchaseId, int installmentNumber) =>
      _database.hasCardInvoiceItem(purchaseId, installmentNumber);
  void markCardInvoicePaid({
    required String id,
    required String invoiceId,
    required String transactionId,
    required DateTime paidOn,
    required int amountInCents,
  }) =>
      _database.markCardInvoicePaid(
          id: id,
          invoiceId: invoiceId,
          transactionId: transactionId,
          paidOn: paidOn,
          amountInCents: amountInCents);
  void reverseCardInvoicePayment(String invoiceId) =>
      _database.reverseCardInvoicePayment(invoiceId);
  void assertCardPurchaseHasNoPaidInvoice(String id) =>
      _database.assertCardPurchaseHasNoPaidInvoice(id);
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
  void insertFinanceSubcategory(FinanceSubcategory item) =>
      _database.insertFinanceSubcategory(item);
  void setTransactionSettled(String id, bool value) =>
      _database.setTransactionSettled(id, value);
  void updateFinancialGoalSaved(String id, int savedInCents) =>
      _database.updateFinancialGoalSaved(id, savedInCents);
  void deleteAccount(String id) => _database.deleteAccount(id);
  void deleteTransaction(String id) => _database.deleteTransaction(id);
  void updateTransactionDetails(String id, int cents, String description) =>
      _database.updateTransactionDetails(id, cents, description);
  void updateTransactionRecord(TransactionRecord item) =>
      _database.updateTransactionRecord(item);
  void deleteTransactionRows(Iterable<String> ids) =>
      _database.deleteTransactionRows(ids);
  void deleteBudget(String id) => _database.deleteBudget(id);
  void deleteSubscription(String id) => _database.deleteSubscription(id);
  void deleteFinancialGoal(String id) => _database.deleteFinancialGoal(id);
  void deleteInvestment(String id) => _database.deleteInvestment(id);
  void saveSalaryAllocation(SalaryAllocation item) =>
      _database.saveSalaryAllocation(item);
  void transaction(void Function() operation) =>
      _database.transaction(operation);
  void close() => _database.close();
}

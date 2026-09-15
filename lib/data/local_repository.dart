import '../database/app_database.dart';
import '../domain/models.dart';

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
  List<InvestmentPosition> loadInvestments() => _database.loadInvestments();
  List<Budget> loadBudgets() => _database.loadBudgets();
  List<Subscription> loadSubscriptions() => _database.loadSubscriptions();
  SalaryAllocation loadSalaryAllocation() => _database.loadSalaryAllocation();
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
  void deleteShoppingItem(String id) => _database.deleteShoppingItem(id);
  void insertCreditCard(CreditCard item) => _database.insertCreditCard(item);
  void insertCardPurchase(CardPurchase item) =>
      _database.insertCardPurchase(item);
  void insertInvestment(InvestmentPosition item) =>
      _database.insertInvestment(item);
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
  void deleteBudget(String id) => _database.deleteBudget(id);
  void deleteSubscription(String id) => _database.deleteSubscription(id);
  void deleteFinancialGoal(String id) => _database.deleteFinancialGoal(id);
  void deleteInvestment(String id) => _database.deleteInvestment(id);
  void saveSalaryAllocation(SalaryAllocation item) =>
      _database.saveSalaryAllocation(item);
  void close() => _database.close();
}

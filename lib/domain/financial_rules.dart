import 'models.dart';

/// Financial amounts are integer cents to avoid binary floating-point errors.
class FinancialRules {
  const FinancialRules._();

  static int accountBalance(
      Account account, Iterable<TransactionRecord> items) {
    var balance = account.openingBalanceInCents;
    for (final item in items) {
      if (!item.isSettled) continue;
      if (item.accountId == account.id) {
        switch (item.type) {
          case TransactionType.income:
            balance += item.amountInCents;
          case TransactionType.expense:
            balance -= item.amountInCents;
          case TransactionType.transfer:
            balance -= item.amountInCents;
        }
      }
      if (item.type == TransactionType.transfer &&
          item.destinationAccountId == account.id) {
        balance += item.amountInCents;
      }
    }
    return balance;
  }

  static int currentBalance(
    Iterable<Account> accounts,
    Iterable<TransactionRecord> transactions,
  ) =>
      accounts.fold(
        0,
        (total, account) => total + accountBalance(account, transactions),
      );

  /// Groups included account balances by currency. Values in different
  /// currencies are intentionally never combined or converted.
  static Map<String, int> accountBalancesByCurrencyForNetWorth(
    Iterable<Account> accounts,
    Iterable<TransactionRecord> transactions,
  ) {
    final items = transactions.toList(growable: false);
    final totals = <String, int>{};
    for (final account in accounts) {
      if (!account.includeInNetWorth) continue;
      totals.update(
        account.currency,
        (balance) => balance + accountBalance(account, items),
        ifAbsent: () => accountBalance(account, items),
      );
    }
    return Map.unmodifiable(totals);
  }

  static int monthTotal(
    Iterable<TransactionRecord> items,
    DateTime month,
    TransactionType type,
  ) =>
      items
          .where((item) =>
              item.type == type &&
              item.systemType == null &&
              item.isSettled &&
              item.occurredOn.year == month.year &&
              item.occurredOn.month == month.month)
          .fold(0, (total, item) => total + item.amountInCents);

  /// Settled cash leaving owned accounts, including system card payments.
  /// Category expense reporting must use [monthTotal] and card purchases.
  static int settledCashOutflowTotal(Iterable<TransactionRecord> items) => items
      .where((item) => item.type == TransactionType.expense && item.isSettled)
      .fold(0, (total, item) => total + item.amountInCents);

  static bool isValidAmount(int cents) => cents > 0 && cents < 100000000000;

  static int budgetSpent(Budget budget, List<TransactionRecord> transactions,
      [Iterable<CardPurchase> cardPurchases = const []]) {
    final accountExpenses = transactions
        .where((item) =>
            item.type == TransactionType.expense &&
            item.systemType == null &&
            item.isSettled &&
            (budget.categoryId != null && item.categoryId != null
                ? item.categoryId == budget.categoryId
                : item.category.toLowerCase() ==
                    budget.category.toLowerCase()) &&
            item.occurredOn.year == budget.year &&
            item.occurredOn.month == budget.month)
        .fold(0, (sum, item) => sum + item.amountInCents);
    final cardExpenses = cardPurchases
        .where((item) =>
            (budget.categoryId != null && item.categoryId != null
                ? item.categoryId == budget.categoryId
                : item.category.toLowerCase() ==
                    budget.category.toLowerCase()) &&
            item.purchasedOn.year == budget.year &&
            item.purchasedOn.month == budget.month)
        .fold(0, (sum, item) => sum + item.amountInCents);
    return accountExpenses + cardExpenses;
  }

  static double budgetProgress(
      Budget budget, List<TransactionRecord> transactions,
      [Iterable<CardPurchase> cardPurchases = const []]) {
    if (budget.limitInCents <= 0) return 0;
    return (budgetSpent(budget, transactions, cardPurchases) /
            budget.limitInCents)
        .clamp(0, 1);
  }

  static int cardPurchaseTotal(
          Iterable<CardPurchase> purchases, DateTime month) =>
      purchases
          .where((item) =>
              item.purchasedOn.year == month.year &&
              item.purchasedOn.month == month.month)
          .fold(0, (sum, item) => sum + item.amountInCents);

  static String formatBrl(int cents, {bool signed = false}) {
    final prefix = signed ? (cents < 0 ? '-' : '+') : (cents < 0 ? '-' : '');
    final absolute = cents.abs();
    final rawReais = (absolute ~/ 100).toString();
    final groupedReais = rawReais.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final centavos = (absolute % 100).toString().padLeft(2, '0');
    return '${prefix}R\$ $groupedReais,$centavos';
  }
}

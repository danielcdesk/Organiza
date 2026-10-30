import 'dart:math';

import 'package:clock/clock.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

/// Reproducible synthetic data for volume tests; never uses the device clock.
class SeedGenerator {
  SeedGenerator({this.seed = 42, Clock? clock})
      : clock = clock ?? Clock.fixed(DateTime.utc(2026, 1, 15, 12));

  final int seed;
  final Clock clock;

  SeedData generate({
    int accountCount = 5,
    int transactionCount = 10000,
    int recurringSeriesCount = 4,
    int installmentSeriesCount = 4,
    int cardCount = 3,
    int cardPurchaseCount = 24,
  }) {
    const seriesLength = 12;
    if (accountCount < 1 ||
        transactionCount < 0 ||
        recurringSeriesCount < 0 ||
        installmentSeriesCount < 0 ||
        cardCount < 0 ||
        cardPurchaseCount < 0) {
      throw ArgumentError('As contagens devem ser válidas e deve haver conta.');
    }
    final seriesCount = recurringSeriesCount + installmentSeriesCount;
    if (transactionCount < seriesCount * seriesLength) {
      throw ArgumentError(
          'A quantidade de transações deve comportar as séries.');
    }
    if (cardPurchaseCount > 0 && cardCount == 0) {
      throw ArgumentError('Compras exigem ao menos um cartão.');
    }

    // Restart the sequence on every generation, including repeated calls on the
    // same instance. A fixed clock also makes dates and snapshots reproducible.
    final random = Random(seed);
    final now = clock.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final prefix = 'seed-$seed';
    final accounts = List.generate(
      accountCount,
      (index) => Account(
        id: '$prefix-account-$index',
        name: 'Conta de teste ${index + 1}',
        openingBalanceInCents: 100000 + random.nextInt(900000),
        createdAt: now,
      ),
    );
    final transactions = <TransactionRecord>[];
    for (var seriesIndex = 0; seriesIndex < seriesCount; seriesIndex++) {
      final recurring = seriesIndex < recurringSeriesCount;
      final totalInCents = 12001 + random.nextInt(120000);
      final account = accounts[seriesIndex % accountCount];
      for (var occurrence = 0; occurrence < seriesLength; occurrence++) {
        final month = DateTime.utc(today.year, today.month - 6 + occurrence);
        final lastDay = DateTime.utc(month.year, month.month + 1, 0).day;
        final dueOn = DateTime.utc(
          month.year,
          month.month,
          min(today.day, lastDay),
        );
        transactions.add(TransactionRecord(
          id: '$prefix-transaction-${transactions.length}',
          accountId: account.id,
          type: recurring ? TransactionType.income : TransactionType.expense,
          amountInCents: recurring
              ? totalInCents
              : totalInCents ~/ seriesLength +
                  (occurrence < totalInCents % seriesLength ? 1 : 0),
          description: recurring
              ? 'Receita recorrente ${seriesIndex + 1}'
              : 'Compra parcelada ${seriesIndex + 1}',
          category: recurring ? 'Salário' : 'Outros',
          occurredOn: dueOn,
          createdAt: now,
          scheduleType: recurring
              ? TransactionScheduleType.recurring
              : TransactionScheduleType.installment,
          seriesId: '$prefix-series-$seriesIndex',
          installmentNumber: occurrence + 1,
          installmentCount: seriesLength,
          isSettled: !dueOn.isAfter(today),
        ));
      }
    }
    while (transactions.length < transactionCount) {
      final index = transactions.length;
      var type = TransactionType.values[index % TransactionType.values.length];
      if (type == TransactionType.transfer && accountCount == 1) {
        type = TransactionType.expense;
      }
      final accountIndex = random.nextInt(accountCount);
      final dueOn = today.add(Duration(days: random.nextInt(3831) - 3650));
      transactions.add(TransactionRecord(
        id: '$prefix-transaction-$index',
        accountId: accounts[accountIndex].id,
        destinationAccountId: type == TransactionType.transfer
            ? accounts[(accountIndex + 1) % accountCount].id
            : null,
        type: type,
        amountInCents: 1 + random.nextInt(1000000),
        description: 'Lançamento de teste ${index + 1}',
        category: switch (type) {
          TransactionType.income => 'Salário',
          TransactionType.expense => 'Alimentação',
          TransactionType.transfer => 'Transferência',
        },
        occurredOn: dueOn,
        createdAt: now,
        isSettled: !dueOn.isAfter(today),
      ));
    }
    final cards = List.generate(
      cardCount,
      (index) => CreditCard(
        id: '$prefix-card-$index',
        name: 'Cartão de teste ${index + 1}',
        brand: CardBrand.values[index % CardBrand.values.length],
        lastFour: (index % 10000).toString().padLeft(4, '0'),
        limitInCents: 2000000 + random.nextInt(3000000),
        closingDay: 1 + index % 28,
        dueDay: 1 + (index + 7) % 28,
        colorValue: 0xFF245943,
        createdAt: now,
      ),
    );
    final purchases = List.generate(
      cardPurchaseCount,
      (index) => CardPurchase(
        id: '$prefix-purchase-$index',
        cardId: cards[index % cardCount].id,
        description: 'Compra no cartão ${index + 1}',
        amountInCents: 10001 + random.nextInt(500000),
        purchasedOn: today.subtract(Duration(days: random.nextInt(730))),
        installments: 2 + index % 47,
        createdAt: now,
      ),
    );
    return SeedData._(
      accounts: accounts,
      transactions: transactions,
      creditCards: cards,
      cardPurchases: purchases,
    );
  }
}

class SeedData {
  SeedData._({
    required List<Account> accounts,
    required List<TransactionRecord> transactions,
    required List<CreditCard> creditCards,
    required List<CardPurchase> cardPurchases,
  })  : accounts = List.unmodifiable(accounts),
        transactions = List.unmodifiable(transactions),
        creditCards = List.unmodifiable(creditCards),
        cardPurchases = List.unmodifiable(cardPurchases);

  final List<Account> accounts;
  final List<TransactionRecord> transactions;
  final List<CreditCard> creditCards;
  final List<CardPurchase> cardPurchases;

  /// Inserts the complete fixture atomically, respecting foreign key order.
  void insertInto(AppDatabase database) {
    database.transaction(() {
      for (final account in accounts) {
        database.insertAccount(account);
      }
      for (final card in creditCards) {
        database.insertCreditCard(card);
      }
      // Prepare stable category IDs before the repository resolves transaction
      // names. Otherwise newly created subcategories get random UUIDs and two
      // fixtures generated with the same seed have different snapshots.
      if (database.schemaVersion >= 17) {
        final categories = database.loadFinanceCategories();
        final subcategories = database.loadFinanceSubcategories();
        var nextCategory = 0;
        var nextSubcategory = 0;
        for (final item in transactions) {
          if (item.type == TransactionType.transfer) continue;
          var category = categories
              .where((entry) =>
                  entry.type == item.type && entry.name == item.category)
              .firstOrNull;
          if (category == null) {
            category = FinanceCategory(
              id: 'fixture-category-${nextCategory++}',
              name: item.category,
              type: item.type,
              isSystem: false,
              createdAt: item.createdAt,
            );
            database.insertFinanceCategory(category);
            categories.add(category);
          }
          if (subcategories.any((entry) =>
              entry.categoryId == category!.id &&
              entry.name == item.subcategory)) {
            continue;
          }
          final subcategory = FinanceSubcategory(
            id: 'fixture-subcategory-${nextSubcategory++}',
            categoryId: category.id,
            name: item.subcategory,
            isSystem: false,
            createdAt: item.createdAt,
          );
          database.insertFinanceSubcategory(subcategory);
          subcategories.add(subcategory);
        }
      }
      for (final transaction in transactions) {
        database.insertTransaction(transaction);
      }
      for (final purchase in cardPurchases) {
        database.insertCardPurchase(purchase);
      }
    });
  }
}

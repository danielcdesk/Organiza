import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

import '../../support/seed_generator.dart';

void main() {
  final fixedNow = DateTime.utc(2024, 1, 31, 12);

  SeedGenerator generator({int seed = 42}) =>
      SeedGenerator(seed: seed, clock: Clock.fixed(fixedNow));

  test('gera dez mil transações e conjuntos completos para testes de volume',
      () {
    final data = generator().generate();

    expect(data.accounts, hasLength(5));
    expect(data.transactions, hasLength(10000));
    expect(data.creditCards, hasLength(3));
    expect(data.cardPurchases, hasLength(24));
    expect(data.transactions.map((item) => item.type).toSet(),
        TransactionType.values.toSet());
    expect(data.transactions.map((item) => item.scheduleType).toSet(),
        TransactionScheduleType.values.toSet());
    expect(data.cardPurchases.every((item) => item.installments > 1), isTrue);
    expect(data.transactions.any((item) => !item.isSettled), isTrue);
    expect(data.transactions.any((item) => item.isSettled), isTrue);
    expect(
        data.transactions.every((item) => item.createdAt == fixedNow), isTrue);
  });

  test('mesma semente e relógio produzem o mesmo banco, sem depender da ordem',
      () {
    final first = AppDatabase.openInMemory();
    final second = AppDatabase.openInMemory();
    addTearDown(first.close);
    addTearDown(second.close);
    final shared = generator();

    shared.generate().insertInto(first);
    shared.generate().insertInto(second);

    expect(first.loadTransactions(), hasLength(10000));
    expect(jsonEncode(first.exportSnapshot()),
        jsonEncode(second.exportSnapshot()));
    expect(first.loadCardPurchases(), hasLength(24));
  });

  test('escala a cinquenta mil ocorrências sem referências inválidas', () {
    final data = generator(seed: 7).generate(
      accountCount: 7,
      transactionCount: 50000,
      recurringSeriesCount: 2,
      installmentSeriesCount: 3,
      cardCount: 2,
      cardPurchaseCount: 10,
    );
    final accountIds = data.accounts.map((item) => item.id).toSet();
    final cardIds = data.creditCards.map((item) => item.id).toSet();

    expect(accountIds, hasLength(7));
    expect(data.transactions, hasLength(50000));
    expect(data.transactions.map((item) => item.id).toSet(), hasLength(50000));
    expect(data.cardPurchases, hasLength(10));
    for (final item in data.transactions) {
      expect(accountIds, contains(item.accountId));
      expect(item.amountInCents, greaterThan(0));
      expect(item.occurredOn.isUtc, isTrue);
      expect(item.occurredOn.hour, 0);
      expect(
          item.isSettled, !item.occurredOn.isAfter(DateTime.utc(2024, 1, 31)));
      if (item.type == TransactionType.transfer) {
        expect(accountIds, contains(item.destinationAccountId));
        expect(item.destinationAccountId, isNot(item.accountId));
      } else {
        expect(item.destinationAccountId, isNull);
      }
    }
    for (final purchase in data.cardPurchases) {
      expect(cardIds, contains(purchase.cardId));
      expect(purchase.amountInCents, greaterThan(0));
      expect(purchase.installments, inInclusiveRange(2, 48));
    }
  });

  test('séries preservam sequência mensal, vencimento e centavos das parcelas',
      () {
    final data = generator().generate();
    final series = <String, List<TransactionRecord>>{};
    for (final item
        in data.transactions.where((item) => item.seriesId != null)) {
      series.putIfAbsent(item.seriesId!, () => []).add(item);
    }

    expect(series, hasLength(8));
    for (final occurrences in series.values) {
      expect(occurrences, hasLength(12));
      expect(occurrences.map((item) => item.installmentNumber),
          orderedEquals(List.generate(12, (index) => index + 1)));
      expect(occurrences.map((item) => item.accountId).toSet(), hasLength(1));
      expect(occurrences.every((item) => item.installmentCount == 12), isTrue);
      expect(occurrences[6].occurredOn, DateTime.utc(2024, 1, 31));
      expect(occurrences[7].occurredOn, DateTime.utc(2024, 2, 29));
      expect(occurrences[8].occurredOn, DateTime.utc(2024, 3, 31));
      final amounts = occurrences.map((item) => item.amountInCents).toList()
        ..sort();
      if (occurrences.first.scheduleType == TransactionScheduleType.recurring) {
        expect(amounts.toSet(), hasLength(1));
      } else {
        expect(amounts.last - amounts.first, lessThanOrEqualTo(1));
      }
    }
  });

  test('uma única conta dispensa transferências e permite massa mínima', () {
    final data = generator().generate(
      accountCount: 1,
      transactionCount: 2,
      recurringSeriesCount: 0,
      installmentSeriesCount: 0,
      cardCount: 0,
      cardPurchaseCount: 0,
    );

    expect(data.transactions, hasLength(2));
    expect(
        data.transactions.any((item) => item.type == TransactionType.transfer),
        isFalse);
    expect(data.cardPurchases, isEmpty);
    expect(() => data.accounts.clear(), throwsUnsupportedError);
  });

  test('rejeita contagens impossíveis antes de gerar dados', () {
    expect(() => generator().generate(accountCount: 0), throwsArgumentError);
    expect(
        () => generator().generate(transactionCount: -1), throwsArgumentError);
    expect(() => generator().generate(recurringSeriesCount: -1),
        throwsArgumentError);
    expect(() => generator().generate(installmentSeriesCount: -1),
        throwsArgumentError);
    expect(
        () => generator().generate(transactionCount: 95), throwsArgumentError);
    expect(() => generator().generate(cardCount: -1), throwsArgumentError);
    expect(
        () => generator().generate(cardPurchaseCount: -1), throwsArgumentError);
    expect(() => generator().generate(cardCount: 0), throwsArgumentError);
  });
}

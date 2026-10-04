import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/balance_projection.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final today = DateTime(2026, 1, 1);
  final fixedClock = Clock.fixed(today);

  Account account(String id, int opening) => Account(
        id: id,
        name: id,
        openingBalanceInCents: opening,
        createdAt: today,
      );

  TransactionRecord transaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required int amount,
    required DateTime date,
    bool settled = false,
    String? destinationAccountId,
    TransactionScheduleType scheduleType = TransactionScheduleType.single,
    String? seriesId,
    int installmentNumber = 1,
    int installmentCount = 1,
    String category = 'Outros',
  }) =>
      TransactionRecord(
        id: id,
        accountId: accountId,
        destinationAccountId: destinationAccountId,
        type: type,
        amountInCents: amount,
        description: id,
        occurredOn: date,
        createdAt: today,
        category: category,
        scheduleType: scheduleType,
        seriesId: seriesId,
        installmentNumber: installmentNumber,
        installmentCount: installmentCount,
        isSettled: settled,
      );

  test('sem pendências, a linha permanece constante', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 10000)],
      transactions: [
        transaction(
          id: 'settled',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 2500,
          date: DateTime(2025, 12, 20),
          settled: true,
        ),
      ],
      salaries: const [],
      clock: fixedClock,
      horizonDays: 30,
    );

    expect(result.points, hasLength(30));
    expect(result.points.map((point) => point.balanceInCents).toSet(), {7500});
    expect(result.firstNegativeDate, isNull);
  });

  test('despesa grande no dia 10 marca o primeiro dia negativo', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 10000)],
      transactions: [
        transaction(
          id: 'large-expense',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 12000,
          date: DateTime(2026, 1, 10),
        ),
      ],
      salaries: const [],
      clock: fixedClock,
      horizonDays: 30,
    );

    expect(result.firstNegativeDate, DateTime(2026, 1, 10));
    expect(result.firstNegativeBalanceInCents, -2000);
  });

  test('transferência não altera o consolidado, mas altera as contas', () {
    final result = BalanceProjection.calculate(
      accounts: [account('origin', 10000), account('destination', 0)],
      transactions: [
        transaction(
          id: 'transfer',
          accountId: 'origin',
          destinationAccountId: 'destination',
          type: TransactionType.transfer,
          amount: 4000,
          date: DateTime(2026, 1, 2),
        ),
      ],
      salaries: const [],
      clock: fixedClock,
      horizonDays: 5,
    );

    final point = result.points[1];
    expect(point.balanceInCents, 10000);
    expect(point.accountBalancesInCents['origin'], 6000);
    expect(point.accountBalancesInCents['destination'], 4000);
  });

  test('salário recorrente no dia 31 cai no último dia de fevereiro', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 0)],
      transactions: const [],
      salaries: [
        SalarySchedule(
          id: 'salary',
          accountId: 'main',
          amountInCents: 10000,
          description: 'Salário',
          subcategory: 'Mensal',
          firstDueOn: DateTime(2026, 1, 31),
          paymentDay: 31,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      clock: Clock.fixed(DateTime(2026, 1, 15)),
      horizonDays: 60,
    );

    final february = result.points
        .firstWhere((point) => point.date == DateTime(2026, 2, 28));
    expect(february.balanceInCents, 20000);
  });

  test('recorrência no dia 31 gera ocorrência no último dia de fevereiro', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 0)],
      transactions: [
        transaction(
          id: 'recurring-january',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 500,
          date: DateTime(2026, 1, 31),
          scheduleType: TransactionScheduleType.recurring,
          seriesId: 'recurring-series',
          installmentCount: 2,
        ),
      ],
      salaries: const [],
      clock: Clock.fixed(DateTime(2026, 1, 15)),
      horizonDays: 60,
    );

    final february = result.points
        .firstWhere((point) => point.date == DateTime(2026, 2, 28));
    expect(february.balanceInCents, -1000);
  });

  test('parcelas futuras são somadas uma vez por ocorrência', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 0)],
      transactions: [
        transaction(
          id: 'installment-1',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 300,
          date: DateTime(2026, 1, 10),
          scheduleType: TransactionScheduleType.installment,
          seriesId: 'series',
          installmentNumber: 1,
          installmentCount: 3,
        ),
        transaction(
          id: 'installment-2',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 300,
          date: DateTime(2026, 2, 10),
          scheduleType: TransactionScheduleType.installment,
          seriesId: 'series',
          installmentNumber: 2,
          installmentCount: 3,
        ),
        transaction(
          id: 'installment-3',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 400,
          date: DateTime(2026, 3, 10),
          scheduleType: TransactionScheduleType.installment,
          seriesId: 'series',
          installmentNumber: 3,
          installmentCount: 3,
        ),
      ],
      salaries: const [],
      clock: fixedClock,
      horizonDays: 90,
    );

    final march = result.points
        .firstWhere((point) => point.date == DateTime(2026, 3, 10));
    expect(march.balanceInCents, -1000);
  });

  test('pode gastar por dia usa o menor saldo até o próximo salário', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 10000)],
      transactions: [
        transaction(
          id: 'expense',
          accountId: 'main',
          type: TransactionType.expense,
          amount: 2000,
          date: DateTime(2026, 1, 6),
        ),
      ],
      salaries: [
        SalarySchedule(
          id: 'salary',
          accountId: 'main',
          amountInCents: 10000,
          description: 'Salário',
          subcategory: 'Mensal',
          firstDueOn: DateTime(2026, 1, 11),
          paymentDay: 11,
          createdAt: today,
        ),
      ],
      clock: fixedClock,
      horizonDays: 30,
    );

    expect(result.canSpendPerDayInCents, 800);
  });
}

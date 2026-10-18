import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/balance_projection.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('projeção inclui obrigação ativa e ignora pausada', () {
    final today = DateTime.utc(2026, 9, 10);
    final obligation = RecurringObligation(id: 'r', name: 'Energia',
      category: 'Moradia', accountId: 'a', estimatedAmountInCents: 12000,
      billingDay: 11, nextDueOn: DateTime.utc(2026, 9, 11),
      isActive: true, createdAt: today);
    BalanceProjectionResult projected(RecurringObligation item) =>
        BalanceProjection.calculate(
          accounts: [Account(id: 'a', name: 'Conta',
              openingBalanceInCents: 100000, createdAt: today)],
          transactions: const [], salaries: const [],
          recurringObligations: [item],
          clock: Clock.fixed(today), horizonDays: 3);
    expect(projected(obligation).points[1].balanceInCents, 88000);
    expect(projected(RecurringObligation(id: obligation.id,
      name: obligation.name, category: obligation.category,
      accountId: obligation.accountId,
      estimatedAmountInCents: obligation.estimatedAmountInCents,
      billingDay: obligation.billingDay, nextDueOn: obligation.nextDueOn,
      isActive: false, createdAt: today)).points[1].balanceInCents, 100000);
  });
  test('projeção inclui próxima parcela de dívida sem lançá-la no histórico', () {
    final today = DateTime.utc(2026, 9, 10);
    final result = BalanceProjection.calculate(
      accounts: [Account(id: 'a', name: 'Conta', openingBalanceInCents: 200000,
          createdAt: today)],
      transactions: const [], salaries: const [],
      debts: [Debt(id: 'd', name: 'Empréstimo',
        originalPrincipalInCents: 100000, outstandingPrincipalInCents: 100000,
        monthlyInterestBasisPoints: 100, installmentAmountInCents: 10000,
        firstDueOn: DateTime.utc(2026, 9, 11), installmentsRemaining: 12,
        accountId: 'a', category: 'Empréstimos', isActive: true,
        createdAt: today)],
      clock: Clock.fixed(today), horizonDays: 3,
    );
    expect(result.points[0].balanceInCents, 200000);
    expect(result.points[1].balanceInCents, 190000);
  });
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

  test('fatura fechada não paga reduz o consolidado no vencimento', () {
    final result = BalanceProjection.calculate(
      accounts: [account('main', 10000)],
      transactions: const [],
      salaries: const [],
      clock: fixedClock,
      cardInvoices: [
        CardInvoice(
          id: 'invoice',
          cardId: 'card',
          cycleStart: DateTime(2025, 12, 1),
          closingDate: DateTime(2025, 12, 31),
          dueDate: DateTime(2026, 1, 5),
          status: CardInvoiceStatus.closed,
          totalInCents: 2500,
        )
      ],
      horizonDays: 10,
    );
    expect(result.points[3].balanceInCents, 10000);
    expect(result.points[4].balanceInCents, 7500);
    expect(result.points[4].accountBalancesInCents['main'], 10000);
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

    expect(result.firstNegativeDate, DateTime.utc(2026, 1, 10));
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
        .firstWhere((point) => point.date == DateTime.utc(2026, 2, 28));
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
        .firstWhere((point) => point.date == DateTime.utc(2026, 2, 28));
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
        .firstWhere((point) => point.date == DateTime.utc(2026, 3, 10));
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

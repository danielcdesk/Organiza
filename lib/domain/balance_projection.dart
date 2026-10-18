import 'package:clock/clock.dart';

import 'models.dart';
import 'business_date.dart';
import 'debt_rules.dart';
import 'recurring_obligation_rules.dart';

/// A daily consolidated balance, with the corresponding per-account balances.
class BalanceProjectionPoint {
  const BalanceProjectionPoint({
    required this.date,
    required this.balanceInCents,
    required this.accountBalancesInCents,
  });

  final DateTime date;
  final int balanceInCents;
  final Map<String, int> accountBalancesInCents;
}

class BalanceProjectionResult {
  const BalanceProjectionResult({
    required this.points,
    required this.firstNegativeDate,
    required this.firstNegativeBalanceInCents,
    required this.nextSalaryDate,
    required this.canSpendPerDayInCents,
  });

  final List<BalanceProjectionPoint> points;
  final DateTime? firstNegativeDate;
  final int? firstNegativeBalanceInCents;
  final DateTime? nextSalaryDate;
  final int canSpendPerDayInCents;
}

/// Pure projection of future cash flow from the current, confirmed balance.
///
/// Confirmed transactions are already part of the starting balance and are
/// therefore not applied again. Pending overdue transactions are projected on
/// today. Recurring and installment transactions are expanded only when an
/// occurrence is missing from the supplied records; this keeps the rule
/// compatible with the store, which normally materializes every occurrence.
class BalanceProjection {
  const BalanceProjection._();

  static BalanceProjectionResult calculate({
    required Iterable<Account> accounts,
    required Iterable<TransactionRecord> transactions,
    required Iterable<SalarySchedule> salaries,
    required Clock clock,
    Iterable<CardInvoice> cardInvoices = const <CardInvoice>[],
    Iterable<Debt> debts = const <Debt>[],
    Iterable<DebtPayment> debtPayments = const <DebtPayment>[],
    Iterable<RecurringObligation> recurringObligations =
        const <RecurringObligation>[],
    int horizonDays = 90,
  }) {
    if (horizonDays < 1) {
      throw ArgumentError.value(horizonDays, 'horizonDays', 'must be positive');
    }

    final today = _dateOnly(clock.now());
    final lastDay =
        DateTime.utc(today.year, today.month, today.day + horizonDays - 1);
    final accountList = accounts.toList(growable: false);
    final transactionList = transactions.toList(growable: false);
    final balances = <String, int>{
      for (final account in accountList)
        account.id: _confirmedAccountBalance(account, transactionList),
    };
    final events = <_ProjectionEvent>[];

    for (final item in transactionList) {
      if (item.isSettled) continue;
      _addTransactionEvent(
        events,
        item,
        today: today,
        lastDay: lastDay,
      );
    }

    _addMissingSeriesOccurrences(
      events,
      transactionList,
      today: today,
      lastDay: lastDay,
    );

    final salaryDates = <DateTime>[];
    for (final item in transactionList) {
      if (_isSalary(item) && !item.isSettled) {
        final date = _effectiveDate(item.occurredOn, today);
        if (!date.isAfter(lastDay)) salaryDates.add(date);
      }
    }
    for (final schedule in salaries) {
      var month =
          DateTime.utc(schedule.firstDueOn.year, schedule.firstDueOn.month);
      while (!month.isAfter(lastDay)) {
        final due =
            _safeMonthlyDate(month.year, month.month, schedule.paymentDay);
        if (!due.isBefore(today) && !due.isAfter(lastDay)) {
          salaryDates.add(due);
          if (!_hasSalaryOccurrence(transactionList, schedule.id, due)) {
            _addEvent(
              events,
              _ProjectionEvent.income(
                date: due,
                accountId: schedule.accountId,
                amountInCents: schedule.amountInCents,
              ),
              accountIds: balances.keys,
            );
          }
        }
        month = DateTime.utc(month.year, month.month + 1);
      }
    }

    for (final debt in debts) {
      if (!debt.isActive || debt.outstandingPrincipalInCents <= 0) continue;
      final paidCount =
          debtPayments.where((item) => item.debtId == debt.id).length;
      var outstanding = debt.outstandingPrincipalInCents;
      for (var index = 0;
          index < debt.installmentsRemaining && outstanding > 0;
          index++) {
        final due = DebtRules.nextDueDate(debt.firstDueOn, paidCount + index);
        if (due.isAfter(lastDay)) break;
        final part = DebtRules.splitInstallment(
          outstandingPrincipalInCents: outstanding,
          installmentAmountInCents: debt.installmentAmountInCents,
          monthlyInterestBasisPoints: debt.monthlyInterestBasisPoints,
        );
        _addEvent(
            events,
            _ProjectionEvent(
              date: _effectiveDate(due, today),
              accountId: debt.accountId,
              type: TransactionType.expense,
              amountInCents: part.paymentInCents,
            ),
            accountIds: balances.keys);
        outstanding -= part.principalInCents;
      }
    }
    for (final obligation in recurringObligations) {
      if (!obligation.isActive) continue;
      for (var offset = 0; offset < 120; offset++) {
        final due = RecurringObligationRules.monthlyDue(obligation.nextDueOn,
            billingDay: obligation.billingDay, monthOffset: offset);
        if (due.isAfter(lastDay)) break;
        _addEvent(
            events,
            _ProjectionEvent(
              date: _effectiveDate(due, today),
              accountId: obligation.accountId,
              type: TransactionType.expense,
              amountInCents: obligation.estimatedAmountInCents,
            ),
            accountIds: balances.keys);
      }
    }

    final eventsByDate = <DateTime, List<_ProjectionEvent>>{};
    for (final event in events) {
      (eventsByDate[event.date] ??= []).add(event);
    }

    final obligationsByDate = <DateTime, int>{};
    for (final invoice in cardInvoices) {
      if (invoice.status != CardInvoiceStatus.closed ||
          invoice.totalInCents <= 0) {
        continue;
      }
      final date = _effectiveDate(invoice.dueDate, today);
      if (!date.isAfter(lastDay)) {
        obligationsByDate.update(
            date, (amount) => amount + invoice.totalInCents,
            ifAbsent: () => invoice.totalInCents);
      }
    }

    final points = <BalanceProjectionPoint>[];
    var unassignedCardOutflows = 0;
    DateTime? firstNegativeDate;
    int? firstNegativeBalance;
    for (var offset = 0; offset < horizonDays; offset++) {
      final date = DateTime.utc(today.year, today.month, today.day + offset);
      for (final event in eventsByDate[date] ?? const <_ProjectionEvent>[]) {
        _applyEvent(balances, event);
      }
      unassignedCardOutflows += obligationsByDate[date] ?? 0;
      final total = balances.values.fold<int>(0, (sum, value) => sum + value) -
          unassignedCardOutflows;
      final point = BalanceProjectionPoint(
        date: date,
        balanceInCents: total,
        accountBalancesInCents: Map.unmodifiable(balances),
      );
      points.add(point);
      if (firstNegativeDate == null && total < 0) {
        firstNegativeDate = date;
        firstNegativeBalance = total;
      }
    }

    salaryDates.sort();
    DateTime? nextSalaryDate;
    for (final date in salaryDates) {
      if (!date.isBefore(today)) {
        nextSalaryDate = date;
        break;
      }
    }
    final canSpendPerDay = _canSpendPerDay(
      points,
      today: today,
      nextSalaryDate: nextSalaryDate,
    );

    return BalanceProjectionResult(
      points: List.unmodifiable(points),
      firstNegativeDate: firstNegativeDate,
      firstNegativeBalanceInCents: firstNegativeBalance,
      nextSalaryDate: nextSalaryDate,
      canSpendPerDayInCents: canSpendPerDay,
    );
  }

  static int _confirmedAccountBalance(
    Account account,
    Iterable<TransactionRecord> transactions,
  ) {
    var balance = account.openingBalanceInCents;
    for (final item in transactions) {
      if (!item.isSettled) continue;
      if (item.accountId == account.id) {
        balance += switch (item.type) {
          TransactionType.income => item.amountInCents,
          TransactionType.expense => -item.amountInCents,
          TransactionType.transfer => -item.amountInCents,
        };
      }
      if (item.type == TransactionType.transfer &&
          item.destinationAccountId == account.id) {
        balance += item.amountInCents;
      }
    }
    return balance;
  }

  static void _addTransactionEvent(
    List<_ProjectionEvent> events,
    TransactionRecord item, {
    required DateTime today,
    required DateTime lastDay,
  }) {
    final date = _effectiveDate(item.occurredOn, today);
    if (date.isAfter(lastDay)) return;
    _addEvent(
      events,
      _ProjectionEvent.fromTransaction(item, date),
      accountIds: const <String>[],
      allowUnknownAccounts: true,
    );
  }

  static void _addMissingSeriesOccurrences(
    List<_ProjectionEvent> events,
    List<TransactionRecord> transactions, {
    required DateTime today,
    required DateTime lastDay,
  }) {
    final seeds = <String, TransactionRecord>{};
    for (final item in transactions) {
      if (item.scheduleType == TransactionScheduleType.single ||
          item.seriesId == null ||
          item.installmentCount < 2 ||
          _isSalary(item)) {
        continue;
      }
      final current = seeds[item.seriesId!];
      if (current == null || item.occurredOn.isBefore(current.occurredOn)) {
        seeds[item.seriesId!] = item;
      }
    }

    for (final entry in seeds.entries) {
      final seed = entry.value;
      for (var index = 0; index < seed.installmentCount; index++) {
        final date = _addMonths(seed.occurredOn, index);
        if (date.isBefore(today) || date.isAfter(lastDay)) continue;
        final exists = transactions.any((item) =>
            item.seriesId == entry.key && _dateOnly(item.occurredOn) == date);
        if (exists) continue;
        _addEvent(
          events,
          _ProjectionEvent.fromTransaction(seed, date),
          accountIds: const <String>[],
          allowUnknownAccounts: true,
        );
      }
    }
  }

  static void _addEvent(
    List<_ProjectionEvent> events,
    _ProjectionEvent event, {
    required Iterable<String> accountIds,
    bool allowUnknownAccounts = false,
  }) {
    if (allowUnknownAccounts ||
        accountIds.contains(event.accountId) ||
        (event.destinationAccountId != null &&
            accountIds.contains(event.destinationAccountId))) {
      events.add(event);
    }
  }

  static void _applyEvent(
    Map<String, int> balances,
    _ProjectionEvent event,
  ) {
    switch (event.type) {
      case TransactionType.income:
        if (balances.containsKey(event.accountId)) {
          balances[event.accountId] =
              balances[event.accountId]! + event.amountInCents;
        }
      case TransactionType.expense:
        if (balances.containsKey(event.accountId)) {
          balances[event.accountId] =
              balances[event.accountId]! - event.amountInCents;
        }
      case TransactionType.transfer:
        if (balances.containsKey(event.accountId)) {
          balances[event.accountId] =
              balances[event.accountId]! - event.amountInCents;
        }
        final destination = event.destinationAccountId;
        if (destination != null && balances.containsKey(destination)) {
          balances[destination] = balances[destination]! + event.amountInCents;
        }
    }
  }

  static int _canSpendPerDay(
    List<BalanceProjectionPoint> points, {
    required DateTime today,
    required DateTime? nextSalaryDate,
  }) {
    if (nextSalaryDate == null) return 0;
    final daysRemaining = nextSalaryDate.difference(today).inDays;
    if (daysRemaining <= 0) return 0;
    var minimum = points.first.balanceInCents;
    for (final point in points) {
      if (point.date.isBefore(nextSalaryDate) &&
          point.balanceInCents < minimum) {
        minimum = point.balanceInCents;
      }
    }
    return minimum <= 0 ? 0 : minimum ~/ daysRemaining;
  }

  static bool _hasSalaryOccurrence(
    Iterable<TransactionRecord> transactions,
    String scheduleId,
    DateTime date,
  ) =>
      transactions.any((item) =>
          item.seriesId == scheduleId && _dateOnly(item.occurredOn) == date);

  static bool _isSalary(TransactionRecord item) =>
      item.type == TransactionType.income &&
      item.category.trim().toLowerCase() == 'salário';

  static DateTime _effectiveDate(DateTime value, DateTime today) {
    final date = _dateOnly(value);
    return date.isBefore(today) ? today : date;
  }

  static DateTime _dateOnly(DateTime value) => BusinessDate.from(value);

  static DateTime _safeMonthlyDate(int year, int month, int day) {
    final last = DateTime.utc(year, month + 1, 0).day;
    return DateTime.utc(year, month, day.clamp(1, last));
  }

  static DateTime _addMonths(DateTime value, int months) {
    final normalized = DateTime.utc(value.year, value.month + months);
    return _safeMonthlyDate(normalized.year, normalized.month, value.day);
  }
}

class _ProjectionEvent {
  const _ProjectionEvent({
    required this.date,
    required this.accountId,
    required this.type,
    required this.amountInCents,
    this.destinationAccountId,
  });

  const _ProjectionEvent.income({
    required DateTime date,
    required String accountId,
    required int amountInCents,
  }) : this(
          date: date,
          accountId: accountId,
          type: TransactionType.income,
          amountInCents: amountInCents,
        );

  factory _ProjectionEvent.fromTransaction(
    TransactionRecord item,
    DateTime date,
  ) =>
      _ProjectionEvent(
        date: date,
        accountId: item.accountId,
        destinationAccountId: item.destinationAccountId,
        type: item.type,
        amountInCents: item.amountInCents,
      );

  final DateTime date;
  final String accountId;
  final String? destinationAccountId;
  final TransactionType type;
  final int amountInCents;
}

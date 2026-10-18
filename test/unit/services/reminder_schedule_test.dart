import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/services/notifications/reminder_schedule.dart';

void main() {
  test('schedules civil due dates using injected clock and hides money', () {
    withClock(Clock.fixed(DateTime.utc(2026, 2, 20, 23, 50)), () {
      final schedule = ReminderSchedule(clock: clock);
      final transaction = TransactionRecord(
        id: 'pending',
        accountId: 'account',
        type: TransactionType.expense,
        amountInCents: 1299,
        description: 'Conta de luz',
        occurredOn: DateTime(2026, 2, 22),
        createdAt: DateTime.utc(2026),
        isSettled: false,
      );
      final result = schedule.calculate(
        transactions: [transaction],
        invoices: const [],
        subscriptions: const [],
        daysAhead: 1,
        hour: 8,
        minute: 30,
        hideValues: true,
      );
      expect(result.single.date, DateTime(2026, 2, 21, 8, 30));
      expect(result.single.title, 'Lançamento pendente');
      expect(result.single.body, 'Conta de luz.');
      expect(result.single.body, isNot(contains('12,99')));
    });
  });

  test('handles month end and leap day subscription cycles', () {
    final schedule =
        ReminderSchedule(clock: Clock.fixed(DateTime.utc(2028, 2, 27)));
    final subscription = Subscription(
      id: 'sub',
      name: 'Streaming',
      amountInCents: 3990,
      billingDay: 31,
      category: 'Entretenimento',
      createdAt: DateTime.utc(2026),
    );
    final result = schedule.calculate(
      transactions: const [],
      invoices: const [],
      subscriptions: [subscription],
      daysAhead: 1,
      hour: 9,
      minute: 0,
      hideValues: false,
    );
    expect(result.single.date, DateTime(2028, 2, 28, 9));
    expect(result.single.body, contains('R\$ 39,90'));
  });
}

import 'package:clock/clock.dart';

import '../../domain/business_date.dart';
import '../../domain/models.dart';

enum ReminderKind { pending, invoice, subscription }

class LocalReminder {
  const LocalReminder({
    required this.kind,
    required this.id,
    required this.date,
    required this.title,
    required this.body,
  });

  final ReminderKind kind;
  final String id;
  final DateTime date;
  final String title;
  final String body;
}

/// Produces civil-date reminders. No timestamps or external services are used.
class ReminderSchedule {
  ReminderSchedule({Clock? clock}) : _clock = clock ?? const Clock();
  final Clock _clock;

  List<LocalReminder> calculate({
    required List<TransactionRecord> transactions,
    required List<CardInvoice> invoices,
    required List<Subscription> subscriptions,
    DateTime? today,
    required int daysAhead,
    required int hour,
    required int minute,
    required bool hideValues,
  }) {
    if (![0, 1, 3].contains(daysAhead) ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError('Preferências de lembrete inválidas.');
    }
    final businessToday = BusinessDate.from(today ?? _clock.now());
    final reminders = <LocalReminder>[];
    DateTime? reminderDate(DateTime due) {
      final dueDate = BusinessDate.from(due);
      final candidate = dueDate.subtract(Duration(days: daysAhead));
      if (candidate.isBefore(businessToday)) return null;
      return DateTime(
          candidate.year, candidate.month, candidate.day, hour, minute);
    }

    for (final item in transactions.where(
        (item) => !item.isSettled && item.type != TransactionType.transfer)) {
      final date = reminderDate(item.occurredOn);
      if (date == null) continue;
      final amount = hideValues ? '' : ' · ${_money(item.amountInCents)}';
      reminders.add(LocalReminder(
          kind: ReminderKind.pending,
          id: 'pending-${item.id}',
          date: date,
          title: 'Lançamento pendente',
          body:
              '${item.description.isEmpty ? 'Uma pendência vence' : item.description}$amount.'));
    }
    for (final invoice
        in invoices.where((item) => item.status == CardInvoiceStatus.closed)) {
      final date = reminderDate(invoice.dueDate);
      if (date == null) continue;
      reminders.add(LocalReminder(
          kind: ReminderKind.invoice,
          id: 'invoice-${invoice.id}',
          date: date,
          title: 'Fatura do cartão',
          body: hideValues
              ? 'Uma fatura vence em breve.'
              : 'Fatura de ${_money(invoice.totalInCents)} vence em breve.'));
    }
    for (final sub in subscriptions.where((item) => item.isActive)) {
      final due = _nextBillingDate(sub.billingDay, businessToday);
      final date = reminderDate(due);
      if (date == null) continue;
      reminders.add(LocalReminder(
          kind: ReminderKind.subscription,
          id: 'subscription-${sub.id}',
          date: date,
          title: 'Assinatura próxima',
          body: hideValues
              ? '${sub.name} vence em breve.'
              : '${sub.name} · ${_money(sub.amountInCents)} vence em breve.'));
    }
    return reminders;
  }

  static DateTime _nextBillingDate(int day, DateTime today) {
    DateTime inMonth(int year, int month) =>
        DateTime(year, month, day.clamp(1, DateTime(year, month + 1, 0).day));
    final current = inMonth(today.year, today.month);
    return current.isBefore(today)
        ? inMonth(today.year, today.month + 1)
        : current;
  }

  static String _money(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
}

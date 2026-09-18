import 'models.dart';

/// A projection of recorded transactions only. Transfers between owned
/// accounts never change the consolidated projection.
class CashFlowSummary {
  CashFlowSummary(Iterable<TransactionRecord> transactions, DateTime today) {
    final date = DateTime(today.year, today.month, today.day);
    final end = DateTime(today.year, today.month + 1);
    pending = transactions
        .where(
            (item) => !item.isSettled && item.type != TransactionType.transfer)
        .toList()
      ..sort((a, b) => a.occurredOn.compareTo(b.occurredOn));
    for (final item in pending) {
      if (item.occurredOn.isBefore(date)) overdueCount++;
      if (!item.occurredOn.isBefore(end)) continue;
      if (item.type == TransactionType.income) {
        receivable += item.amountInCents;
      } else {
        payable += item.amountInCents;
      }
    }
  }

  late final List<TransactionRecord> pending;
  int overdueCount = 0;
  int payable = 0;
  int receivable = 0;
  int projectedBalance(int currentBalance) =>
      currentBalance + receivable - payable;
}

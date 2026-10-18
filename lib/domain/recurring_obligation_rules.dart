abstract final class RecurringObligationRules {
  static DateTime monthlyDue(DateTime reference, {
    required int billingDay,
    required int monthOffset,
  }) {
    if (billingDay < 1 || billingDay > 31) {
      throw ArgumentError('Dia de cobrança inválido.');
    }
    final month = DateTime.utc(reference.year, reference.month + monthOffset);
    final lastDay = DateTime.utc(month.year, month.month + 1, 0).day;
    return DateTime.utc(month.year, month.month,
        billingDay.clamp(1, lastDay));
  }
}

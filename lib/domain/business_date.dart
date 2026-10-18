/// Calendar date used for financial/business rules. Its UTC representation is
/// only a stable carrier for the civil year/month/day; it is not an instant.
abstract final class BusinessDate {
  static DateTime from(DateTime value) => DateTime.utc(
        value.year,
        value.month,
        value.day,
      );

  static DateTime parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) {
      throw FormatException('Data de negócio inválida.', value);
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw FormatException('Data de negócio inválida.', value);
    }
    return parsed;
  }

  static String serialize(DateTime value) {
    final date = from(value);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime addMonths(DateTime value, int months) {
    final first = DateTime.utc(value.year, value.month + months);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    return DateTime.utc(first.year, first.month, value.day.clamp(1, lastDay));
  }
}

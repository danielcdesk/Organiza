import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/business_date.dart';

void main() {
  test('serializes a civil date independent of the source offset', () {
    expect(
        BusinessDate.serialize(BusinessDate.parse('2026-01-01T00:30:00-03:00')),
        '2026-01-01');
    expect(
        BusinessDate.serialize(BusinessDate.parse('2026-01-01T00:30:00+09:00')),
        '2026-01-01');
    expect(BusinessDate.parse('2026-01-01T23:59:00-03:00'),
        DateTime.utc(2026, 1, 1));
  });

  test('month arithmetic uses civil calendar and clamps month ends', () {
    expect(BusinessDate.addMonths(DateTime.utc(2024, 1, 31), 1),
        DateTime.utc(2024, 2, 29));
    expect(BusinessDate.addMonths(DateTime.utc(2025, 1, 31), 1),
        DateTime.utc(2025, 2, 28));
    expect(BusinessDate.addMonths(DateTime.utc(2025, 3, 31), 1),
        DateTime.utc(2025, 4, 30));
    expect(BusinessDate.addMonths(DateTime.utc(2025, 10, 31), 1),
        DateTime.utc(2025, 11, 30));
    expect(BusinessDate.addMonths(DateTime.utc(2025, 12, 31), 1),
        DateTime.utc(2026, 1, 31));
  });
}

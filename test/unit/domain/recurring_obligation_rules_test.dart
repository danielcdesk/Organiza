import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/recurring_obligation_rules.dart';

void main() {
  test('dia 31 é ajustado no fevereiro bissexto sem perder março', () {
    expect(
        RecurringObligationRules.monthlyDue(DateTime.utc(2028, 1, 31),
            billingDay: 31, monthOffset: 1),
        DateTime.utc(2028, 2, 29));
    expect(
        RecurringObligationRules.monthlyDue(DateTime.utc(2028, 1, 31),
            billingDay: 31, monthOffset: 2),
        DateTime.utc(2028, 3, 31));
  });
}

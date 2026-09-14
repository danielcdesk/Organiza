import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:organiza/domain/financial_rules.dart';

void main() {
  test('formatBrl formata centavos em R\$', () {
    expect(FinancialRules.formatBrl(1234), 'R\$ 12,34');
    expect(FinancialRules.formatBrl(0), 'R\$ 0,00');
    expect(FinancialRules.formatBrl(-500), '-R\$ 5,00');
    expect(FinancialRules.formatBrl(100, signed: true), '+R\$ 1,00');
    expect(FinancialRules.formatBrl(123456789), 'R\$ 1.234.567,89');
  });

  testWidgets('valor formatado renderiza na tela', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Text(FinancialRules.formatBrl(1234)))),
    );

    expect(find.text('R\$ 12,34'), findsOneWidget);
  });
}

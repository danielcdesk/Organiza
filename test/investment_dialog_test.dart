import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('edita valor atual e rentabilidade informada da poupança',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final position = InvestmentPosition(
      id: 'savings',
      name: 'Poupança',
      type: InvestmentType.fixedIncome,
      fixedIncomeType: FixedIncomeType.savings,
      investedAmountInCents: 100000,
      currentValueInCents: 100500,
      quotedRateBasisPoints: 50,
      quotedRatePeriod: InvestmentRatePeriod.monthly,
      createdAt: DateTime(2026, 9, 15),
    );
    InvestmentInput? saved;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () async {
                      saved = await showDialog<InvestmentInput>(
                        context: context,
                        builder: (_) => InvestmentDialog(position: position),
                      );
                    },
                    child: const Text('Editar'),
                  ))),
    ));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar investimento'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).at(3), '1.035,00');
    await tester.enterText(find.byType(TextField).at(4), '0,75');
    await tester.enterText(find.byType(TextField).at(5), '10');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.currentValueInCents, 103500);
    expect(saved!.quotedRateBasisPoints, 75);
    expect(saved!.quotedRatePeriod, InvestmentRatePeriod.monthly);
    expect(saved!.yieldPaymentDay, 10);
    expect(tester.takeException(), isNull);
  });
}

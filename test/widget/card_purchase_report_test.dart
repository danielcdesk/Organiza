import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/reports_page.dart';

void main() {
  testWidgets('relatório mostra compra no mês da compra', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 1, 5, 12)));
    addTearDown(store.dispose);
    store.addCreditCard(
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 100000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff000000,
    );
    store.addCardPurchase(
      cardId: store.creditCards.single.id,
      description: 'Livro',
      amountInCents: 10001,
      installments: 3,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ReportsPage(
        store: store,
        hideValues: false,
        onExport: (_, __) async {},
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 100,01'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Gastos por categoria'), 250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Outros'), findsWidgets);
  });
}

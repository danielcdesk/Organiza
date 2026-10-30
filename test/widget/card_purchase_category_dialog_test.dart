import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('compra escolhe categoria, subcategoria e data', (tester) async {
    CardPurchaseInput? result;
    final now = DateTime(2026, 1, 5, 12);
    final card = CreditCard(
      id: 'card',
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 100000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff000000,
      createdAt: now,
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: Builder(
          builder: (context) => FilledButton(
                onPressed: () async =>
                    result = await showDialog<CardPurchaseInput>(
                  context: context,
                  builder: (_) => CardPurchaseDialog(
                    cards: [card],
                    categories: [
                      FinanceCategory(
                          id: 'other',
                          name: 'Outros',
                          type: TransactionType.expense,
                          createdAt: now),
                      FinanceCategory(
                          id: 'education',
                          name: 'Educação',
                          type: TransactionType.expense,
                          createdAt: now),
                    ],
                    subcategories: [
                      FinanceSubcategory(
                        id: 'books',
                        categoryId: 'education',
                        name: 'Livros',
                        createdAt: now,
                      )
                    ],
                    clock: Clock.fixed(now),
                  ),
                ),
                child: const Text('Nova compra'),
              )),
    )));
    await tester.tap(find.text('Nova compra'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Coleção');
    await tester.enterText(find.byType(TextField).at(1), '100,00');
    await tester.tap(find.text('Outros').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Educação').last);
    await tester.pumpAndSettle();
    expect(find.text('Livros'), findsOneWidget);
    await tester.tap(find.text('Salvar compra'));
    await tester.pumpAndSettle();
    expect(result?.category, 'Educação');
    expect(result?.subcategory, 'Livros');
    expect(result?.purchasedOn, now);
  });
}

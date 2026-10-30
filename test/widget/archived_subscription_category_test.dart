import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('editar assinatura preserva categoria arquivada', (tester) async {
    SubscriptionInput? result;
    final subscription = Subscription(
      id: 'subscription',
      name: 'Clube',
      amountInCents: 2000,
      billingDay: 10,
      category: 'Lazer especial',
      categoryId: 'archived',
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => FilledButton(
                  onPressed: () async =>
                      result = await showDialog<SubscriptionInput>(
                    context: context,
                    builder: (_) => SubscriptionDialog(
                      categories: const ['Lazer'],
                      subscription: subscription,
                    ),
                  ),
                  child: const Text('Editar'),
                )),
      ),
    ));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Lazer especial (arquivada)'), findsOneWidget);
    await tester.tap(find.text('Salvar assinatura'));
    await tester.pumpAndSettle();
    expect(result?.category, 'Lazer especial');
  });
}

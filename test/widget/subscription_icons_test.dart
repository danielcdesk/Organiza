import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/dialogs.dart';
import 'package:organiza/presentation/subscriptions_page.dart';

void main() {
  testWidgets('marca original aparece na lista mobile e persiste',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addSubscription(
        name: 'Meu streaming',
        amountInCents: 2990,
        billingDay: 10,
        category: 'Lazer',
        iconKey: 'netflix');
    expect(store.subscriptions.single.iconKey, 'netflix');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SubscriptionsPage(
                store: store,
                onAdd: () {},
                onDelete: (_) {},
                onEdit: (_) {},
                onActiveChanged: (_, __) {}))));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.label == 'Ícone Netflix'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usuário escolhe o ícone no cadastro mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          onPressed: () async => showDialog<SubscriptionInput>(
              context: context,
              builder: (_) => const SubscriptionDialog(categories: ['Lazer'])),
          child: const Text('Abrir')),
    ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Ícone'), findsOneWidget);
    expect(find.text('Automático pelo nome'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

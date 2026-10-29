import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/basic_pages.dart';
import 'package:organiza/presentation/organiza_app.dart';
import 'package:organiza/presentation/organiza_theme.dart';

void main() {
  testWidgets('novo lançamento começa no hoje do relógio do aplicativo',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory(
      clock: Clock.fixed(DateTime(2024, 2, 29, 12)),
    );
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa', incomeInCents: 0);
    store.addAccount('Principal', 0);

    await tester.pumpWidget(OrganizaApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Fevereiro de 2024'), findsOneWidget);
    await tester.tap(find.text('Nova despesa').first);
    await tester.pumpAndSettle();

    expect(find.text('Data: 29/02/2024'), findsOneWidget);
    await tester.tap(find.text('Data: 29/02/2024'));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.currentDate, DateTime(2024, 2, 29));
    expect(picker.lastDate, DateTime(2025, 2, 28));
    expect(tester.takeException(), isNull);
  });

  testWidgets('histórico abre e restaura o mês do relógio do aplicativo',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory(
      clock: Clock.fixed(DateTime(2024, 2, 29, 12)),
    );
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final accountId = store.accounts.single.id;
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.expense,
      amountInCents: 100,
      description: 'Compra de fevereiro',
      occurredOn: DateTime(2024, 2, 29),
    );
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.expense,
      amountInCents: 200,
      description: 'Compra de março',
      occurredOn: DateTime(2024, 3, 1),
    );

    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.light(),
      home: Scaffold(
        body: TransactionsPage(
          store: store,
          hideValues: false,
          onAdd: () {},
          onDelete: (_) {},
          onSettledChanged: (_, __) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Fevereiro 2024'), findsWidgets);
    expect(find.text('Compra de fevereiro'), findsOneWidget);
    expect(find.text('Compra de março'), findsNothing);

    await tester.tap(find.text('Todo o período'));
    await tester.pumpAndSettle();
    expect(find.text('Compra de março'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Fevereiro 2024'), findsWidgets);
    expect(find.text('Compra de março'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

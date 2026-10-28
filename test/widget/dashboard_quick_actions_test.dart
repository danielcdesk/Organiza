import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/organiza_app.dart';

void main() {
  testWidgets('ações rápidas abrem receita e transferência no tipo correto',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa', incomeInCents: 0);
    store.addAccount('Principal', 0);
    store.addAccount('Reserva', 0);

    await tester.pumpWidget(OrganizaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova receita').first);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(DropdownButtonFormField<TransactionType>, 'Receita'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transferir').first);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
          DropdownButtonFormField<TransactionType>, 'Transferência'),
      findsOneWidget,
    );
    expect(find.text('Conta de destino'), findsOneWidget);
  });
}

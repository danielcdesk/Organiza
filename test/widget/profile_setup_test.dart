import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/organiza_app.dart';
import 'package:organiza/presentation/shared_widgets.dart';

void main() {
  testWidgets('primeiro acesso exige perfil antes de abrir o painel',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    await tester.pumpWidget(OrganizaApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Suas finanças, só no seu aparelho.'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    expect(find.text('Vamos começar'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('profile-setup-name')), 'Pessoa teste');
    await tester.enterText(
        find.byKey(const ValueKey('profile-setup-income')), '5.000,00');
    await tester
        .ensureVisible(find.byKey(const ValueKey('profile-setup-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-setup-submit')));
    await tester.pumpAndSettle();

    expect(store.profileName, 'Pessoa teste');
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Disponível no mês'), findsOneWidget);
  });
}

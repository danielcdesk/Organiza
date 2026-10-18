import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/app_lock_gate.dart';

void main() {
  testWidgets('requires system unlock and reveals the app after success',
      (tester) async {
    final store = OrganizaStore.inMemory();
    store.updateAppLockPreferences(
        enabled: true, timeoutMinutes: 5, onWindowHide: false);
    await tester.pumpWidget(MaterialApp(
      home: AppLockGate(
          store: store,
          authenticate: () async => true,
          child: const Scaffold(body: Text('Conteúdo protegido'))),
    ));
    expect(find.text('Organiza bloqueado'), findsOneWidget);
    expect(find.text('Conteúdo protegido'), findsNothing);
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Conteúdo protegido'), findsOneWidget);
    store.dispose();
  });
}

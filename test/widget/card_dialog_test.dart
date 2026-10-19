import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('cartão aceita emissor e cor clara personalizada no mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CardInput? saved;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () async => saved = await showDialog<CardInput>(
            context: context, builder: (_) => const CardDialog()),
        child: const Text('Abrir')),
    ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome do cartão'), 'Principal');
    await tester.enterText(find.widgetWithText(TextField, 'Emissor ou banco (opcional)'), 'Nubank');
    await tester.enterText(find.widgetWithText(TextField, 'Últimos 4 dígitos'), '4242');
    await tester.enterText(find.widgetWithText(TextField, 'Limite (R\$)'), '100000');
    await tester.ensureVisible(find.widgetWithText(TextField, 'Cor personalizada (hex)'));
    await tester.enterText(find.widgetWithText(TextField, 'Cor personalizada (hex)'), '#FFFFFF');
    await tester.ensureVisible(find.text('Salvar cartão'));
    await tester.tap(find.text('Salvar cartão'));
    await tester.pumpAndSettle();
    expect(saved?.issuer, 'Nubank');
    expect(saved?.colorValue, 0xFFFFFFFF);
    expect(saved?.lastFour, '4242');
    expect(tester.takeException(), isNull);
  });
}

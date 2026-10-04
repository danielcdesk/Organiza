import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/organiza_theme.dart';
import 'package:organiza/presentation/welcome_page.dart';

void main() {
  testWidgets('boas-vindas tem ação principal, restauração e privacidade',
      (tester) async {
    var started = false;
    var restored = false;
    var privacy = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: OrganizaTheme.dark(),
        home: WelcomePage(
          onStart: () => started = true,
          onRestore: () => restored = true,
          onPrivacy: () => privacy = true,
        ),
      ),
    );

    expect(find.text('Suas finanças, só no seu aparelho.'), findsOneWidget);
    await tester.ensureVisible(find.text('Já tenho um backup'));
    await tester.tap(find.text('Começar'));
    await tester.tap(find.text('Já tenho um backup'));
    await tester.ensureVisible(find.text('Política de privacidade'));
    await tester.tap(find.text('Política de privacidade'));
    expect(started, isTrue);
    expect(restored, isTrue);
    expect(privacy, isTrue);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('boas-vindas não estoura em ${width.toInt()} dp e fonte 200%',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrganizaTheme.light(),
          home: WelcomePage(
            onStart: () {},
            onRestore: () {},
            onPrivacy: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

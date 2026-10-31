import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/subscription_platform_mark.dart';

void main() {
  testWidgets('Spotify e ChatGPT mostram seus logos reais', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(children: [
          SubscriptionPlatformMark(name: 'Spotify', category: 'Lazer'),
          SubscriptionPlatformMark(name: 'ChatGPT Plus', category: 'Trabalho'),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('subscription-platform-spotify-logo')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('subscription-platform-chatgpt-logo')),
        findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
  });

  testWidgets('assinaturas comuns recebem marcas e outras têm ícone genérico',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(children: [
          SubscriptionPlatformMark(name: 'Netflix Premium', category: 'Lazer'),
          SubscriptionPlatformMark(name: 'Spotify', category: 'Lazer'),
          SubscriptionPlatformMark(name: 'Serviço próprio', category: 'Outros'),
        ]),
      ),
    ));
    expect(find.text('N'), findsOneWidget);
    expect(find.byKey(const ValueKey('subscription-platform-spotify-logo')),
        findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
    expect(find.byIcon(Icons.autorenew_rounded), findsOneWidget);
  });
}

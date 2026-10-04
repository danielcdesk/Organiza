import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/basic_pages.dart';
import 'package:organiza/presentation/dashboard_page.dart';
import 'package:organiza/presentation/organiza_theme.dart';
import 'package:organiza/presentation/overview_widgets.dart';

void main() {
  group('contraste do tema', () {
    for (final brightness in Brightness.values) {
      test('mantém contraste mínimo em $brightness', () {
        final scheme = (brightness == Brightness.light
                ? OrganizaTheme.light()
                : OrganizaTheme.dark())
            .colorScheme;

        expect(_contrast(scheme.primary, scheme.surface),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.secondary, scheme.surface),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.onSecondary, scheme.secondary),
            greaterThanOrEqualTo(4.5));
        expect(
            _contrast(scheme.error, scheme.surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5));
        expect(_contrast(scheme.onSurfaceVariant, scheme.surface),
            greaterThanOrEqualTo(4.5));
        expect(
            _contrast(scheme.outline, scheme.surface), greaterThanOrEqualTo(3));
      });
    }
  });

  testWidgets('controles principais têm alvo mínimo de 48 dp', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.light(),
      home: Scaffold(
        body: Column(
          children: [
            FilledButton(
                key: const Key('filled'),
                onPressed: () {},
                child: const Text('Salvar')),
            OutlinedButton(
                key: const Key('outlined'),
                onPressed: () {},
                child: const Text('Editar')),
            TextButton(
                key: const Key('text'),
                onPressed: () {},
                child: const Text('Abrir')),
            IconButton(
              key: const Key('icon'),
              tooltip: 'Buscar',
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
    ));

    for (final key in ['filled', 'outlined', 'text', 'icon']) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
  });

  testWidgets('botões somente com ícone têm rótulo semântico', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Conta principal com um nome bastante comprido', 100000);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 2500,
      description:
          'Despesa com descrição longa para validar a leitura ampliada',
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

    expect(find.bySemanticsLabel('Mês anterior'), findsOneWidget);
    expect(find.bySemanticsLabel('Próximo mês'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('gráfico oferece descrição e tabela alternativa', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.light(),
      home: Scaffold(
        body: CashFlowChart(transactions: const [], hideValues: false),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ver tabela de valores'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Gráfico de entradas e saídas')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Visão geral, Finanças e Organização suportam fonte em 200%',
      (tester) async {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Conta principal com um nome bastante comprido', 100000);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 2500,
      description:
          'Despesa com descrição longa para validar a leitura ampliada',
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    final pages = [
      DashboardPage(
        store: store,
        hideValues: false,
        onNewTransaction: () {},
        onOpenCards: () {},
        onOpenTransactions: () {},
        onOpenGoals: () {},
        onOpenReports: () {},
        onNewAccount: () {},
      ),
      TransactionsPage(
        store: store,
        hideValues: false,
        onAdd: () {},
        onDelete: (_) {},
        onSettledChanged: (_, __) {},
      ),
      PlanningPage(
        store: store,
        onAdd: () {},
        onDeleteTask: (_) async {},
        onAddBudget: () {},
        onDeleteBudget: (_) {},
        onCancelSalary: (_) {},
      ),
    ];

    for (final page in pages) {
      await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.mobile(OrganizaTheme.light()),
        home: Scaffold(body: page),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('foco de teclado tem indicador visível', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.light(),
      home: Scaffold(
        body: IconButton(
          tooltip: 'Buscar',
          onPressed: () {},
          icon: const Icon(Icons.search),
        ),
      ),
    ));

    final style = Theme.of(tester.element(find.byType(IconButton)))
        .iconButtonTheme
        .style!;
    final focusedSide = style.side!.resolve({WidgetState.focused});
    expect(focusedSide?.width, 2);
  });

  testWidgets('tela principal usa ordem de foco explícita', (tester) async {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.light(),
      home: Scaffold(
        body: DashboardPage(
          store: store,
          hideValues: false,
          onNewTransaction: () {},
          onOpenCards: () {},
          onOpenTransactions: () {},
          onOpenGoals: () {},
          onOpenReports: () {},
          onNewAccount: () {},
        ),
      ),
    ));

    expect(find.byKey(const Key('dashboard-focus-order')), findsOneWidget);
  });
}

double _contrast(Color first, Color second) {
  final firstLuminance = _luminance(first);
  final secondLuminance = _luminance(second);
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
  return (lighter + .05) / (darker + .05);
}

double _luminance(Color color) {
  double channel(int value) {
    final normalized = value / 255;
    return normalized <= .03928
        ? normalized / 12.92
        : math.pow((normalized + .055) / 1.055, 2.4).toDouble();
  }

  final red = channel((color.r * 255).round());
  final green = channel((color.g * 255).round());
  final blue = channel((color.b * 255).round());
  return .2126 * red + .7152 * green + .0722 * blue;
}

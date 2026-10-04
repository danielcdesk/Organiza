import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/organiza_theme.dart';
import 'package:organiza/presentation/shared_widgets.dart';

void main() {
  testWidgets('componentes visuais expõem rótulos e estados', (tester) async {
    final semantics = tester.ensureSemantics();
    var selected = 'Mês';
    await tester.pumpWidget(
      MaterialApp(
        theme: OrganizaTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ListView(
              children: [
                const HeroAmount(
                  label: 'Disponível no mês',
                  value: 'R\$ 100,00',
                  subtitle: 'Saldo atual',
                ),
                const DeltaText(
                  value: '+5%',
                  semanticValue: 'subiu 5%',
                  tone: DeltaTone.positive,
                ),
                SegmentedRange<String>(
                  options: const ['Mês', '3M'],
                  selected: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
                QuickActionGrid(
                  actions: [
                    for (final label in const [
                      'Nova despesa',
                      'Nova receita',
                      'Transferir',
                      'Cartões',
                    ])
                      QuickActionItem(
                        icon: Icons.add_rounded,
                        label: label,
                        onPressed: () {},
                      ),
                  ],
                ),
                const StatusPill(label: 'Pendente'),
                HairlineSection(
                  title: 'Movimento',
                  child: Text('Conteúdo',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Disponível no mês')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('subiu 5%')), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Mês'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('quick-action-Nova despesa'))).height,
        greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  testWidgets('componentes mantêm layout com fonte ampliada e tema escuro',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: OrganizaTheme.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuickActionGrid(
              actions: [
                for (final label in const [
                  'Nova despesa',
                  'Nova receita',
                  'Transferir',
                  'Cartões',
                ])
                  QuickActionItem(
                    icon: Icons.add_rounded,
                    label: label,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

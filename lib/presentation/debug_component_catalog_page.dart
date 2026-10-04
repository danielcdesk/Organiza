import 'package:flutter/material.dart';

import 'shared_widgets.dart';

class DebugComponentCatalogPage extends StatefulWidget {
  const DebugComponentCatalogPage({super.key});

  @override
  State<DebugComponentCatalogPage> createState() =>
      _DebugComponentCatalogPageState();
}

class _DebugComponentCatalogPageState extends State<DebugComponentCatalogPage> {
  var _range = '30D';
  var _nav = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Catálogo visual')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            HeroAmount(
              label: 'HeroAmount',
              value: 'R\$ 2.094,00',
              subtitle: 'Depois das contas pendentes',
            ),
            const SizedBox(height: 24),
            const DeltaText(
              value: '+12,4%',
              semanticValue: 'subiu 12,4%',
              tone: DeltaTone.positive,
            ),
            const SizedBox(height: 24),
            SegmentedRange<String>(
              options: const ['7D', '30D', '90D', 'Ano'],
              selected: _range,
              onChanged: (value) => setState(() => _range = value),
            ),
            const SizedBox(height: 24),
            QuickActionGrid(
              actions: [
                QuickActionItem(
                    icon: Icons.add_rounded,
                    label: 'Nova despesa',
                    onPressed: () {}),
                QuickActionItem(
                    icon: Icons.south_west_rounded,
                    label: 'Nova receita',
                    onPressed: () {}),
                QuickActionItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transferir',
                    onPressed: () {}),
                QuickActionItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Cartões',
                    onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                StatusPill(label: 'Confirmado'),
                StatusPill(label: 'Pendente'),
                StatusPill(label: 'Atrasado'),
              ],
            ),
            const SizedBox(height: 24),
            HairlineSection(
              title: 'HairlineSection',
              child: Text('Divisor de seção sem cartão',
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(height: 24),
            AppBottomNav(
              currentIndex: _nav,
              items: [
                for (final item in const [
                  ('Início', Icons.home_outlined),
                  ('Finanças', Icons.swap_horiz_rounded),
                  ('Nova', Icons.add_rounded),
                  ('Metas', Icons.flag_outlined),
                  ('Mais', Icons.menu_rounded),
                ])
                  AppBottomNavItem(
                    label: item.$1,
                    icon: item.$2,
                    onPressed: () => setState(() => _nav = 0),
                  ),
              ],
            ),
          ],
        ),
      );
}

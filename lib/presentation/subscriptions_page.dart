import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import 'organiza_theme.dart';
import 'shared_widgets.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage(
      {super.key,
      required this.store,
      required this.onAdd,
      required this.onDelete});
  final OrganizaStore store;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final active = store.subscriptions.where((item) => item.isActive).toList();
    final total = active.fold(0, (sum, item) => sum + item.amountInCents);
    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 44),
      children: [
        PageHeading(
          eyebrow: 'Recorrências',
          title: 'Assinaturas',
          description:
              'Organize cobranças recorrentes e saiba quanto já está comprometido no mês.',
          actions: [
            FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nova assinatura'))
          ],
        ),
        const SizedBox(height: 26),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(children: [
                  Expanded(
                      child: _Metric(
                          label: 'Comprometido por mês',
                          value: FinancialRules.formatBrl(total),
                          color: OrganizaTheme.orange)),
                  _Divider(),
                  Expanded(
                      child: _Metric(
                          label: 'Assinaturas ativas',
                          value: '${active.length}')),
                  _Divider(),
                  Expanded(
                      child: _Metric(
                          label: 'Próxima cobrança',
                          value: active.isEmpty
                              ? '—'
                              : 'dia ${active.map((e) => e.billingDay).reduce((a, b) => a < b ? a : b)}')),
                ]))),
        const SizedBox(height: 14),
        Panel(
            title: 'Cobranças recorrentes',
            subtitle: active.isEmpty
                ? 'Nenhuma assinatura ativa'
                : 'Ordenadas pelo dia de cobrança',
            child: active.isEmpty
                ? EmptyState(
                    icon: Icons.autorenew_rounded,
                    title: 'Organize suas assinaturas',
                    description:
                        'Adicione streaming, academia, seguros e outros compromissos fixos.',
                    actionLabel: 'Adicionar assinatura',
                    onAction: onAdd)
                : Column(
                    children: active
                        .map((item) => DataListRow(
                            icon: Icons.autorenew_rounded,
                            iconColor: OrganizaTheme.orange,
                            title: item.name,
                            subtitle:
                                '${item.category} · cobrança dia ${item.billingDay}',
                            value: FinancialRules.formatBrl(item.amountInCents,
                                signed: true),
                            valueColor: OrganizaTheme.orange,
                            trailing: IconButton(
                                tooltip: 'Excluir assinatura',
                                onPressed: () => onDelete(item.id),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18))))
                        .toList())),
        const SizedBox(height: 14),
        const Panel(
            title: 'Roadmap de organização',
            subtitle: 'Próximas melhorias do módulo',
            child: Column(children: [
              _RoadmapRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendário de cobranças',
                  subtitle:
                      'Ver todas as datas recorrentes em uma linha do tempo'),
              _RoadmapRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Alertas antes da cobrança',
                  subtitle: 'Lembretes locais para evitar surpresas'),
              _RoadmapRow(
                  icon: Icons.insights_outlined,
                  title: 'Impacto no orçamento',
                  subtitle: 'Cruzar assinaturas com limites por categoria'),
            ])),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700))
      ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 38, color: Theme.of(context).dividerColor);
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(children: [
        IconTile(
            icon: icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        ])),
        const StatusPill(label: 'Roadmap')
      ]));
}

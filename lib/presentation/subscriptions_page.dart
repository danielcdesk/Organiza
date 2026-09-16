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
      required this.onDelete,
      required this.onEdit,
      required this.onActiveChanged});
  final OrganizaStore store;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEdit;
  final void Function(String id, bool active) onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final active = store.subscriptions.where((item) => item.isActive).toList();
    final total = active.fold(0, (sum, item) => sum + item.amountInCents);
    final now = DateTime.now();
    DateTime nextDate(int day) {
      DateTime forMonth(int offset) {
        final month = DateTime(now.year, now.month + offset);
        final last = DateTime(month.year, month.month + 1, 0).day;
        return DateTime(month.year, month.month, day.clamp(1, last));
      }

      final thisMonth = forMonth(0);
      return thisMonth.isBefore(DateTime(now.year, now.month, now.day))
          ? forMonth(1)
          : thisMonth;
    }

    final next = active.isEmpty
        ? null
        : (active.map((item) => nextDate(item.billingDay)).toList()..sort())
            .first;
    return ListView(
      padding: pagePadding(context),
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
                          value: next == null
                              ? '—'
                              : '${next.day}/${next.month}')),
                ]))),
        const SizedBox(height: 14),
        Panel(
            title: 'Cobranças recorrentes',
            subtitle:
                '${active.length} ativa${active.length == 1 ? '' : 's'} · ${store.subscriptions.length - active.length} pausada${store.subscriptions.length - active.length == 1 ? '' : 's'}',
            child: store.subscriptions.isEmpty
                ? EmptyState(
                    icon: Icons.autorenew_rounded,
                    title: 'Organize suas assinaturas',
                    description:
                        'Adicione streaming, academia, seguros e outros compromissos fixos.',
                    actionLabel: 'Adicionar assinatura',
                    onAction: onAdd)
                : Column(
                    children: store.subscriptions
                        .map((item) => DataListRow(
                            icon: Icons.autorenew_rounded,
                            iconColor: OrganizaTheme.orange,
                            title: item.name,
                            subtitle:
                                '${item.category} · ${item.isActive ? 'próxima em ${nextDate(item.billingDay).day}/${nextDate(item.billingDay).month}' : 'pausada'}',
                            value: FinancialRules.formatBrl(item.amountInCents,
                                signed: true),
                            valueColor: OrganizaTheme.orange,
                            trailing: PopupMenuButton<String>(
                                tooltip: 'Ações da assinatura',
                                onSelected: (action) {
                                  if (action == 'edit') onEdit(item.id);
                                  if (action == 'toggle') {
                                    onActiveChanged(item.id, !item.isActive);
                                  }
                                  if (action == 'delete') onDelete(item.id);
                                },
                                itemBuilder: (_) => [
                                      const PopupMenuItem(
                                          value: 'edit', child: Text('Editar')),
                                      PopupMenuItem(
                                          value: 'toggle',
                                          child: Text(item.isActive
                                              ? 'Pausar'
                                              : 'Reativar')),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Excluir')),
                                    ])))
                        .toList())),
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

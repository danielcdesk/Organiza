import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'organiza_theme.dart';
import 'shared_widgets.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage(
      {super.key,
      required this.store,
      required this.onAdd,
      required this.onDelete});

  final OrganizaStore store;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthBudgets = store.budgets
        .where((item) => item.year == now.year && item.month == now.month)
        .toList();
    final totalLimit =
        monthBudgets.fold(0, (sum, item) => sum + item.limitInCents);
    final totalSpent = monthBudgets.fold(
        0,
        (sum, item) =>
            sum + FinancialRules.budgetSpent(item, store.transactions));

    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 44),
      children: [
        PageHeading(
          eyebrow: 'Planejamento mensal',
          title: 'Orçamentos',
          description:
              'Defina limites simples por categoria e acompanhe o ritmo dos seus gastos.',
          actions: [
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Novo orçamento'),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _BudgetSummary(limit: totalLimit, spent: totalSpent),
        const SizedBox(height: 14),
        if (monthBudgets.isEmpty)
          Panel(
            title: 'Seu mês, no controle',
            subtitle: 'Acompanhamento por categoria',
            child: EmptyState(
              icon: Icons.track_changes_rounded,
              title: 'Nenhum orçamento neste mês',
              description:
                  'Crie um limite para Alimentação, Moradia ou qualquer categoria que queira acompanhar.',
              actionLabel: 'Criar orçamento',
              onAction: onAdd,
            ),
          )
        else
          Panel(
            title: 'Limites de ${_monthName(now.month)}',
            subtitle:
                '${monthBudgets.length} categoria${monthBudgets.length == 1 ? '' : 's'} acompanhada${monthBudgets.length == 1 ? '' : 's'}',
            child: Column(
              children: monthBudgets
                  .map((budget) => _BudgetRow(
                        budget: budget,
                        spent: FinancialRules.budgetSpent(
                            budget, store.transactions),
                        onDelete: () => onDelete(budget.id),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.limit, required this.spent});
  final int limit;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final remaining = limit - spent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
                child: _Metric(
                    label: 'Limite do mês',
                    value: FinancialRules.formatBrl(limit))),
            _Divider(),
            Expanded(
                child: _Metric(
                    label: 'Já utilizado',
                    value: FinancialRules.formatBrl(spent),
                    color: OrganizaTheme.orange)),
            _Divider(),
            Expanded(
                child: _Metric(
                    label: remaining >= 0 ? 'Disponível' : 'Acima do limite',
                    value: FinancialRules.formatBrl(remaining),
                    color: remaining >= 0
                        ? const Color(0xFF258A5A)
                        : const Color(0xFFC94D4D))),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 38, color: Theme.of(context).dividerColor);
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow(
      {required this.budget, required this.spent, required this.onDelete});
  final Budget budget;
  final int spent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress =
        budget.limitInCents == 0 ? 0.0 : spent / budget.limitInCents;
    final over = spent > budget.limitInCents;
    final color = over
        ? const Color(0xFFC94D4D)
        : progress > .8
            ? OrganizaTheme.orange
            : const Color(0xFF258A5A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: _categoryIcon(budget.category), color: color),
              const SizedBox(width: 11),
              Expanded(
                  child: Text(budget.category,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(
                  '${FinancialRules.formatBrl(spent)} de ${FinancialRules.formatBrl(budget.limitInCents)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              IconButton(
                  tooltip: 'Excluir orçamento',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18)),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
                value: value, minHeight: 8, color: color),
          ),
          const SizedBox(height: 6),
          Text(
              over
                  ? 'Você passou ${FinancialRules.formatBrl(spent - budget.limitInCents)} do limite'
                  : '${((progress * 100).round())}% utilizado',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
      'Alimentação' => Icons.restaurant_outlined,
      'Moradia' => Icons.home_outlined,
      'Transporte' => Icons.directions_car_outlined,
      'Lazer' => Icons.local_activity_outlined,
      'Saúde' => Icons.favorite_border_rounded,
      'Educação' => Icons.menu_book_outlined,
      _ => Icons.category_outlined,
    };

String _monthName(int month) => const [
      '',
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ][month];

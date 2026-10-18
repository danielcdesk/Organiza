import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_planning.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

class MonthlyPlanningPage extends StatefulWidget {
  const MonthlyPlanningPage({
    super.key,
    required this.store,
    required this.hideValues,
  });

  final OrganizaStore store;
  final bool hideValues;

  @override
  State<MonthlyPlanningPage> createState() => _MonthlyPlanningPageState();
}

class _MonthlyPlanningPageState extends State<MonthlyPlanningPage> {
  late DateTime _month = DateTime.utc(
      widget.store.clock.now().year, widget.store.clock.now().month);

  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  String _money(int cents) =>
      widget.hideValues ? '••••' : FinancialRules.formatBrl(cents);

  @override
  Widget build(BuildContext context) {
    final summary = summarize(
      transactions: widget.store.reportTransactions,
      categories: widget.store.financeCategories,
      month: _month,
      excludedEssentialCategoryIds: const {},
    );
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: 'Planejamento mensal',
          subtitle: 'Entradas e saídas pela competência do mês',
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                tooltip: 'Mês anterior',
                onPressed: () => setState(() =>
                    _month = DateTime.utc(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Flexible(child: Text('${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                tooltip: 'Próximo mês',
                onPressed: () => setState(() =>
                    _month = DateTime.utc(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
            _line('Receitas', summary.incomeInCents),
            _line('Despesas essenciais', summary.essentialExpensesInCents),
            _line('Despesas não essenciais', summary.nonEssentialExpensesInCents),
            _line('Não classificadas', summary.unclassifiedExpensesInCents),
            const Divider(),
            _line('Sobra do mês', summary.surplusInCents),
            _line('Taxa de poupança', summary.savingsRateBasisPoints,
                percentage: true),
          ]),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Categorias essenciais',
          subtitle: 'Classifique uma vez; lançamentos antigos continuam no total',
          child: categories.isEmpty
              ? const Text('Nenhuma categoria de despesa')
              : Column(children: [
                  for (final category in categories)
                    Row(children: [
                      Expanded(child: Text(category.name)),
                      SizedBox(
                        width: 156,
                        child: DropdownButtonFormField<ExpenseEssentiality>(
                          isExpanded: true,
                          key: ValueKey('essentiality-${category.id}-${category.essentiality.name}'),
                          initialValue: category.essentiality,
                          decoration: const InputDecoration(
                              labelText: 'Classificação'),
                          items: const [
                            DropdownMenuItem(value: ExpenseEssentiality.unclassified,
                                child: Text('Não classificada')),
                            DropdownMenuItem(value: ExpenseEssentiality.essential,
                                child: Text('Essencial')),
                            DropdownMenuItem(value: ExpenseEssentiality.nonEssential,
                                child: Text('Não essencial')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            widget.store.setFinanceCategoryEssentiality(
                                category.id, value);
                            setState(() {});
                          },
                        ),
                      ),
                    ]),
                ]),
        ),
      ],
    );
  }

  Widget _line(String label, int value, {bool percentage = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(widget.hideValues
              ? '••••'
              : percentage
                  ? '${(value / 100).toStringAsFixed(2)}%'
                  : _money(value)),
        ]),
      );
}

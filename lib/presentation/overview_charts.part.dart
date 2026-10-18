part of 'overview_widgets.dart';

class CashFlowChart extends StatefulWidget {
  const CashFlowChart(
      {super.key, required this.transactions, required this.hideValues});
  final List<TransactionRecord> transactions;
  final bool hideValues;
  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart> {
  int _selected = 5;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final incomes = months
        .map((m) => FinancialRules.monthTotal(
            widget.transactions, m, TransactionType.income))
        .toList();
    final expenses = months
        .map((m) => FinancialRules.monthTotal(
            widget.transactions, m, TransactionType.expense))
        .toList();
    final maximum = [...incomes, ...expenses].fold<int>(1, math.max);
    String money(int value) =>
        widget.hideValues ? '••••••' : FinancialRules.formatBrl(value);
    final selected = months[_selected];
    return Panel(
        title: 'Seu dinheiro no tempo',
        subtitle: 'Últimos 6 meses · valores confirmados',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 18, runSpacing: 6, children: [
            Text('Entradas  ${money(incomes[_selected])}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600)),
            Text('Saídas  ${money(expenses[_selected])}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          Semantics(
            container: true,
            label: _cashFlowChartSemantics(months, incomes, expenses),
            child: SizedBox(
                height: 146,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(6, (i) {
                      final active = i == _selected;
                      final month =
                          '${monthName(months[i].month)} ${months[i].year}';
                      final label = widget.hideValues
                          ? '$month. Valores ocultos.'
                          : '$month: entradas ${money(incomes[i])}, '
                              'saídas ${money(expenses[i])}';
                      return Expanded(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Tooltip(
                            message: label,
                            child: Semantics(
                              button: true,
                              label: label,
                              selected: active,
                              child: Material(
                                  color: active
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setState(() => _selected = i),
                                    child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            7, 12, 7, 8),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                  child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                    _bar(
                                                        context,
                                                        incomes[i] / maximum,
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                    const SizedBox(width: 4),
                                                    _bar(
                                                        context,
                                                        expenses[i] / maximum,
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                  ])),
                                              const SizedBox(height: 10),
                                              Text(
                                                  monthName(months[i].month)
                                                      .substring(0, 3),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: active
                                                          ? FontWeight.w800
                                                          : FontWeight.w500)),
                                            ])),
                                  )),
                            )),
                      ));
                    }))),
          ),
          const SizedBox(height: 14),
          Text(
              '${sentenceCase(monthName(selected.month))} ${selected.year} · Resultado ${money(incomes[_selected] - expenses[_selected])}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Ver tabela de valores'),
            children: [
              for (var i = 0; i < months.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      '${sentenceCase(monthName(months[i].month))} ${months[i].year}'),
                  subtitle: Text(widget.hideValues
                      ? 'Entradas e saídas: valores ocultos'
                      : 'Entradas: ${money(incomes[i])}\nSaídas: ${money(expenses[i])}'),
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
            ],
          ),
        ]));
  }

  String _cashFlowChartSemantics(
      List<DateTime> months, List<int> incomes, List<int> expenses) {
    String format(int value) =>
        widget.hideValues ? 'valores ocultos' : FinancialRules.formatBrl(value);
    if (widget.hideValues) {
      return 'Gráfico de entradas e saídas dos últimos seis meses. '
          'Valores ocultos. Use a tabela de valores para navegar por mês.';
    }
    final values = <String>[];
    for (var i = 0; i < months.length; i++) {
      values
          .add('${sentenceCase(monthName(months[i].month))} ${months[i].year}: '
              'entradas ${format(incomes[i])}, saídas ${format(expenses[i])}');
    }
    return 'Gráfico de entradas e saídas dos últimos seis meses. '
        '${values.join('. ')}.';
  }

  Widget _bar(BuildContext context, double ratio, Color color) => Expanded(
          child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                height: widget.hideValues ? 5 : math.max(3, 88 * value),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: ratio == 0 ? .15 : .85),
                    borderRadius: BorderRadius.circular(5)))),
      ));
}

class FirstStepsCard extends StatelessWidget {
  const FirstStepsCard({super.key, required this.onNewAccount});
  final VoidCallback onNewAccount;
  @override
  Widget build(BuildContext context) => Panel(
      title: 'Seu ponto de partida',
      subtitle: 'Organize o presente. Planeje o próximo passo.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            '1. Cadastre uma conta e seu saldo atual.\n2. Registre receitas e despesas.\n3. Defina um limite mensal e uma meta.',
            style: TextStyle(height: 1.9)),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: onNewAccount,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar primeira conta')),
      ]));
}

class BudgetWatch extends StatelessWidget {
  const BudgetWatch(
      {super.key,
      required this.store,
      required this.hideValues,
      required this.onOpen});
  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budgets = store.budgets
        .where((b) =>
            b.year == now.year && b.month == now.month && b.limitInCents > 0)
        .toList()
      ..sort((a, b) =>
          (FinancialRules.budgetSpent(b, store.reportTransactions) /
                  b.limitInCents)
              .compareTo(
                  FinancialRules.budgetSpent(a, store.reportTransactions) /
                      a.limitInCents));
    if (budgets.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Panel(
          title: 'De olho nos limites',
          subtitle: 'Categorias mais próximas do orçamento mensal',
          trailing:
              TextButton(onPressed: onOpen, child: const Text('Planejar')),
          child: Column(
              children: budgets.take(3).map((budget) {
            final spent =
                FinancialRules.budgetSpent(budget, store.reportTransactions);
            final ratio = spent / budget.limitInCents;
            final color = ratio >= 1
                ? Theme.of(context).colorScheme.error
                : ratio >= .8
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary;
            return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Text(budget.category,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    Text(
                        hideValues
                            ? '••••'
                            : '${(ratio * 100).round()}%${ratio > 1 ? ' · Acima do limite' : ''}',
                        style: TextStyle(fontSize: 12, color: color))
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: hideValues ? 0 : ratio.clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                      color: color),
                  const SizedBox(height: 6),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          hideValues
                              ? 'Valores ocultos'
                              : '${FinancialRules.formatBrl(spent)} de ${FinancialRules.formatBrl(budget.limitInCents)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))),
                ]));
          }).toList()),
        ));
  }
}

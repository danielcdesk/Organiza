part of 'overview_widgets.dart';

class CashFlowWorkspace extends StatelessWidget {
  const CashFlowWorkspace(
      {super.key,
      required this.store,
      required this.hideValues,
      required this.onOpenTransactions});
  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    final summary = CashFlowSummary(store.transactions, DateTime.now());
    final evolution =
        CashFlowChart(transactions: store.transactions, hideValues: hideValues);
    final agenda = _PendingAgenda(
        store: store,
        summary: summary,
        hideValues: hideValues,
        onOpenTransactions: onOpenTransactions);
    return Column(children: [
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 880) {
          return Column(
              children: [evolution, const SizedBox(height: 16), agenda]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: evolution),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: agenda),
        ]);
      }),
      const SizedBox(height: 16),
      _Forecast(store: store, summary: summary, hideValues: hideValues),
      const SizedBox(height: 16),
      BalanceProjectionCard(store: store, hideValues: hideValues),
    ]);
  }
}

class BalanceProjectionCard extends StatefulWidget {
  const BalanceProjectionCard({
    super.key,
    required this.store,
    required this.hideValues,
  });

  final OrganizaStore store;
  final bool hideValues;

  @override
  State<BalanceProjectionCard> createState() => _BalanceProjectionCardState();
}

class _BalanceProjectionCardState extends State<BalanceProjectionCard> {
  var _horizonDays = 30;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.store.accounts.isNotEmpty ||
        widget.store.transactions.isNotEmpty ||
        widget.store.salarySchedules.isNotEmpty;
    final projection = BalanceProjection.calculate(
      accounts: widget.store.accounts,
      transactions: widget.store.transactions,
      salaries: widget.store.salarySchedules,
      cardInvoices: widget.store.cardInvoices,
      clock: widget.store.clock,
      horizonDays: _horizonDays,
    );
    String money(int cents) =>
        widget.hideValues ? '••••••' : FinancialRules.formatBrl(cents);

    return Panel(
      title: 'Saldo projetado',
      subtitle: 'Evolução diária prevista para os próximos $_horizonDays dias',
      trailing: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 30, label: Text('30 dias')),
          ButtonSegment(value: 60, label: Text('60 dias')),
          ButtonSegment(value: 90, label: Text('90 dias')),
        ],
        selected: {_horizonDays},
        onSelectionChanged: (value) =>
            setState(() => _horizonDays = value.first),
      ),
      child: !hasData
          ? const EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Sem dados para projetar',
              description: 'Cadastre uma conta ou registre uma movimentação.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectionMetricRow(
                  dailySpendable: money(projection.canSpendPerDayInCents),
                  nextSalary: projection.nextSalaryDate == null
                      ? 'Sem próximo salário cadastrado'
                      : 'Até ${_dayMonth(projection.nextSalaryDate!)}',
                  hideValues: widget.hideValues,
                ),
                const SizedBox(height: 18),
                Semantics(
                  container: true,
                  label: _chartSemantics(projection),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _BalanceProjectionPainter(
                        points: projection.points,
                        criticalDate: projection.firstNegativeDate,
                        lineColor: Theme.of(context).colorScheme.primary,
                        gridColor: Theme.of(context).dividerColor,
                        criticalColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (projection.firstNegativeDate != null)
                  Text(
                    'Seu saldo pode ficar negativo em '
                    '${_dayMonth(projection.firstNegativeDate!)} '
                    '(${_negativeMoney(projection.firstNegativeBalanceInCents!, widget.hideValues)})',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    'Nenhum saldo negativo projetado neste período.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('Ver tabela de valores'),
                  children: [
                    _ProjectionTable(
                      points: projection.points,
                      hideValues: widget.hideValues,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _chartSemantics(BalanceProjectionResult projection) {
    if (widget.hideValues) {
      return 'Gráfico de saldo projetado. Valores ocultos.';
    }
    final first = projection.points.first.balanceInCents;
    final last = projection.points.last.balanceInCents;
    final critical = projection.firstNegativeDate == null
        ? 'Nenhum saldo negativo projetado.'
        : 'Primeiro saldo negativo em ${_dayMonth(projection.firstNegativeDate!)}.';
    return 'Gráfico de linha do saldo projetado por $_horizonDays dias. '
        'Começa em ${FinancialRules.formatBrl(first)} e termina em '
        '${FinancialRules.formatBrl(last)}. $critical';
  }
}

class _ProjectionMetricRow extends StatelessWidget {
  const _ProjectionMetricRow({
    required this.dailySpendable,
    required this.nextSalary,
    required this.hideValues,
  });

  final String dailySpendable;
  final String nextSalary;
  final bool hideValues;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _ProjectionMetric(
            label: 'Pode gastar por dia',
            value: dailySpendable,
            detail: nextSalary,
            color: Theme.of(context).colorScheme.primary,
          ),
          _ProjectionMetric(
            label: 'Critério',
            value: 'Menor saldo até o próximo salário',
            detail: hideValues ? 'Valores ocultos' : 'Mínimo de R\$ 0,00',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      );
}

class _ProjectionMetric extends StatelessWidget {
  const _ProjectionMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 2),
            Text(detail,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

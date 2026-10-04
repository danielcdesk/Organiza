import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../application/organiza_store.dart';
import '../domain/balance_projection.dart';
import '../domain/cash_flow_summary.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

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

class _ProjectionTable extends StatelessWidget {
  const _ProjectionTable({required this.points, required this.hideValues});

  final List<BalanceProjectionPoint> points;
  final bool hideValues;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Tabela alternativa do saldo projetado',
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
          },
          children: [
            const TableRow(children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Data',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Saldo',
                      style: TextStyle(fontWeight: FontWeight.w700))),
            ]),
            for (final point in points)
              TableRow(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_dayMonth(point.date))),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(hideValues
                        ? '••••••'
                        : FinancialRules.formatBrl(point.balanceInCents))),
              ]),
          ],
        ),
      );
}

class _BalanceProjectionPainter extends CustomPainter {
  const _BalanceProjectionPainter({
    required this.points,
    required this.criticalDate,
    required this.lineColor,
    required this.gridColor,
    required this.criticalColor,
  });

  final List<BalanceProjectionPoint> points;
  final DateTime? criticalDate;
  final Color lineColor;
  final Color gridColor;
  final Color criticalColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 8.0;
    const right = 8.0;
    const top = 14.0;
    const bottom = 24.0;
    final chart = Rect.fromLTRB(left, top,
        math.max(left + 1, size.width - right), size.height - bottom);
    final values = points.map((point) => point.balanceInCents).toList();
    var minimum = values.reduce((a, b) => a < b ? a : b).toDouble();
    var maximum = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (minimum == maximum) {
      final padding = math.max(100.0, maximum.abs() * .1);
      minimum -= padding;
      maximum += padding;
    } else {
      final padding = (maximum - minimum) * .08;
      minimum -= padding;
      maximum += padding;
    }

    double xFor(int index) => points.length == 1
        ? chart.center.dx
        : chart.left + chart.width * index / (points.length - 1);
    double yFor(int value) =>
        chart.bottom - chart.height * (value - minimum) / (maximum - minimum);

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .65)
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = chart.top + chart.height * index / 2;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    if (minimum <= 0 && maximum >= 0) {
      final y = yFor(0);
      canvas.drawLine(
          Offset(chart.left, y),
          Offset(chart.right, y),
          Paint()
            ..color = criticalColor.withValues(alpha: .45)
            ..strokeWidth = 1.5);
    }

    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(xFor(index), yFor(points[index].balanceInCents));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    if (criticalDate != null) {
      final index = points.indexWhere((point) => point.date == criticalDate);
      if (index >= 0) {
        final point = points[index];
        final center = Offset(xFor(index), yFor(point.balanceInCents));
        canvas.drawCircle(
            center,
            7,
            Paint()
              ..color = criticalColor
              ..style = PaintingStyle.fill);
        canvas.drawCircle(
            center,
            10,
            Paint()
              ..color = criticalColor.withValues(alpha: .22)
              ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceProjectionPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.criticalDate != criticalDate ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}

String _dayMonth(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

String _negativeMoney(int cents, bool hideValues) =>
    hideValues ? '−••••••' : '−${FinancialRules.formatBrl(cents.abs())}';

class _Forecast extends StatelessWidget {
  const _Forecast(
      {required this.store, required this.summary, required this.hideValues});
  final OrganizaStore store;
  final CashFlowSummary summary;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    String money(int cents) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(cents);
    final projected = summary.projectedBalance(store.balance);
    final tiles = [
      (
        'A receber',
        money(summary.receivable),
        Icons.south_west_rounded,
        Theme.of(context).colorScheme.secondary
      ),
      (
        'A pagar',
        money(summary.payable),
        Icons.north_east_rounded,
        Theme.of(context).colorScheme.error
      ),
      (
        'Saldo previsto',
        money(projected),
        Icons.account_balance_wallet_outlined,
        projected < 0
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface
      ),
    ];
    return Panel(
        title: 'Até o fim do mês',
        subtitle:
            'Saldo atual + receitas pendentes − despesas pendentes, incluindo atrasos.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(
              builder: (context, constraints) => Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: tiles
                        .map((tile) => SizedBox(
                              width: constraints.maxWidth < 520
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 32) / 3,
                              child: Row(children: [
                                IconTile(icon: tile.$3, color: tile.$4),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(tile.$1,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(tile.$2,
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: tile.$4)),
                                    ]))
                              ]),
                            ))
                        .toList(),
                  )),
          const SizedBox(height: 16),
          Text(
              'Só considera lançamentos registrados. Assinaturas, faturas e salários ainda não lançados não entram nesta previsão.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]));
  }
}

class _PendingAgenda extends StatelessWidget {
  const _PendingAgenda(
      {required this.store,
      required this.summary,
      required this.hideValues,
      required this.onOpenTransactions});
  final OrganizaStore store;
  final CashFlowSummary summary;
  final bool hideValues;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Sua próxima ação',
        subtitle: summary.overdueCount > 0
            ? '${summary.overdueCount} pendência(s) em atraso'
            : 'Pagamentos e recebimentos por vencimento',
        trailing: TextButton(
            onPressed: onOpenTransactions, child: const Text('Ver todas')),
        child: summary.pending.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 27),
                child: Row(children: [
                  IconTile(
                      icon: Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Tudo em dia por aqui',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Você não tem lançamentos pendentes.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ])),
                ]))
            : Column(
                children: summary.pending.take(3).map((item) {
                final now = DateTime.now();
                final overdue = item.occurredOn
                    .isBefore(DateTime(now.year, now.month, now.day));
                final account = store.accounts
                    .where((a) => a.id == item.accountId)
                    .firstOrNull;
                final income = item.type == TransactionType.income;
                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      InstitutionMark(
                          institution: account?.institution ??
                              AccountInstitution.generic,
                          customIconKey: account?.customIconKey,
                          size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                item.description.isEmpty
                                    ? item.category
                                    : item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '${shortDate(item.occurredOn)}${overdue ? ' · Atrasado' : ''}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: overdue
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          ])),
                      const SizedBox(width: 8),
                      Text(
                          hideValues
                              ? '••••'
                              : FinancialRules.formatBrl(item.amountInCents),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: income
                                  ? Theme.of(context).colorScheme.secondary
                                  : null)),
                      Semantics(
                        button: true,
                        label: income
                            ? 'Confirmar recebimento'
                            : 'Confirmar pagamento',
                        child: IconButton(
                          tooltip: income
                              ? 'Confirmar recebimento'
                              : 'Confirmar pagamento',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: Text(income
                                          ? 'Confirmar recebimento?'
                                          : 'Confirmar pagamento?'),
                                      content: Text(
                                          'O lançamento será confirmado e o saldo de ${account?.name ?? 'sua conta'} será atualizado.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar')),
                                        FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Confirmar'))
                                      ],
                                    ));
                            if (confirmed != true || !context.mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            store.setTransactionSettled(item.id, true);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(SnackBar(
                                content: const Text('Lançamento confirmado.'),
                                action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () {
                                      if (store.transactions.any(
                                          (current) => current.id == item.id)) {
                                        store.setTransactionSettled(
                                            item.id, false);
                                      }
                                    })));
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 21),
                        ),
                      ),
                    ]));
              }).toList()),
      );
}

/// Each monthly column is a focusable button with a full textual equivalent.
/// No continuous animation is used; reduced motion is respected.
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
          (FinancialRules.budgetSpent(b, store.transactions) / b.limitInCents)
              .compareTo(FinancialRules.budgetSpent(a, store.transactions) /
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
                FinancialRules.budgetSpent(budget, store.transactions);
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

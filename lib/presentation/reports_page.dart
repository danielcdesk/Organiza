import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onExport,
  });

  final OrganizaStore store;
  final bool hideValues;
  final Future<void> Function(DateTime month, bool includePending) onExport;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  var _months = 6;
  var _includePending = false;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    );
    final data = _monthlyDataUntil(
      widget.store.transactions,
      _selectedMonth,
      _months,
      includePending: _includePending,
    );
    final monthTransactions = _transactionsForMonth(
      widget.store.transactions,
      _selectedMonth,
    );
    final previousTransactions = _transactionsForMonth(
      widget.store.transactions,
      previousMonth,
    );
    final visibleMonthTransactions = _visibleTransactions(
      monthTransactions,
      includePending: _includePending,
    );
    final visiblePreviousTransactions = _visibleTransactions(
      previousTransactions,
      includePending: _includePending,
    );
    final incomes = _typeTotal(
      visibleMonthTransactions,
      TransactionType.income,
    );
    final expenses = _typeTotal(
      visibleMonthTransactions,
      TransactionType.expense,
    );
    final previousIncomes = _typeTotal(
      visiblePreviousTransactions,
      TransactionType.income,
    );
    final previousExpenses = _typeTotal(
      visiblePreviousTransactions,
      TransactionType.expense,
    );
    final balance = incomes - expenses;
    final previousBalance = previousIncomes - previousExpenses;
    final hide = widget.hideValues;
    String money(int value) =>
        hide ? '••••••' : FinancialRules.formatBrl(value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 44),
      children: [
        PageHeading(
          eyebrow: 'Análise financeira',
          title: 'Relatórios',
          description:
              'Resumo realizado de ${_longMonth(_selectedMonth)} e contexto histórico.',
          actions: [
            _MonthNavigator(
              month: _selectedMonth,
              canGoNext: _canGoNext,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onSelect: _selectMonth,
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onExport(
                _selectedMonth,
                _includePending,
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Exportar mês'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ReportModeBar(
          includePending: _includePending,
          onChanged: (value) => setState(() => _includePending = value),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ReportMetric(
                width: constraints.maxWidth,
                label: 'Entradas do mês',
                value: money(incomes),
                icon: Icons.south_west_rounded,
                color: const Color(0xFF258A5A),
                detail: hide
                    ? 'Comparação oculta'
                    : _comparisonLabel(incomes, previousIncomes),
                detailColor: _comparisonColor(incomes, previousIncomes),
              ),
              _ReportMetric(
                width: constraints.maxWidth,
                label: 'Saídas do mês',
                value: money(expenses),
                icon: Icons.north_east_rounded,
                color: const Color(0xFFC94D4D),
                detail: hide
                    ? 'Comparação oculta'
                    : _comparisonLabel(expenses, previousExpenses),
                detailColor: _comparisonColor(
                  expenses,
                  previousExpenses,
                  lowerIsBetter: true,
                ),
              ),
              _ReportMetric(
                width: constraints.maxWidth,
                label: 'Resultado',
                value: money(balance),
                icon: Icons.account_balance_outlined,
                color: balance >= 0
                    ? const Color(0xFF258A5A)
                    : const Color(0xFFC94D4D),
                detail: hide
                    ? 'Comparação oculta'
                    : _comparisonLabel(balance, previousBalance),
                detailColor: _comparisonColor(balance, previousBalance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Evolução mensal',
          subtitle:
              'Resultado acumulado até ${monthName(_selectedMonth.month).toLowerCase()}',
          trailing: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 3, label: Text('3 meses')),
              ButtonSegment(value: 6, label: Text('6 meses')),
              ButtonSegment(value: 12, label: Text('12 meses')),
            ],
            selected: {_months},
            onSelectionChanged: (value) =>
                setState(() => _months = value.first),
          ),
          child: SizedBox(
            height: 246,
            child: _TrendChart(data: data, hideValues: hide),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final comparison =
                _IncomeExpensePanel(data: data, hideValues: hide);
            final ranking = _ExpenseRanking(
              transactions: visibleMonthTransactions,
              hideValues: hide,
            );
            if (constraints.maxWidth < 920) {
              return Column(
                children: [comparison, const SizedBox(height: 14), ranking],
              );
            }
            return SizedBox(
              height: 294,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: comparison),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: ranking),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final expensesByCategory =
                _byCategory(visibleMonthTransactions, TransactionType.expense);
            final incomesByCategory =
                _byCategory(visibleMonthTransactions, TransactionType.income);
            final expensePanel = _CategoryChart(
                title: 'Gastos por categoria',
                subtitle: 'Distribuição em ${_longMonth(_selectedMonth)}',
                data: expensesByCategory,
                color: const Color(0xFFC94D4D),
                hideValues: hide);
            final incomePanel = _CategoryChart(
                title: 'Receitas por categoria',
                subtitle: 'Distribuição em ${_longMonth(_selectedMonth)}',
                data: incomesByCategory,
                color: const Color(0xFF258A5A),
                hideValues: hide);
            if (constraints.maxWidth < 900) {
              return Column(children: [
                expensePanel,
                const SizedBox(height: 14),
                incomePanel
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: expensePanel),
              const SizedBox(width: 14),
              Expanded(child: incomePanel)
            ]);
          },
        ),
        const SizedBox(height: 14),
        _SpendingRoadmap(
            transactions: widget.store.transactions,
            subscriptions: widget.store.subscriptions,
            hideValues: hide,
            year: _selectedMonth.year,
            includePending: _includePending),
      ],
    );
  }

  bool get _canGoNext {
    return _selectedMonth.isBefore(DateTime(2100, 12));
  }

  void _changeMonth(int offset) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    if (next.year < 2000 || next.year > 2100) return;
    setState(() => _selectedMonth = next);
  }

  Future<void> _selectMonth() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initialMonth: _selectedMonth),
    );
    if (selected != null && mounted) {
      setState(() => _selectedMonth = selected);
    }
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart(
      {required this.title,
      required this.subtitle,
      required this.data,
      required this.color,
      required this.hideValues});
  final String title;
  final String subtitle;
  final Map<String, int> data;
  final Color color;
  final bool hideValues;
  @override
  Widget build(BuildContext context) {
    final rows = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximum = rows.isEmpty ? 1 : rows.first.value;
    return Panel(
      title: title,
      subtitle: rows.isEmpty ? 'Sem lançamentos categorizados' : subtitle,
      child: rows.isEmpty
          ? const EmptyState(
              icon: Icons.donut_small_outlined,
              title: 'Sem dados ainda',
              description:
                  'Categorize suas transações para visualizar o fluxo.',
            )
          : Column(
              children: rows.take(6).map((entry) {
                final ratio = entry.value / maximum;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                        if (!hideValues)
                          Text(FinancialRules.formatBrl(entry.value),
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 7),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => LinearProgressIndicator(
                            value: value, minHeight: 7, color: color),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ReportModeBar extends StatelessWidget {
  const _ReportModeBar({
    required this.includePending,
    required this.onChanged,
  });

  final bool includePending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    includePending ? 'Visão prevista' : 'Visão realizada',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    includePending
                        ? 'Inclui lançamentos pagos e pendentes do período.'
                        : 'Considera somente valores já pagos ou recebidos.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Realizado')),
                ButtonSegment(value: true, label: Text('Com previsão')),
              ],
              selected: {includePending},
              onSelectionChanged: (value) => onChanged(value.first),
            ),
          ],
        ),
      );
}

class _SpendingRoadmap extends StatelessWidget {
  const _SpendingRoadmap(
      {required this.transactions,
      required this.subscriptions,
      required this.hideValues,
      required this.year,
      required this.includePending});
  final List<TransactionRecord> transactions;
  final List<Subscription> subscriptions;
  final bool hideValues;
  final int year;
  final bool includePending;

  @override
  Widget build(BuildContext context) {
    final yearStart = DateTime(year);
    final yearEnd = DateTime(year, 12, 31);
    final gridStart = yearStart.subtract(Duration(days: yearStart.weekday - 1));
    final gridEnd = yearEnd.add(Duration(days: 7 - yearEnd.weekday));
    final days = List.generate(
      gridEnd.difference(gridStart).inDays + 1,
      (index) => gridStart.add(Duration(days: index)),
    );
    final totals = <DateTime, int>{};
    for (final item in transactions.where((item) =>
        item.type == TransactionType.expense &&
        item.occurredOn.year == year &&
        (includePending || item.isSettled))) {
      final key = DateTime(
          item.occurredOn.year, item.occurredOn.month, item.occurredOn.day);
      totals.update(key, (value) => value + item.amountInCents,
          ifAbsent: () => item.amountInCents);
    }
    if (includePending) {
      for (final month in List.generate(12, (index) => index + 1)) {
        final lastDay = DateTime(year, month + 1, 0).day;
        for (final item in subscriptions.where((item) =>
            item.isActive &&
            (item.createdAt.year < year ||
                (item.createdAt.year == year &&
                    item.createdAt.month <= month)))) {
          final day = math.min(item.billingDay, lastDay);
          final key = DateTime(year, month, day);
          totals.update(key, (value) => value + item.amountInCents,
              ifAbsent: () => item.amountInCents);
        }
      }
    }
    final maximum = totals.values.isEmpty ? 1 : totals.values.reduce(math.max);
    final weeks = days.length ~/ 7;
    return Panel(
      title: 'Mapa anual de gastos',
      subtitle: includePending
          ? '$year completo · realizados, pendentes e assinaturas previstas'
          : '$year completo · somente despesas efetivadas em cada dia',
      trailing: const StatusPill(label: '365 dias'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 31, bottom: 7),
              child: SizedBox(
                width: weeks * 13,
                height: 14,
                child: _MonthLabels(year: year, gridStart: gridStart),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 31,
                  child: Column(children: [
                    SizedBox(height: 13),
                    _WeekdayLabel('seg'),
                    SizedBox(height: 13),
                    _WeekdayLabel('qua'),
                    SizedBox(height: 13),
                    _WeekdayLabel('sex'),
                  ]),
                ),
                Row(
                  children: List.generate(weeks, (week) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Column(
                        children: List.generate(7, (weekday) {
                          final day = days[week * 7 + weekday];
                          final inYear = day.year == year;
                          final amount = totals[day] ?? 0;
                          final ratio = amount / maximum;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Tooltip(
                              message: !inYear
                                  ? ''
                                  : amount == 0
                                      ? '${shortDate(day)} · sem gastos'
                                      : '${shortDate(day)} · ${hideValues ? 'valor oculto' : FinancialRules.formatBrl(amount)}',
                              child: AnimatedContainer(
                                duration: Duration(
                                    milliseconds:
                                        240 + ((week + weekday) % 7) * 45),
                                curve: Curves.easeOutCubic,
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: inYear
                                      ? _roadmapColor(context, ratio, amount)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2.5),
                                  border: inYear && amount == 0
                                      ? Border.all(
                                          color: Theme.of(context).dividerColor)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Text('Menos',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 7),
              ...[0.0, .18, .42, .7, 1.0].map((ratio) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: ratio == 0
                            ? Theme.of(context).colorScheme.surfaceContainerHigh
                            : _roadmapColor(context, ratio, 1),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  )),
              const SizedBox(width: 3),
              Text('Mais',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ],
        ),
      ),
    );
  }
}

Color _roadmapColor(BuildContext context, double ratio, int amount) {
  if (amount == 0) return Theme.of(context).colorScheme.surfaceContainerHigh;
  final primary = Theme.of(context).colorScheme.primary;
  if (ratio < .2) return primary.withValues(alpha: .2);
  if (ratio < .45) return primary.withValues(alpha: .42);
  if (ratio < .72) return primary.withValues(alpha: .68);
  return primary;
}

class _MonthLabels extends StatelessWidget {
  const _MonthLabels({required this.year, required this.gridStart});

  final int year;
  final DateTime gridStart;

  @override
  Widget build(BuildContext context) => Stack(
        children: List.generate(12, (index) {
          final month = DateTime(year, index + 1);
          final week = month.difference(gridStart).inDays ~/ 7;
          return Positioned(
            left: week * 13,
            child: Text(
              const [
                'jan',
                'fev',
                'mar',
                'abr',
                'mai',
                'jun',
                'jul',
                'ago',
                'set',
                'out',
                'nov',
                'dez'
              ][index],
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }),
      );
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 13,
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

Map<String, int> _byCategory(
    List<TransactionRecord> transactions, TransactionType type) {
  final result = <String, int>{};
  for (final item in transactions.where((item) => item.type == type)) {
    result.update(item.category, (value) => value + item.amountInCents,
        ifAbsent: () => item.amountInCents);
  }
  return result;
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.detail,
    required this.detailColor,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String detail;
  final Color detailColor;

  @override
  Widget build(BuildContext context) {
    final itemWidth = width > 900
        ? (width - 28) / 3
        : width > 620
            ? (width - 14) / 2
            : width;
    return SizedBox(
      width: itemWidth,
      height: 136,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 19),
              const Spacer(),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.5)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 5),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: detailColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data, required this.hideValues});

  final List<_MonthData> data;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final values = <int>[];
    var running = 0;
    for (final item in data) {
      running += item.incomes - item.expenses;
      values.add(running);
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(values.join('-')),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) => CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _LineChartPainter(
                  values: values,
                  lineColor: Theme.of(context).colorScheme.primary,
                  gridColor: Theme.of(context).dividerColor,
                  progress: progress,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data
                .map((item) => Text(item.label,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.progress,
  });

  final List<int> values;
  final Color lineColor;
  final Color gridColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final range = math.max(1, maxValue - minValue);
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = (values[index] - minValue) / range;
      final y = size.height - (normalized * progress * (size.height - 24)) - 12;
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final middle = (previous.dx + current.dx) / 2;
      path.cubicTo(
          middle, previous.dy, middle, current.dy, current.dx, current.dy);
    }
    final area = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: .22),
            lineColor.withValues(alpha: .015),
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (progress > .9) {
      canvas.drawCircle(
        points.last,
        4.5,
        Paint()..color = lineColor,
      );
      canvas.drawCircle(
        points.last,
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.progress != progress;
}

class _IncomeExpensePanel extends StatelessWidget {
  const _IncomeExpensePanel({required this.data, required this.hideValues});

  final List<_MonthData> data;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final maximum = data.fold(
        1, (max, item) => math.max(max, math.max(item.incomes, item.expenses)));
    return Panel(
      title: 'Entradas e saídas',
      subtitle: 'Comparação por mês',
      child: SizedBox(
        height: 190,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(
              data.map((item) => '${item.incomes}:${item.expenses}').join('|')),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 820),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: FractionallySizedBox(
                                  heightFactor:
                                      item.incomes / maximum * progress,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF258A5A),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: FractionallySizedBox(
                                  heightFactor:
                                      item.expenses / maximum * progress,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC94D4D),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(item.label, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ExpenseRanking extends StatelessWidget {
  const _ExpenseRanking({required this.transactions, required this.hideValues});

  final List<TransactionRecord> transactions;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final item in transactions.where(
        (item) => item.type == TransactionType.expense && item.isSettled)) {
      totals.update(item.description, (value) => value + item.amountInCents,
          ifAbsent: () => item.amountInCents);
    }
    final ranking = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Panel(
      title: 'Maiores gastos',
      subtitle: 'Por descrição registrada',
      child: ranking.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sem despesas no período',
              description: 'Registre despesas para gerar comparações.',
            )
          : Column(
              children: ranking.take(4).map((entry) {
                return DataListRow(
                  icon: Icons.arrow_outward_rounded,
                  iconColor: const Color(0xFFC94D4D),
                  title: entry.key,
                  subtitle: 'Despesa acumulada',
                  value: hideValues
                      ? '••••••'
                      : FinancialRules.formatBrl(entry.value),
                  valueColor: const Color(0xFFC94D4D),
                );
              }).toList(),
            ),
    );
  }
}

class _MonthData {
  const _MonthData(
      {required this.label, required this.incomes, required this.expenses});

  final String label;
  final int incomes;
  final int expenses;
}

List<_MonthData> _monthlyDataUntil(
  List<TransactionRecord> transactions,
  DateTime endMonth,
  int months, {
  required bool includePending,
}) {
  return List.generate(months, (index) {
    final date = DateTime(
      endMonth.year,
      endMonth.month - months + index + 1,
    );
    final monthTransactions = _visibleTransactions(
      _transactionsForMonth(transactions, date),
      includePending: includePending,
    );
    final incomes = _typeTotal(monthTransactions, TransactionType.income);
    final expenses = _typeTotal(monthTransactions, TransactionType.expense);
    return _MonthData(
      label: monthName(date.month).substring(0, 3),
      incomes: incomes,
      expenses: expenses,
    );
  });
}

List<TransactionRecord> _transactionsForMonth(
  List<TransactionRecord> transactions,
  DateTime month,
) =>
    transactions
        .where((item) =>
            item.occurredOn.year == month.year &&
            item.occurredOn.month == month.month)
        .toList();

List<TransactionRecord> _visibleTransactions(
  List<TransactionRecord> transactions, {
  required bool includePending,
}) =>
    includePending
        ? transactions
        : transactions.where((item) => item.isSettled).toList();

int _typeTotal(
  Iterable<TransactionRecord> transactions,
  TransactionType type,
) =>
    transactions
        .where((item) => item.type == type)
        .fold(0, (total, item) => total + item.amountInCents);

String _longMonth(DateTime month) =>
    '${monthName(month.month)} de ${month.year}';

String _comparisonLabel(int current, int previous) {
  if (previous == 0) {
    return current == 0
        ? 'Sem movimento nos dois meses'
        : 'Primeiro valor no período';
  }
  final percentage = ((current - previous) / previous.abs() * 100).round();
  if (percentage == 0) return 'Estável em relação ao mês anterior';
  final arrow = percentage > 0 ? '↑' : '↓';
  return '$arrow ${percentage.abs()}% vs. mês anterior';
}

Color _comparisonColor(
  int current,
  int previous, {
  bool lowerIsBetter = false,
}) {
  if (current == previous) return const Color(0xFF6F7378);
  final improved = lowerIsBetter ? current < previous : current > previous;
  return improved ? const Color(0xFF258A5A) : const Color(0xFFC94D4D);
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Mês anterior',
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
            ),
            TextButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.calendar_month_outlined, size: 17),
              label: Text(_longMonth(month)),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              tooltip: 'Próximo mês',
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ],
        ),
      );
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher período'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed:
                      _year > 2000 ? () => setState(() => _year--) : null,
                  tooltip: 'Ano anterior',
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed:
                      _year < 2100 ? () => setState(() => _year++) : null,
                  tooltip: 'Próximo ano',
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = DateTime(_year, index + 1);
                final isSelected = month.year == widget.initialMonth.year &&
                    month.month == widget.initialMonth.month;
                return FilledButton.tonal(
                  onPressed: () => Navigator.pop(context, month),
                  style: FilledButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  child: Text(monthName(month.month).substring(0, 3)),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

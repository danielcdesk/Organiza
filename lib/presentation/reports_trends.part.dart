part of 'reports_page.dart';

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

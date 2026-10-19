part of 'reports_page.dart';

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
      height: 104,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: detailColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

part of 'investments_page.dart';

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({
    required this.current,
    required this.invested,
    required this.profit,
    required this.rate,
    required this.positive,
    required this.hideValues,
  });

  final String current;
  final String invested;
  final String profit;
  final double rate;
  final bool positive;
  final bool hideValues;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Carteira consolidada',
        subtitle: 'Valores informados manualmente · variação acumulada simples',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(current,
                    style: Theme.of(context).textTheme.displaySmall),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: (positive
                          ? const Color(0xFF258A5A)
                          : const Color(0xFFC94D4D))
                      .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hideValues
                      ? '••••••'
                      : '${positive ? '+' : ''}${_percent(rate, decimals: 1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: positive
                        ? const Color(0xFF258A5A)
                        : const Color(0xFFC94D4D),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _Value(label: 'Total aplicado', value: invested)),
                Expanded(
                  child: _Value(
                    label: 'Variação acumulada',
                    value: hideValues
                        ? '••••••'
                        : '${positive ? '+' : ''}${_percent(rate, decimals: 1)}%',
                    color: positive
                        ? const Color(0xFF258A5A)
                        : const Color(0xFFC94D4D),
                  ),
                ),
                Expanded(
                  child: _Value(
                    label: 'Resultado',
                    value: profit,
                    color: positive
                        ? const Color(0xFF258A5A)
                        : const Color(0xFFC94D4D),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _AllocationPanel extends StatelessWidget {
  const _AllocationPanel({required this.positions});

  final List<InvestmentPosition> positions;

  @override
  Widget build(BuildContext context) {
    final totals = <InvestmentType, int>{};
    for (final position in positions) {
      totals.update(
          position.type, (value) => value + position.currentValueInCents,
          ifAbsent: () => position.currentValueInCents);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = totals.values.fold(0, (sum, value) => sum + value);
    final colors = [
      Theme.of(context).colorScheme.primary,
      const Color(0xFF258A5A),
      const Color(0xFF5865D8),
      const Color(0xFFB77A22),
      const Color(0xFF7C5AA6),
      const Color(0xFF6B7280),
    ];
    return Panel(
      title: 'Alocação por classe',
      subtitle: 'Diversificação da carteira',
      child: Row(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (_, progress, __) => SizedBox(
            width: 104,
            height: 104,
            child: CustomPaint(
              painter: _AllocationPainter(
                values: entries.map((item) => item.value).toList(),
                colors: colors,
                progress: progress,
              ),
              child: const Center(
                child: Icon(Icons.pie_chart_outline_rounded, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              final share = total == 0 ? 0 : entry.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(investmentTypeName(entry.key),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Text('${(share * 100).round()}%',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _AllocationPainter extends CustomPainter {
  const _AllocationPainter(
      {required this.values, required this.colors, required this.progress});

  final List<int> values;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total = math.max(1, values.fold(0, (sum, value) => sum + value));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * math.pi * 2 * progress;
      paint.color = colors[index % colors.length];
      canvas.drawArc(rect.deflate(10), start, sweep - .025, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AllocationPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

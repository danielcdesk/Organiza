part of 'reports_page.dart';

class _ExpensePieChart extends StatefulWidget {
  const _ExpensePieChart(
      {required this.title,
      required this.subtitle,
      required this.data,
      required this.hideValues});
  final String title, subtitle;
  final Map<String, int> data;
  final bool hideValues;
  @override
  State<_ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<_ExpensePieChart> {
  int? _selected;
  static const _colors = [
    Color(0xFFE47940),
    Color(0xFF5B72B5),
    Color(0xFF48A889),
    Color(0xFFB178BB),
    Color(0xFFE3B55A),
    Color(0xFFDD7182),
    Color(0xFF65A4BB),
    Color(0xFF8C916B)
  ];

  @override
  Widget build(BuildContext context) {
    final rows = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = rows.fold(0, (sum, item) => sum + item.value);
    if (rows.isEmpty) {
      return Panel(
          title: widget.title,
          subtitle: 'Sem lançamentos categorizados',
          child: const EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Sem dados ainda',
              description:
                  'Categorize suas despesas para ver a distribuição.'));
    }
    final selected =
        _selected != null && _selected! < rows.length ? _selected! : null;
    final focus = selected == null ? total : rows[selected].value;
    return Panel(
        title: widget.title,
        subtitle: widget.subtitle,
        child: Column(children: [
          TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => GestureDetector(
                    onTapDown: (details) {
                      const center = 90.0;
                      final dx = details.localPosition.dx - center;
                      final dy = details.localPosition.dy - center;
                      if (math.sqrt(dx * dx + dy * dy) < 36) {
                        setState(() => _selected = null);
                        return;
                      }
                      final angle =
                          (math.atan2(dy, dx) + math.pi / 2 + 2 * math.pi) %
                              (2 * math.pi);
                      var cursor = 0.0;
                      for (var i = 0; i < rows.length; i++) {
                        cursor += rows[i].value / total * 2 * math.pi;
                        if (angle <= cursor) {
                          setState(() => _selected = i);
                          break;
                        }
                      }
                    },
                    child: SizedBox(
                        width: 180,
                        height: 180,
                        child: CustomPaint(
                            painter: _ExpensePiePainter(
                                values: rows.map((item) => item.value).toList(),
                                colors: _colors,
                                selected: selected,
                                progress: progress),
                            child: Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Text(
                                      selected == null
                                          ? 'Total'
                                          : rows[selected].key,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                      widget.hideValues
                                          ? '••••••'
                                          : FinancialRules.formatBrl(focus),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800))
                                ])))),
                  )),
          const SizedBox(height: 16),
          for (var i = 0; i < rows.length; i++)
            InkWell(
                onTap: () => setState(() => _selected = i),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: _colors[i % _colors.length],
                              shape: BoxShape.circle)),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Text(rows[i].key,
                              style: TextStyle(
                                  fontWeight: selected == i
                                      ? FontWeight.w800
                                      : FontWeight.w500))),
                      Text('${(rows[i].value / total * 100).round()}%'),
                      if (!widget.hideValues) ...[
                        const SizedBox(width: 12),
                        Text(FinancialRules.formatBrl(rows[i].value))
                      ]
                    ]))),
        ]));
  }
}

class _ExpensePiePainter extends CustomPainter {
  const _ExpensePiePainter(
      {required this.values,
      required this.colors,
      required this.selected,
      required this.progress});
  final List<int> values;
  final List<Color> colors;
  final int? selected;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0, (sum, item) => sum + item);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 75);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2 * progress;
      canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected == i ? 26 : 20
            ..color = colors[i % colors.length]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ExpensePiePainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.values != values;
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
        child: LayoutBuilder(builder: (context, constraints) {
          final heading = Row(children: [
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
          ]);
          final selector = SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Realizado')),
              ButtonSegment(value: true, label: Text('Com previsão')),
            ],
            selected: {includePending},
            onSelectionChanged: (value) => onChanged(value.first),
          );
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 12),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal, child: selector),
              ],
            );
          }
          return Row(children: [Expanded(child: heading), selector]);
        }),
      );
}

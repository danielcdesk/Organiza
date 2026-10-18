part of 'overview_widgets.dart';

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

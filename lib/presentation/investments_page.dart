import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/investment_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

String _percent(double rate, {int decimals = 2}) =>
    (rate * 100).toStringAsFixed(decimals).replaceAll('.', ',');

class InvestmentsPage extends StatelessWidget {
  const InvestmentsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final positions = store.investments;
    final invested = InvestmentRules.totalInvested(positions);
    final current = InvestmentRules.currentBalance(positions);
    final profit = InvestmentRules.profit(positions);
    final rate = InvestmentRules.returnRate(positions);
    final positive = profit >= 0;
    String money(int value) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(value);

    return ListView(
      padding: pagePadding(context),
      children: [
        PageHeading(
          eyebrow: 'Patrimônio e alocação',
          title: 'Minha carteira',
          description:
              'Consolide ativos, acompanhe rentabilidade e organize vencimentos de renda fixa.',
          actions: [
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar ativo'),
            ),
          ],
        ),
        const SizedBox(height: 26),
        if (positions.isEmpty)
          Panel(
            title: 'Sua carteira',
            subtitle: 'Sem integração bancária ou cotações em tempo real',
            child: EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Nenhum investimento cadastrado',
              description:
                  'Adicione uma posição com o valor investido e o saldo atual para acompanhar a rentabilidade.',
              actionLabel: 'Adicionar ativo',
              onAction: onAdd,
            ),
          )
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final summary = _PortfolioSummary(
                current: money(current),
                invested: money(invested),
                profit: money(profit),
                rate: rate,
                positive: positive,
                hideValues: hideValues,
              );
              final allocation = _AllocationPanel(positions: positions);
              if (constraints.maxWidth < 600) return summary;
              if (constraints.maxWidth < 920) {
                return Column(
                  children: [summary, const SizedBox(height: 14), allocation],
                );
              }
              return SizedBox(
                height: 252,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: summary),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: allocation),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _InvestmentTelemetry(
            positions: positions,
            current: current,
            profit: profit,
            rate: rate,
            hideValues: hideValues,
          ),
          const SizedBox(height: 14),
          _PositionsPanel(
            positions: positions,
            hideValues: hideValues,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          if (MediaQuery.sizeOf(context).width < 600) ...[
            const SizedBox(height: 14),
            _AllocationPanel(positions: positions),
          ],
          if (positions
              .any((item) => item.type == InvestmentType.fixedIncome)) ...[
            const SizedBox(height: 14),
            _FixedIncomePanel(
              positions: positions
                  .where((item) => item.type == InvestmentType.fixedIncome)
                  .toList(),
              hideValues: hideValues,
            ),
          ],
        ],
      ],
    );
  }
}

class _InvestmentTelemetry extends StatefulWidget {
  const _InvestmentTelemetry({
    required this.positions,
    required this.current,
    required this.profit,
    required this.rate,
    required this.hideValues,
  });

  final List<InvestmentPosition> positions;
  final int current;
  final int profit;
  final double rate;
  final bool hideValues;

  @override
  State<_InvestmentTelemetry> createState() => _InvestmentTelemetryState();
}

class _InvestmentTelemetryState extends State<_InvestmentTelemetry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  var _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (kReleaseMode) {
      _motion.repeat();
    } else {
      _motion.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (disabled != _animationsDisabled) {
      _animationsDisabled = disabled;
      if (disabled) {
        _motion.stop(canceled: false);
      } else if (kReleaseMode) {
        _motion.repeat();
      } else {
        _motion.forward();
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = _chartValues();
    final load = (70 + widget.positions.length * 4 + widget.rate * 100)
        .round()
        .clamp(0, 99);
    final response =
        (0.002 + widget.positions.length * .0003).toStringAsFixed(3);
    final phase = _animationsDisabled ? .45 : _motion.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width > 980
            ? (width - 24) / 3
            : width > 620
                ? (width - 12) / 2
                : width;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _TelemetryCard(
                label: 'LIVE FLOW',
                title: 'Carga da carteira',
                value: '$load%',
                accent: const Color(0xFF27D7A0),
                icon: Icons.monitor_heart_outlined,
                child: CustomPaint(
                  painter: _TelemetryLinePainter(
                    values: values,
                    progress: phase,
                    color: const Color(0xFF27D7A0),
                  ),
                  child: const SizedBox(height: 92),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _TelemetryCard(
                label: 'NÚCLEO SINTÉTICO',
                title: 'Pulso do patrimônio',
                value: widget.hideValues
                    ? '••••••'
                    : FinancialRules.formatBrl(widget.current),
                accent: const Color(0xFF8AA8FF),
                icon: Icons.blur_on_rounded,
                child: CustomPaint(
                  painter: _SyntheticCorePainter(
                    phase: phase,
                    color: const Color(0xFF9BAEFF),
                  ),
                  child: const SizedBox(height: 92),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _TelemetryCard(
                label: 'LATENT RESPONSE',
                title: 'Resposta do mercado',
                value: '${widget.hideValues ? '••••••' : response} ms',
                accent: const Color(0xFFFF4164),
                icon: Icons.hub_outlined,
                child: CustomPaint(
                  painter: _TelemetryBarsPainter(
                    values: values,
                    progress: phase,
                    color: const Color(0xFFFF4164),
                  ),
                  child: const SizedBox(height: 92),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<double> _chartValues() {
    final values = <double>[];
    final positions = widget.positions;
    for (var index = 0; index < 7; index++) {
      if (positions.isEmpty) {
        values.add(.35 + index * .04);
      } else {
        final item = positions[index % positions.length];
        final base = item.currentValueInCents == 0
            ? .2
            : item.currentValueInCents /
                math.max(widget.current.abs(), item.currentValueInCents);
        values.add(
            (.22 + base * .58 + (index.isEven ? .03 : -.02)).clamp(.16, .92));
      }
    }
    return values;
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.label,
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
    required this.child,
  });

  final String label;
  final String title;
  final String value;
  final Color accent;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252A32)
        : const Color(0xFFDBDDE6);
    return Container(
      height: 218,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .07),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TelemetryLinePainter extends CustomPainter {
  const _TelemetryLinePainter({
    required this.values,
    required this.progress,
    required this.color,
  });

  final List<double> values;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final path = Path();
    final fill = Path()..moveTo(0, size.height);
    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final wave = math.sin(progress * math.pi * 2 + index * .8) * 3;
      final y = size.height - values[index] * size.height * .72 + wave;
      if (index == 0) {
        path.moveTo(x, y);
        fill.lineTo(x, y);
      } else {
        final previousX = (index - 1) / (values.length - 1) * size.width;
        final previousY = size.height -
            values[index - 1] * size.height * .72 +
            math.sin(progress * math.pi * 2 + (index - 1) * .8) * 3;
        final controlX = (previousX + x) / 2;
        path.cubicTo(controlX, previousY, controlX, y, x, y);
        fill.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .34), color.withValues(alpha: .02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TelemetryLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

class _TelemetryBarsPainter extends CustomPainter {
  const _TelemetryBarsPainter({
    required this.values,
    required this.progress,
    required this.color,
  });

  final List<double> values;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final count = values.length;
    final gap = size.width / (count * 2.2);
    final barWidth = gap * .9;
    final pulse = .86 + math.sin(progress * math.pi * 2) * .08;
    for (var index = 0; index < count; index++) {
      final height = values[index] * size.height * pulse;
      final x = gap + index * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TelemetryBarsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

class _SyntheticCorePainter extends CustomPainter {
  const _SyntheticCorePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 150; index++) {
      final t = index / 149;
      final y = size.height * (.06 + t * .88);
      final wave = math.sin(t * math.pi * 4 + phase * math.pi * 2) *
          (size.width * (.13 + t * .06));
      final x = center.dx + wave;
      final radius = .7 + math.sin(t * math.pi) * 1.7;
      final opacity = (.14 + math.sin(t * math.pi) * .56).clamp(.08, .7);
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
      if (index % 6 == 0) {
        paint.color = Colors.white.withValues(alpha: opacity * .35);
        canvas.drawCircle(Offset(x - wave * .18, y), radius * .55, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SyntheticCorePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

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

class _PositionsPanel extends StatelessWidget {
  const _PositionsPanel(
      {required this.positions,
      required this.hideValues,
      required this.onEdit,
      required this.onDelete});

  final List<InvestmentPosition> positions;
  final bool hideValues;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Posições',
        subtitle:
            '${positions.length} ativo${positions.length == 1 ? '' : 's'}',
        child: Column(children: [
          for (final position in positions)
            _PositionEntry(
              position: position,
              hideValues: hideValues,
              onEdit: () => onEdit(position.id),
              onDelete: () => onDelete(position.id),
            ),
        ]),
      );
}

class _PositionEntry extends StatelessWidget {
  const _PositionEntry(
      {required this.position,
      required this.hideValues,
      required this.onEdit,
      required this.onDelete});

  final InvestmentPosition position;
  final bool hideValues;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final result =
        position.currentValueInCents - position.investedAmountInCents;
    final positive = result >= 0;
    final resultColor =
        positive ? const Color(0xFF258A5A) : const Color(0xFFC94D4D);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconTile(
              icon: investmentTypeIcon(position.type),
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(position.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(_positionSubtitle(position),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          )),
          PopupMenuButton<String>(
            tooltip: 'Ações de ${position.name}',
            onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar posição')),
              PopupMenuItem(value: 'delete', child: Text('Excluir posição')),
            ],
          ),
        ]),
        const SizedBox(height: 15),
        LayoutBuilder(builder: (context, constraints) {
          final metricWidth = constraints.maxWidth < 600
              ? (constraints.maxWidth - 12) / 2
              : (constraints.maxWidth - 24) / 3;
          return Wrap(spacing: 12, runSpacing: 14, children: [
            _PositionMetric(
              width: metricWidth,
              label: 'Total aplicado',
              value: hideValues
                  ? '••••••'
                  : FinancialRules.formatBrl(position.investedAmountInCents),
            ),
            _PositionMetric(
              width: metricWidth,
              label: 'Valor atual',
              value: hideValues
                  ? '••••••'
                  : FinancialRules.formatBrl(position.currentValueInCents),
            ),
            _PositionMetric(
              width: metricWidth,
              label: 'Variação acumulada',
              value: hideValues
                  ? '••••••'
                  : '${positive ? '+' : ''}${FinancialRules.formatBrl(result)}',
              detail: hideValues
                  ? null
                  : '${positive ? '+' : ''}${_percent(InvestmentRules.positionReturnRate(position))}%',
              color: resultColor,
            ),
          ]);
        }),
        if (position.quotedRateBasisPoints != null) ...[
          const SizedBox(height: 13),
          Text(
              hideValues
                  ? 'Taxa informada: ••••••'
                  : 'Taxa informada: ${_percent(position.quotedRateBasisPoints! / 10000)}% ${position.quotedRatePeriod == InvestmentRatePeriod.monthly ? 'ao mês' : 'ao ano'}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

class _PositionMetric extends StatelessWidget {
  const _PositionMetric(
      {required this.width,
      required this.label,
      required this.value,
      this.detail,
      this.color});

  final double width;
  final String label;
  final String value;
  final String? detail;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        if (detail != null)
          Text(detail!,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]));
}

String _positionSubtitle(InvestmentPosition position) {
  final details = <String>[investmentTypeName(position.type)];
  if (position.fixedIncomeType != null) {
    details.add(fixedIncomeTypeName(position.fixedIncomeType!));
  }
  if (position.institutionName != null) details.add(position.institutionName!);
  if (position.yieldPaymentDay != null) {
    details.add('Rendimento: dia ${position.yieldPaymentDay}');
  }
  return details.join(' · ');
}

class _FixedIncomePanel extends StatelessWidget {
  const _FixedIncomePanel({required this.positions, required this.hideValues});

  final List<InvestmentPosition> positions;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final sorted = List<InvestmentPosition>.of(positions)
      ..sort((a, b) {
        if (a.maturityDate == null) return 1;
        if (b.maturityDate == null) return -1;
        return a.maturityDate!.compareTo(b.maturityDate!);
      });
    return Panel(
      title: 'Renda fixa',
      subtitle: 'Tipos, emissores e próximos vencimentos',
      trailing: StatusPill(label: '${positions.length} posições'),
      child: Column(
        children: sorted.map((position) {
          final maturity = position.maturityDate;
          return DataListRow(
            icon: Icons.lock_clock_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            title: position.name,
            subtitle: [
              fixedIncomeTypeName(
                  position.fixedIncomeType ?? FixedIncomeType.other),
              position.institutionName ?? 'Emissor não informado',
              maturity == null
                  ? 'Sem vencimento informado'
                  : 'Vence em ${shortDate(maturity)}',
              if (position.quotedRateBasisPoints != null)
                hideValues
                    ? 'Taxa informada ••••••'
                    : '${_percent(position.quotedRateBasisPoints! / 10000)}% ${position.quotedRatePeriod == InvestmentRatePeriod.monthly ? 'ao mês' : 'ao ano'}',
              if (position.yieldPaymentDay != null)
                'Crédito dia ${position.yieldPaymentDay}',
            ].join(' · '),
            value: hideValues
                ? '••••••'
                : FinancialRules.formatBrl(position.currentValueInCents),
          );
        }).toList(),
      ),
    );
  }
}

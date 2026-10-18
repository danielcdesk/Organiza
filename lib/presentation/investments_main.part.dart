part of 'investments_page.dart';

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

part of 'investments_page.dart';

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

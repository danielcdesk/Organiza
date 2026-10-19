part of 'shared_widgets.dart';

class DataListRow extends StatelessWidget {
  const DataListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.leading,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 460) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    leading ?? IconTile(icon: icon, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(value,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: valueColor)),
                        ])),
                    if (trailing != null) trailing!,
                  ]),
                  const SizedBox(height: 7),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ]);
          }
          return Row(
            children: [
              leading ?? IconTile(icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style:
                    TextStyle(fontWeight: FontWeight.w700, color: valueColor),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          );
        }),
      );
}

class TransactionListRow extends StatelessWidget {
  const TransactionListRow({
    super.key,
    required this.item,
    required this.hideValues,
    this.trailing,
    this.account,
  });

  final TransactionRecord item;
  final Account? account;
  final bool hideValues;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final income = item.type == TransactionType.income;
    final transfer = item.type == TransactionType.transfer;
    final color = income
        ? Theme.of(context).colorScheme.secondary
        : transfer
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;
    final schedule = switch (item.scheduleType) {
      TransactionScheduleType.single => 'Único',
      TransactionScheduleType.recurring => 'Recorrente',
      TransactionScheduleType.installment =>
        'Parcela ${item.installmentNumber}/${item.installmentCount}',
    };
    return DataListRow(
      leading: transfer && account != null
          ? InstitutionMark(
              institution: account!.institution,
              customIconKey: account!.customIconKey)
          : null,
      icon: transfer
          ? Icons.swap_horiz_rounded
          : financeCategoryIcon(item.category, item.subcategory),
      iconColor: color,
      title: item.description.isEmpty ? item.category : item.description,
      subtitle:
          '${account == null ? '' : '${account!.name} · '}${item.category} / ${item.subcategory} · $schedule · ${item.isSettled ? (income ? 'Recebido' : 'Pago') : 'Pendente'} · ${shortDate(item.occurredOn)}',
      value:
          hideValues ? '••••••' : FinancialRules.formatBrl(item.amountInCents),
      valueColor: color,
      trailing: trailing,
    );
  }
}

enum StatusKind { confirmed, pending, overdue, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.kind});

  final String label;
  final StatusKind? kind;

  StatusKind get _effectiveKind =>
      kind ??
      switch (label.toLowerCase()) {
        'confirmado' || 'concluída' => StatusKind.confirmed,
        'pendente' => StatusKind.pending,
        'atrasado' || 'atrasada' => StatusKind.overdue,
        _ => StatusKind.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = OrganizaDesignTokens.of(context);
    final color = switch (_effectiveKind) {
      StatusKind.confirmed => tokens.positive,
      StatusKind.pending => tokens.warning,
      StatusKind.overdue => scheme.error,
      StatusKind.neutral => tokens.neutral,
    };
    final icon = switch (_effectiveKind) {
      StatusKind.confirmed => Icons.check_circle_outline_rounded,
      StatusKind.pending => Icons.schedule_rounded,
      StatusKind.overdue => Icons.warning_amber_rounded,
      StatusKind.neutral => Icons.info_outline_rounded,
    };
    return Semantics(
      label: label,
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: tokens.spaceLg - tokens.spaceSm, color: color),
          SizedBox(width: tokens.spaceSm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class HeroAmount extends StatelessWidget {
  const HeroAmount({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.hideValues = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final hidden = hideValues ? 'Valores ocultos' : value;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $hidden${subtitle == null ? '' : '. $subtitle'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.titleMedium),
          SizedBox(height: OrganizaDesignTokens.of(context).spaceSm),
          Text(
            hideValues ? '••••••' : value,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: OrganizaDesignTokens.of(context).spaceXs),
            Text(subtitle!, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

enum DeltaTone { positive, negative, neutral }

class DeltaText extends StatelessWidget {
  const DeltaText({
    super.key,
    required this.value,
    required this.semanticValue,
    required this.tone,
    this.label,
  });

  final String value;
  final String semanticValue;
  final DeltaTone tone;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      DeltaTone.positive => tokens.positive,
      DeltaTone.negative => scheme.error,
      DeltaTone.neutral => tokens.neutral,
    };
    final icon = switch (tone) {
      DeltaTone.positive => Icons.trending_up_rounded,
      DeltaTone.negative => Icons.trending_down_rounded,
      DeltaTone.neutral => Icons.trending_flat_rounded,
    };
    return Semantics(
      label: '${label == null ? '' : '$label: '}$semanticValue',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          SizedBox(width: tokens.spaceXs),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class SegmentedRange<T> extends StatelessWidget {
  const SegmentedRange({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label = 'Período',
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Semantics(
      container: true,
      label: label,
      child: Wrap(
        spacing: tokens.spaceXs,
        runSpacing: tokens.spaceXs,
        children: [
          for (final option in options)
            Semantics(
              selected: option == selected,
              button: true,
              label:
                  '${option.toString()}${option == selected ? ', selecionado' : ''}',
              child: ChoiceChip(
                label: Text(option.toString()),
                selected: option == selected,
                onSelected: (_) => onChanged(option),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceSm,
                  vertical: tokens.spaceXs,
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
        ],
      ),
    );
  }
}

enum QuickActionTone { neutral, brand, positive }

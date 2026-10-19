part of 'dashboard_page.dart';

class _MonthToolbar extends StatelessWidget {
  const _MonthToolbar({
    required this.month,
    required this.compact,
    required this.hideValues,
    required this.onToggleValues,
    this.onNewTransaction,
  });

  final DateTime month;
  final bool compact;
  final bool hideValues;
  final VoidCallback? onToggleValues;
  final VoidCallback? onNewTransaction;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final label = '${sentenceCase(monthName(month.month))} de ${month.year}';
    final monthLabel = Semantics(
      label: 'Mês atual: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.headlineSmall),
          ),
        ],
      ),
    );
    if (compact) {
      return Row(
        children: [
          Expanded(child: monthLabel),
          SizedBox(width: tokens.spaceSm),
          _visibilityButton(),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mês atual',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              SizedBox(height: tokens.spaceXs),
              monthLabel,
            ],
          ),
        ),
        _visibilityButton(outlined: true),
        if (onNewTransaction != null) ...[
          SizedBox(width: tokens.spaceMd),
          FilledButton.icon(
            key: const Key('desktop-new-transaction'),
            onPressed: onNewTransaction,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova transação'),
          ),
        ],
      ],
    );
  }

  Widget _visibilityButton({bool outlined = false}) =>
      Builder(builder: (context) {
        final tokens = OrganizaDesignTokens.of(context);
        return Container(
          decoration: outlined
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                )
              : null,
          child: IconButton(
            tooltip: hideValues ? 'Mostrar valores' : 'Ocultar valores',
            onPressed: onToggleValues,
            constraints: BoxConstraints(
              minWidth: tokens.minTapTarget,
              minHeight: tokens.minTapTarget,
            ),
            icon: Icon(
              hideValues
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        );
      });
}

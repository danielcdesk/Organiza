part of 'dashboard_page.dart';

class _MonthToolbar extends StatelessWidget {
  const _MonthToolbar({
    required this.month,
    required this.compact,
    required this.hideValues,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleValues,
    this.onNewTransaction,
  });

  final DateTime month;
  final bool compact;
  final bool hideValues;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToggleValues;
  final VoidCallback? onNewTransaction;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final label = '${sentenceCase(monthName(month.month))} de ${month.year}';
    if (!compact) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visão do período',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(label, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _monthButton(
                  tooltip: 'Mês anterior',
                  onPressed: onPrevious,
                  icon: Icons.chevron_left_rounded,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
                  child: Text(
                    sentenceCase(monthName(month.month)),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _monthButton(
                  tooltip: 'Próximo mês',
                  onPressed: onNext,
                  icon: Icons.chevron_right_rounded,
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceSm),
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
    if (largeText) {
      return Wrap(
        spacing: tokens.spaceSm,
        runSpacing: tokens.spaceSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          _monthButton(
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
            icon: Icons.chevron_left_rounded,
            outlined: true,
          ),
          _monthButton(
            tooltip: 'Próximo mês',
            onPressed: onNext,
            icon: Icons.chevron_right_rounded,
            outlined: true,
          ),
          _visibilityButton(outlined: true),
        ],
      );
    }
    return Row(
      children: [
        _monthButton(
          tooltip: 'Mês anterior',
          onPressed: onPrevious,
          icon: Icons.chevron_left_rounded,
          outlined: true,
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Semantics(
            label: 'Mês selecionado: $label',
            child: Container(
              constraints: BoxConstraints(minHeight: tokens.minTapTarget),
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  SizedBox(width: tokens.spaceSm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        _monthButton(
          tooltip: 'Próximo mês',
          onPressed: onNext,
          icon: Icons.chevron_right_rounded,
          outlined: true,
        ),
        SizedBox(width: tokens.spaceXs),
        _visibilityButton(),
      ],
    );
  }

  Widget _monthButton({
    required String tooltip,
    required VoidCallback onPressed,
    required IconData icon,
    bool outlined = false,
  }) =>
      Builder(builder: (context) {
        final tokens = OrganizaDesignTokens.of(context);
        return Container(
          decoration: outlined
              ? BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  shape: BoxShape.circle,
                )
              : null,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            constraints: BoxConstraints(
              minWidth: tokens.minTapTarget,
              minHeight: tokens.minTapTarget,
            ),
            icon: Icon(icon),
          ),
        );
      });

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

part of 'dashboard_page.dart';

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.available,
    required this.current,
    required this.hideValues,
    this.hint,
  });

  final String available;
  final String current;
  final bool hideValues;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final theme = Theme.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final semanticAvailable = hideValues ? 'valor oculto' : available;
    final semanticCurrent = hideValues ? 'valor oculto' : current;
    return Semantics(
      container: true,
      label:
          'Disponível no mês: $semanticAvailable. Saldo atual: $semanticCurrent${hint == null ? '' : '. $hint'}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (largeText) ...[
              _HeroWalletIcon(tokens: tokens, theme: theme),
              SizedBox(height: tokens.spaceMd),
              Text('Disponível no mês', style: theme.textTheme.titleMedium),
              SizedBox(height: tokens.spaceSm),
              _HeroValue(value: available),
            ] else
              Row(
                children: [
                  _HeroWalletIcon(tokens: tokens, theme: theme),
                  SizedBox(width: tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disponível no mês',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: tokens.spaceXs),
                        _HeroValue(value: available),
                      ],
                    ),
                  ),
                ],
              ),
            SizedBox(height: tokens.spaceMd),
            Divider(
              height: tokens.hairlineThickness,
              thickness: tokens.hairlineThickness,
            ),
            SizedBox(height: tokens.spaceMd),
            if (hint != null)
              Text(hint!, style: theme.textTheme.bodyMedium)
            else if (largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo atual', style: theme.textTheme.bodySmall),
                  SizedBox(height: tokens.spaceXs),
                  Text(current, style: theme.textTheme.titleMedium),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child:
                        Text('Saldo atual', style: theme.textTheme.bodySmall),
                  ),
                  Text(current, style: theme.textTheme.titleMedium),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroWalletIcon extends StatelessWidget {
  const _HeroWalletIcon({required this.tokens, required this.theme});

  final OrganizaDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
        width: tokens.quickActionDiameter,
        height: tokens.quickActionDiameter,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: .16),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.account_balance_wallet_outlined,
          color: theme.colorScheme.primary,
        ),
      );
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Text(
        value,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

class _HeroSurface extends StatelessWidget {
  const _HeroSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroSurfaceStrong, tokens.heroSurface],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .28),
          width: tokens.hairlineThickness,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: child,
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.onDismiss, required this.onAction});

  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Faça sua primeira conta',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spaceXs),
              const Text(
                'Assim você acompanha seu saldo desde o primeiro lançamento.',
              ),
              Wrap(
                spacing: tokens.spaceSm,
                children: [
                  TextButton(
                    onPressed: onAction,
                    child: const Text('Criar conta'),
                  ),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dispensar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({
    required this.onNewAccount,
    required this.onNewTransaction,
  });

  final VoidCallback onNewAccount;
  final VoidCallback onNewTransaction;

  @override
  Widget build(BuildContext context) => HairlineSection(
        title: 'Comece pelo básico',
        child: Wrap(
          spacing: OrganizaDesignTokens.of(context).spaceSm,
          runSpacing: OrganizaDesignTokens.of(context).spaceSm,
          children: [
            FilledButton.icon(
              onPressed: onNewAccount,
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Criar primeira conta'),
            ),
            OutlinedButton.icon(
              onPressed: onNewTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar primeiro lançamento'),
            ),
          ],
        ),
      );
}

class _OverdueNotice extends StatelessWidget {
  const _OverdueNotice({
    required this.count,
    required this.totalInCents,
    required this.hideValues,
    required this.onPressed,
  });

  final int count;
  final int totalInCents;
  final bool hideValues;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final label = count == 1 ? '1 conta atrasada' : '$count contas atrasadas';
    final value =
        hideValues ? '••••••' : FinancialRules.formatBrl(totalInCents);
    return Semantics(
      button: true,
      label: '$label, total $value. Ver lançamentos',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Text(
                  '$label · $value',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

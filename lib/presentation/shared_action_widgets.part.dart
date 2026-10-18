part of 'shared_widgets.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.tone = QuickActionTone.neutral,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final QuickActionTone tone;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    Color actionColor(QuickActionTone tone) => switch (tone) {
          QuickActionTone.neutral =>
            Theme.of(context).colorScheme.onSurfaceVariant,
          QuickActionTone.brand => Theme.of(context).colorScheme.primary,
          QuickActionTone.positive => tokens.positive,
        };
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final itemWidth =
          (availableWidth - (tokens.spaceSm * 3)) / 4 - tokens.spaceXs * 2;
      var labelHeight = 0.0;
      for (final action in actions) {
        final painter = TextPainter(
          text: TextSpan(text: action.label, style: labelStyle),
          textAlign: TextAlign.center,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 2,
        )..layout(maxWidth: itemWidth);
        if (painter.height > labelHeight) labelHeight = painter.height;
      }
      final itemExtent = tokens.spaceXs * 2 +
          tokens.quickActionDiameter +
          tokens.spaceSm +
          labelHeight;
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: tokens.spaceSm,
        crossAxisSpacing: tokens.spaceSm,
        mainAxisExtent: itemExtent,
        children: [
          for (final action in actions)
            Semantics(
              button: true,
              label: action.semanticLabel ?? action.label,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: tokens.minTapTarget),
                child: InkWell(
                  key: ValueKey('quick-action-${action.label}'),
                  onTap: action.onPressed,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: tokens.quickActionDiameter,
                          height: tokens.quickActionDiameter,
                          decoration: BoxDecoration(
                            color:
                                actionColor(action.tone).withValues(alpha: .12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: actionColor(action.tone)
                                  .withValues(alpha: .32),
                            ),
                          ),
                          child: Icon(
                            action.icon,
                            color: actionColor(action.tone),
                          ),
                        ),
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class HairlineSection extends StatelessWidget {
  const HairlineSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        Divider(
            height: tokens.hairlineThickness,
            thickness: tokens.hairlineThickness),
        SizedBox(height: tokens.spaceSm),
        child,
      ],
    );
  }
}

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.primaryAction = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final bool primaryAction;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
  }) : assert(items.length <= 5);

  final List<AppBottomNavItem> items;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: tokens.navHeight,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected:
                        !items[index].primaryAction && index == currentIndex,
                    label:
                        '${items[index].semanticLabel ?? items[index].label}${!items[index].primaryAction && index == currentIndex ? ', selecionado' : ''}',
                    child: InkWell(
                      key: items[index].primaryAction
                          ? const ValueKey('bottom-nav-primary-action')
                          : null,
                      onTap: items[index].onPressed,
                      child: items[index].primaryAction
                          ? _PrimaryBottomAction(item: items[index])
                          : Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  minWidth: tokens.minTapTarget,
                                  minHeight: tokens.minTapTarget,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: tokens.spaceSm,
                                  vertical: tokens.spaceXs,
                                ),
                                decoration: index == currentIndex
                                    ? BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: .16),
                                        borderRadius: BorderRadius.circular(
                                            tokens.radiusLg),
                                      )
                                    : null,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(items[index].icon),
                                    Text(
                                      items[index].label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBottomAction extends StatelessWidget {
  const _PrimaryBottomAction({required this.item});

  final AppBottomNavItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: item.semanticLabel ?? item.label,
      child: Transform.translate(
        offset: Offset(0, -tokens.spaceXs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tokens.quickActionDiameter,
              height: tokens.quickActionDiameter,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.surface,
                  width: tokens.hairlineThickness * 3,
                ),
              ),
              child: Icon(item.icon, color: scheme.onPrimary),
            ),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String monthName(int month) => const [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ][month - 1];

String sentenceCase(String value) => value.isEmpty
    ? value
    : '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';

String institutionName(AccountInstitution institution, [String? customName]) =>
    switch (institution) {
      AccountInstitution.generic => 'Banco',
      AccountInstitution.nubank => 'Nubank',
      AccountInstitution.inter => 'Inter',
      AccountInstitution.caixa => 'Caixa',
      AccountInstitution.itau => 'Itaú',
      AccountInstitution.bradesco => 'Bradesco',
      AccountInstitution.santander => 'Santander',
      AccountInstitution.bancoDoBrasil => 'Banco do Brasil',
      AccountInstitution.bancoPan => 'Banco PAN',
      AccountInstitution.picpay => 'PicPay',
      AccountInstitution.mercadoPago => 'Mercado Pago',
      AccountInstitution.neon => 'Neon',
      AccountInstitution.original => 'Banco Original',
      AccountInstitution.safra => 'Safra',
      AccountInstitution.sicredi => 'Sicredi',
      AccountInstitution.sicoob => 'Sicoob',
      AccountInstitution.bv => 'Banco BV',
      AccountInstitution.xp => 'XP',
      AccountInstitution.custom => customName?.trim().isNotEmpty == true
          ? customName!.trim()
          : 'Banco personalizado',
    };

String institutionMark(AccountInstitution institution) => switch (institution) {
      AccountInstitution.nubank => 'nu',
      AccountInstitution.inter => 'in',
      AccountInstitution.caixa => 'X',
      AccountInstitution.itau => 'itaú',
      AccountInstitution.bradesco => 'bra',
      AccountInstitution.santander => 'san',
      AccountInstitution.bancoDoBrasil => 'bb',
      AccountInstitution.bancoPan => 'pan',
      AccountInstitution.picpay => 'pay',
      AccountInstitution.mercadoPago => 'mp',
      AccountInstitution.neon => 'n',
      AccountInstitution.original => 'o',
      AccountInstitution.safra => 'saf',
      AccountInstitution.sicredi => 'sic',
      AccountInstitution.sicoob => 'sco',
      AccountInstitution.bv => 'bv',
      AccountInstitution.xp => 'xp',
      AccountInstitution.custom => '',
      AccountInstitution.generic => '',
    };

Color institutionColor(AccountInstitution institution, BuildContext context) =>
    switch (institution) {
      AccountInstitution.nubank => const Color(0xFF820AD1),
      AccountInstitution.inter => const Color(0xFFFF7A00),
      AccountInstitution.caixa => const Color(0xFF0066B3),
      AccountInstitution.itau => const Color(0xFFEC7000),
      AccountInstitution.bradesco => const Color(0xFFCC092F),
      AccountInstitution.santander => const Color(0xFFEC0000),
      AccountInstitution.bancoDoBrasil => const Color(0xFFFFDF00),
      AccountInstitution.bancoPan => const Color(0xFF00AEEF),
      AccountInstitution.picpay => const Color(0xFF21C25E),
      AccountInstitution.mercadoPago => const Color(0xFF009EE3),
      AccountInstitution.neon => const Color(0xFF00D7FF),
      AccountInstitution.original => const Color(0xFF00AEEF),
      AccountInstitution.safra => const Color(0xFFB28A43),
      AccountInstitution.sicredi => const Color(0xFF3DAE2B),
      AccountInstitution.sicoob => const Color(0xFF007E3A),
      AccountInstitution.bv => const Color(0xFF24449C),
      AccountInstitution.xp => const Color(0xFF111111),
      AccountInstitution.custom => OrganizaTheme.orange,
      AccountInstitution.generic => Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: .72),
    };

String institutionAssetPath(AccountInstitution institution) =>
    switch (institution) {
      AccountInstitution.nubank => 'assets/banks/nubank.png',
      AccountInstitution.inter => 'assets/banks/inter.png',
      AccountInstitution.caixa => 'assets/banks/caixa.png',
      AccountInstitution.itau => 'assets/banks/itau.png',
      AccountInstitution.bradesco => 'assets/banks/bradesco.png',
      AccountInstitution.santander => 'assets/banks/santander.png',
      AccountInstitution.bancoDoBrasil => 'assets/banks/banco-do-brasil.png',
      AccountInstitution.bancoPan => '',
      AccountInstitution.picpay => '',
      AccountInstitution.mercadoPago => '',
      AccountInstitution.neon => '',
      AccountInstitution.original => '',
      AccountInstitution.safra => '',
      AccountInstitution.sicredi => '',
      AccountInstitution.sicoob => '',
      AccountInstitution.bv => '',
      AccountInstitution.xp => '',
      AccountInstitution.custom => '',
      AccountInstitution.generic => '',
    };

IconData _customInstitutionIcon(String? key) => switch (key) {
      'wallet' => Icons.account_balance_wallet_rounded,
      'bank' => Icons.account_balance_rounded,
      'payments' => Icons.payments_rounded,
      'savings' => Icons.savings_rounded,
      'business' => Icons.business_rounded,
      'store' => Icons.storefront_rounded,
      'phone' => Icons.phone_android_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };

String investmentTypeName(InvestmentType type) => switch (type) {
      InvestmentType.fixedIncome => 'Renda fixa',
      InvestmentType.stock => 'Ações',
      InvestmentType.fund => 'Fundos',
      InvestmentType.etf => 'ETF',
      InvestmentType.crypto => 'Cripto',
      InvestmentType.other => 'Outro',
    };

IconData investmentTypeIcon(InvestmentType type) => switch (type) {
      InvestmentType.fixedIncome => Icons.lock_clock_outlined,
      InvestmentType.stock => Icons.candlestick_chart_outlined,
      InvestmentType.fund => Icons.pie_chart_outline_rounded,
      InvestmentType.etf => Icons.stacked_line_chart_rounded,
      InvestmentType.crypto => Icons.currency_bitcoin_rounded,
      InvestmentType.other => Icons.savings_outlined,
    };

String fixedIncomeTypeName(FixedIncomeType type) => switch (type) {
      FixedIncomeType.cdb => 'CDB',
      FixedIncomeType.lci => 'LCI',
      FixedIncomeType.lca => 'LCA',
      FixedIncomeType.treasurySelic => 'Tesouro Selic',
      FixedIncomeType.treasuryIpca => 'Tesouro IPCA+',
      FixedIncomeType.treasuryFixed => 'Tesouro Prefixado',
      FixedIncomeType.debenture => 'Debênture',
      FixedIncomeType.cri => 'CRI',
      FixedIncomeType.cra => 'CRA',
      FixedIncomeType.savings => 'Poupança',
      FixedIncomeType.other => 'Outra renda fixa',
    };

String brandName(CardBrand brand) => switch (brand) {
      CardBrand.visa => 'Visa',
      CardBrand.mastercard => 'Mastercard',
      CardBrand.elo => 'Elo',
      CardBrand.amex => 'American Express',
      CardBrand.other => 'Outra',
    };

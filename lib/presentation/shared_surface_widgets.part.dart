part of 'shared_widgets.dart';

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 20,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text(
                        eyebrow,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                title,
                style: compact
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: compact ? 12.5 : null,
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: 9, runSpacing: 9, children: actions),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 15 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        )),
                  ],
                ],
              );
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (trailing != null) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: trailing!,
                      ),
                    ],
                  ],
                );
              }
              return Row(children: [
                Expanded(child: heading),
                if (trailing != null)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing!,
                    ),
                  ),
              ]);
            }),
            const SizedBox(height: 17),
            child,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                IconTile(icon: icon),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      );
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: effectiveColor),
    );
  }
}

class InstitutionMark extends StatelessWidget {
  const InstitutionMark({
    super.key,
    required this.institution,
    this.size = 36,
    this.customIconKey,
  });

  final AccountInstitution institution;
  final double size;
  final String? customIconKey;

  @override
  Widget build(BuildContext context) {
    final background = institutionColor(institution, context);
    if (institution == AccountInstitution.generic) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * .31),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(
          Icons.account_balance_rounded,
          size: size * .48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (institution == AccountInstitution.custom) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * .31),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: Icon(_customInstitutionIcon(customIconKey),
            size: size * .48, color: Colors.white),
      );
    }
    final assetPath = institutionAssetPath(institution);
    if (assetPath.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * .31),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: _InstitutionGlyph(institution: institution, size: size),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .31),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: .2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .28),
        child: Image.asset(
          institutionAssetPath(institution),
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              _InstitutionGlyph(institution: institution, size: size),
        ),
      ),
    );
  }
}

class _InstitutionGlyph extends StatelessWidget {
  const _InstitutionGlyph({required this.institution, required this.size});

  final AccountInstitution institution;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size * .3,
      fontWeight: FontWeight.w900,
      letterSpacing: -.7,
      height: 1,
    );
    return switch (institution) {
      AccountInstitution.nubank => Text('nu',
          style: textStyle.copyWith(
              fontSize: size * .34, fontStyle: FontStyle.italic)),
      AccountInstitution.inter => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * .45,
              height: size * .45,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: size * .055),
                shape: BoxShape.circle,
              ),
            ),
            Text('i', style: textStyle.copyWith(fontSize: size * .3)),
          ],
        ),
      AccountInstitution.caixa => Icon(Icons.close_rounded,
          color: const Color(0xFFFFB000), size: size * .57),
      AccountInstitution.itau => Text('itaú',
          style: textStyle.copyWith(fontSize: size * .22, letterSpacing: -1)),
      AccountInstitution.bradesco =>
        Icon(Icons.water_rounded, color: Colors.white, size: size * .5),
      AccountInstitution.santander => Icon(Icons.local_fire_department_rounded,
          color: Colors.white, size: size * .52),
      AccountInstitution.bancoDoBrasil => Text('BB',
          style: textStyle.copyWith(
              color: const Color(0xFF173E8F), fontSize: size * .26)),
      AccountInstitution.bancoPan =>
        Text('pan', style: textStyle.copyWith(fontSize: size * .28)),
      AccountInstitution.picpay => Icon(Icons.account_balance_wallet_rounded,
          color: Colors.white, size: size * .5),
      AccountInstitution.mercadoPago =>
        Icon(Icons.shopping_bag_rounded, color: Colors.white, size: size * .48),
      AccountInstitution.neon => Text('n', style: textStyle),
      AccountInstitution.original => Text('o', style: textStyle),
      AccountInstitution.safra =>
        Text('safra', style: textStyle.copyWith(fontSize: size * .22)),
      AccountInstitution.sicredi =>
        Icon(Icons.eco_rounded, color: Colors.white, size: size * .52),
      AccountInstitution.sicoob => Icon(Icons.account_balance_rounded,
          color: Colors.white, size: size * .5),
      AccountInstitution.bv => Text('bv', style: textStyle),
      AccountInstitution.xp => Text('xp', style: textStyle),
      AccountInstitution.custom => const SizedBox.shrink(),
      AccountInstitution.generic => const SizedBox.shrink(),
    };
  }
}

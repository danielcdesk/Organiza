import 'package:flutter/material.dart';

import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'organiza_theme.dart';

EdgeInsets pagePadding(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600
        ? const EdgeInsets.fromLTRB(14, 14, 14, 26)
        : const EdgeInsets.fromLTRB(34, 30, 34, 44);

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
      leading: account == null
          ? null
          : InstitutionMark(
              institution: account!.institution,
              customIconKey: account?.customIconKey),
      icon: income
          ? Icons.south_west_rounded
          : transfer
              ? Icons.swap_horiz_rounded
              : Icons.north_east_rounded,
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
    Color actionColor(QuickActionTone tone) => switch (tone) {
          QuickActionTone.neutral =>
            Theme.of(context).colorScheme.onSurfaceVariant,
          QuickActionTone.brand => Theme.of(context).colorScheme.primary,
          QuickActionTone.positive => tokens.positive,
        };
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: tokens.spaceSm,
      crossAxisSpacing: tokens.spaceSm,
      mainAxisExtent: tokens.quickActionDiameter + tokens.spaceLg,
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
                            color:
                                actionColor(action.tone).withValues(alpha: .32),
                          ),
                        ),
                        child: Icon(
                          action.icon,
                          color: actionColor(action.tone),
                        ),
                      ),
                      SizedBox(height: tokens.spaceSm),
                      Flexible(
                        child: Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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

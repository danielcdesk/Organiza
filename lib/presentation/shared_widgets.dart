import 'package:flutter/material.dart';

import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'organiza_theme.dart';

EdgeInsets pagePadding(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600
        ? const EdgeInsets.fromLTRB(16, 18, 16, 32)
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
  Widget build(BuildContext context) => Wrap(
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
                      color: OrganizaTheme.orange.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: OrganizaTheme.orange,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 9, runSpacing: 9, children: actions),
        ],
      );
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
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                  if (trailing != null) trailing!,
                ]);
              }),
              const SizedBox(height: 17),
              child,
            ],
          ),
        ),
      );
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
  });

  final AccountInstitution institution;
  final double size;

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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ? OrganizaTheme.green
        : transfer
            ? Theme.of(context).colorScheme.primary
            : OrganizaTheme.red;
    final schedule = switch (item.scheduleType) {
      TransactionScheduleType.single => 'Único',
      TransactionScheduleType.recurring => 'Recorrente',
      TransactionScheduleType.installment =>
        'Parcela ${item.installmentNumber}/${item.installmentCount}',
    };
    return DataListRow(
      leading: account == null
          ? null
          : InstitutionMark(institution: account!.institution),
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

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
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
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
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

String institutionName(AccountInstitution institution) => switch (institution) {
      AccountInstitution.generic => 'Banco',
      AccountInstitution.nubank => 'Nubank',
      AccountInstitution.inter => 'Inter',
      AccountInstitution.caixa => 'Caixa',
      AccountInstitution.itau => 'Itaú',
      AccountInstitution.bradesco => 'Bradesco',
      AccountInstitution.santander => 'Santander',
      AccountInstitution.bancoDoBrasil => 'Banco do Brasil',
    };

String institutionMark(AccountInstitution institution) => switch (institution) {
      AccountInstitution.nubank => 'nu',
      AccountInstitution.inter => 'in',
      AccountInstitution.caixa => 'X',
      AccountInstitution.itau => 'itaú',
      AccountInstitution.bradesco => 'bra',
      AccountInstitution.santander => 'san',
      AccountInstitution.bancoDoBrasil => 'bb',
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
      AccountInstitution.generic => '',
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

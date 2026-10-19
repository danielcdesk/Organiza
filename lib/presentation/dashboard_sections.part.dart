part of 'dashboard_page.dart';

class _EssentialsSection extends StatelessWidget {
  const _EssentialsSection({
    required this.invoice,
    required this.subscription,
    required this.budget,
    required this.cardStyle,
    required this.hideValues,
    required this.onOpenCards,
    required this.onOpenSubscriptions,
    required this.onOpenBudgets,
  });

  final _NextInvoice? invoice;
  final _NextSubscription? subscription;
  final _BudgetSummary? budget;
  final bool cardStyle;
  final bool hideValues;
  final VoidCallback onOpenCards;
  final VoidCallback onOpenSubscriptions;
  final VoidCallback onOpenBudgets;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final rows = Column(
      children: [
        _EssentialRow(
          icon: Icons.credit_card_outlined,
          label: 'Próxima fatura',
          description: invoice == null
              ? 'Adicione um cartão para acompanhar'
              : '${invoice!.card.name} · vence em ${shortDate(invoice!.dueDate)}',
          value: invoice == null
              ? null
              : _visibleMoney(invoice!.amountInCents, hideValues),
          cardStyle: cardStyle,
          onPressed: onOpenCards,
        ),
        _EssentialRow(
          icon: Icons.autorenew_rounded,
          label: 'Próxima assinatura',
          description: subscription == null
              ? 'Nenhuma assinatura ativa'
              : '${subscription!.subscription.name} · ${shortDate(subscription!.billingDate)}',
          value: subscription == null
              ? null
              : _visibleMoney(
                  subscription!.subscription.amountInCents,
                  hideValues,
                ),
          cardStyle: cardStyle,
          onPressed: onOpenSubscriptions,
        ),
        _EssentialRow(
          icon: Icons.donut_small_rounded,
          label: 'Orçamento do mês',
          description: budget == null
              ? 'Defina limites para saber quanto ainda pode gastar'
              : '${budget!.usedPercent}% do limite utilizado',
          value: budget == null
              ? null
              : 'Restam ${_visibleMoney(budget!.remainingInCents, hideValues)}',
          progress: budget?.progress,
          cardStyle: cardStyle,
          onPressed: onOpenBudgets,
        ),
      ],
    );
    if (!cardStyle) {
      return HairlineSection(title: 'Próximos passos', child: rows);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximos passos', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: tokens.spaceMd),
        rows,
      ],
    );
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.cardStyle,
    required this.onPressed,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String description;
  final String? value;
  final bool cardStyle;
  final VoidCallback onPressed;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: tokens.spaceXs),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        if (largeText && value != null) ...[
          SizedBox(height: tokens.spaceXs),
          Text(value!, style: Theme.of(context).textTheme.labelLarge),
        ],
        if (progress != null) ...[
          SizedBox(height: tokens.spaceSm),
          LinearProgressIndicator(
            value: progress,
            minHeight: tokens.hairlineThickness * 4,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
        ],
      ],
    );
    final row = Semantics(
      button: true,
      label: '$label. $description${value == null ? '' : '. $value'}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          cardStyle ? tokens.radiusMd : tokens.radiusSm,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.minTapTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: tokens.spaceSm),
                Expanded(child: details),
                if (!largeText && value != null) ...[
                  SizedBox(width: tokens.spaceSm),
                  Flexible(
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
                SizedBox(width: tokens.spaceXs),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
    if (!cardStyle) return row;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
          child: row,
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.title,
    required this.items,
    required this.accounts,
    required this.hideValues,
    required this.emptyText,
    required this.onSeeAll,
  });

  final String title;
  final List<TransactionRecord> items;
  final List<Account> accounts;
  final bool hideValues;
  final String emptyText;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => HairlineSection(
        title: title,
        trailing: items.isEmpty
            ? null
            : TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
        child: items.isEmpty
            ? _InlineEmpty(
                icon: Icons.receipt_long_outlined,
                text: emptyText,
              )
            : Column(
                children: [
                  for (final item in items.take(5))
                    _RecentTransactionRow(
                      item: item,
                      account: _findAccount(accounts, item.accountId),
                      hideValues: hideValues,
                    ),
                ],
              ),
      );
}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({
    required this.item,
    required this.account,
    required this.hideValues,
  });

  final TransactionRecord item;
  final Account? account;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final income = item.type == TransactionType.income;
    final value = hideValues
        ? '••••••'
        : '${income ? '+' : '−'}${FinancialRules.formatBrl(item.amountInCents)}';
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Semantics(
      label:
          '${income ? 'Entrada' : 'Despesa'}: ${item.description}, ${shortDate(item.occurredOn)}, $value',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InstitutionMark(
              institution: account?.institution ?? AccountInstitution.generic,
              customIconKey: account?.customIconKey,
              size: tokens.quickActionDiameter - tokens.spaceMd,
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description.isEmpty ? item.category : item.description,
                    maxLines: largeText ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    '${shortDate(item.occurredOn)} · ${account?.name ?? item.category}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (largeText) ...[
                    SizedBox(height: tokens.spaceXs),
                    _TransactionValue(value: value, income: income),
                  ],
                ],
              ),
            ),
            if (!largeText) ...[
              SizedBox(width: tokens.spaceSm),
              _TransactionValue(value: value, income: income),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionValue extends StatelessWidget {
  const _TransactionValue({required this.value, required this.income});

  final String value;
  final bool income;

  @override
  Widget build(BuildContext context) => Text(
        value,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: income
                  ? OrganizaDesignTokens.of(context).positive
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      );
}

class _ReportLink extends StatelessWidget {
  const _ReportLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.query_stats_rounded),
          label: const Text('Ver relatório mensal completo'),
        ),
      );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: OrganizaDesignTokens.of(context).spaceSm),
          Expanded(child: Text(text)),
        ],
      );
}

class _NextInvoice {
  const _NextInvoice({
    required this.card,
    required this.dueDate,
    required this.amountInCents,
  });

  final CreditCard card;
  final DateTime dueDate;
  final int amountInCents;
}

class _NextSubscription {
  const _NextSubscription({
    required this.subscription,
    required this.billingDate,
  });

  final Subscription subscription;
  final DateTime billingDate;
}

class _BudgetSummary {
  const _BudgetSummary({
    required this.remainingInCents,
    required this.progress,
  });

  final int remainingInCents;
  final double progress;
  int get usedPercent => (progress * 100).round();
}

_NextInvoice? _nextInvoice(OrganizaStore store, DateTime reference) {
  _NextInvoice? result;
  for (final card in store.creditCards) {
    var dueDate = _safeDate(reference.year, reference.month, card.dueDay);
    if (dueDate.isBefore(_dateOnly(reference))) {
      dueDate = _safeDate(reference.year, reference.month + 1, card.dueDay);
    }
    final closingMonthOffset = card.dueDay > card.closingDay ? 0 : -1;
    final closingDate = _safeDate(
      dueDate.year,
      dueDate.month + closingMonthOffset,
      card.closingDay,
    );
    final candidate = _NextInvoice(
      card: card,
      dueDate: dueDate,
      amountInCents: CreditCardRules.currentInvoiceTotal(
        card,
        store.cardPurchases,
        closingDate,
      ),
    );
    if (result == null || candidate.dueDate.isBefore(result.dueDate)) {
      result = candidate;
    }
  }
  return result;
}

_NextSubscription? _nextSubscription(
  Iterable<Subscription> subscriptions,
  DateTime reference,
) {
  _NextSubscription? result;
  for (final subscription in subscriptions.where((item) => item.isActive)) {
    var billingDate =
        _safeDate(reference.year, reference.month, subscription.billingDay);
    if (billingDate.isBefore(_dateOnly(reference))) {
      billingDate = _safeDate(
        reference.year,
        reference.month + 1,
        subscription.billingDay,
      );
    }
    final candidate = _NextSubscription(
      subscription: subscription,
      billingDate: billingDate,
    );
    if (result == null || candidate.billingDate.isBefore(result.billingDate)) {
      result = candidate;
    }
  }
  return result;
}

_BudgetSummary? _budgetSummary(OrganizaStore store, DateTime month) {
  final budgets = store.budgets
      .where((item) => item.year == month.year && item.month == month.month)
      .toList();
  if (budgets.isEmpty) return null;
  final limit = budgets.fold(0, (total, item) => total + item.limitInCents);
  final spent = budgets.fold(
    0,
    (total, item) =>
        total + FinancialRules.budgetSpent(item, store.reportTransactions),
  );
  final remaining = limit - spent;
  return _BudgetSummary(
    remainingInCents: remaining < 0 ? 0 : remaining,
    progress: limit <= 0 ? 0 : (spent / limit).clamp(0, 1).toDouble(),
  );
}

List<TransactionRecord> _monthTransactions(
  Iterable<TransactionRecord> source,
  DateTime month,
) =>
    source
        .where((item) =>
            item.occurredOn.year == month.year &&
            item.occurredOn.month == month.month)
        .toList();

List<TransactionRecord> _recentTransactions(
  Iterable<TransactionRecord> source,
  TransactionType type,
) {
  final result =
      source.where((item) => item.type == type && item.isSettled).toList()
        ..sort((a, b) {
          final byDate = b.occurredOn.compareTo(a.occurredOn);
          return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
        });
  return result.take(5).toList();
}

Account? _findAccount(Iterable<Account> accounts, String id) {
  for (final account in accounts) {
    if (account.id == id) return account;
  }
  return null;
}

String _visibleMoney(int cents, bool hideValues) =>
    hideValues ? '••••••' : FinancialRules.formatBrl(cents);

DateTime _referenceForMonth(DateTime month, DateTime today) =>
    month.year == today.year && month.month == today.month
        ? today
        : DateTime(month.year, month.month);

DateTime _safeDate(int year, int month, int day) {
  final normalized = DateTime(year, month);
  final lastDay = DateTime(normalized.year, normalized.month + 1, 0).day;
  return DateTime(normalized.year, normalized.month, day.clamp(1, lastDay));
}

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

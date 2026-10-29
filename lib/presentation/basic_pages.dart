import 'dart:io';

import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'budgets_page.dart';
import 'organiza_theme.dart';
import 'shared_widgets.dart';
import '../services/local_image_service.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onDelete,
    required this.onSettledChanged,
    this.onEdit,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final void Function(String id, bool value) onSettledChanged;
  final ValueChanged<TransactionRecord>? onEdit;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  TransactionType? _filter;
  var _query = '';
  var _pendingOnly = false;
  late DateTime? _month;
  String? _accountId;
  bool _largestFirst = false;
  int _visibleCount = 50;
  final _search = TextEditingController();

  DateTime get _currentMonth {
    final now = widget.store.clock.now();
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    _month = _currentMonth;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetFilters() => setState(() {
        _filter = null;
        _query = '';
        _search.clear();
        _pendingOnly = false;
        _accountId = null;
        _largestFirst = false;
        _visibleCount = 50;
        _month = _currentMonth;
      });

  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.transactions.where((item) {
      final matchesType = _filter == null || item.type == _filter;
      final matchesStatus = !_pendingOnly || !item.isSettled;
      final matchesMonth = _month == null ||
          (item.occurredOn.year == _month!.year &&
              item.occurredOn.month == _month!.month);
      final matchesAccount = _accountId == null ||
          item.accountId == _accountId ||
          item.destinationAccountId == _accountId;
      final needle = _query.toLowerCase();
      final matchesQuery = needle.isEmpty ||
          item.description.toLowerCase().contains(needle) ||
          item.category.toLowerCase().contains(needle) ||
          item.subcategory.toLowerCase().contains(needle);
      return matchesType &&
          matchesStatus &&
          matchesQuery &&
          matchesMonth &&
          matchesAccount;
    }).toList()
      ..sort((a, b) {
        if (_largestFirst) {
          final amount = b.amountInCents.compareTo(a.amountInCents);
          if (amount != 0) return amount;
        }
        final date = b.occurredOn.compareTo(a.occurredOn);
        if (date != 0) return date;
        return b.createdAt.compareTo(a.createdAt);
      });
    return _Page(
      heading: PageHeading(
        eyebrow: 'Bancos e carteiras',
        title: 'Movimentações',
        description: 'Encontre cada lançamento. Entenda cada movimento.',
        actions: [_primaryAction('Nova transação', widget.onAdd)],
      ),
      content: Column(
        children: [
          _TransactionFlowSummary(
              transactions: filtered, hideValues: widget.hideValues),
          SizedBox(height: OrganizaDesignTokens.of(context).spaceMd),
          _TransactionScopeBar(
            month: _month,
            accountId: _accountId,
            accounts: widget.store.accounts,
            onPreviousMonth: () => setState(() {
              final current = _month ?? widget.store.clock.now();
              _month = DateTime(current.year, current.month - 1);
            }),
            onNextMonth: () => setState(() {
              final current = _month ?? widget.store.clock.now();
              _month = DateTime(current.year, current.month + 1);
            }),
            onChooseMonth: () async {
              final now = widget.store.clock.now();
              final date = await showDatePicker(
                context: context,
                currentDate: now,
                initialDate: _month ?? now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100, 12, 31),
                helpText: 'Escolha uma data do mês desejado',
              );
              if (date != null) {
                setState(() => _month = DateTime(date.year, date.month));
              }
            },
            onAccountChanged: (value) =>
                setState(() => _accountId = value == '' ? null : value),
            onAllPeriodChanged: (value) =>
                setState(() => _month = value ? null : _currentMonth),
            onReset: _resetFilters,
          ),
          SizedBox(height: OrganizaDesignTokens.of(context).spaceLg),
          HairlineSection(
            title: 'Histórico',
            trailing: _ResultCount(count: filtered.length),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TransactionFilters(
                  filter: _filter,
                  onFilter: (value) => setState(() => _filter = value),
                  pendingOnly: _pendingOnly,
                  onPending: (value) => setState(() => _pendingOnly = value),
                ),
                SizedBox(height: OrganizaDesignTokens.of(context).spaceMd),
                LayoutBuilder(builder: (context, constraints) {
                  final search = TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar descrição, categoria ou subcategoria',
                      prefixIcon: Icon(Icons.search_rounded),
                    ).copyWith(
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () => setState(() {
                                _search.clear();
                                _query = '';
                              }),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  );
                  final sort = OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _largestFirst = !_largestFirst),
                    icon: const Icon(Icons.sort_rounded),
                    label: Text(_largestFirst
                        ? 'Maior valor primeiro'
                        : 'Mais recentes primeiro'),
                  );
                  if (constraints.maxWidth < 720) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        search,
                        SizedBox(
                            height: OrganizaDesignTokens.of(context).spaceSm),
                        Align(alignment: Alignment.centerLeft, child: sort),
                      ],
                    );
                  }
                  return Row(children: [
                    Expanded(child: search),
                    SizedBox(width: OrganizaDesignTokens.of(context).spaceMd),
                    sort,
                  ]);
                }),
                SizedBox(height: OrganizaDesignTokens.of(context).spaceSm),
                if (filtered.isEmpty)
                  _TransactionEmptyResult(
                    hasTransactions: widget.store.transactions.isNotEmpty,
                    onAdd: widget.onAdd,
                    onReset: _resetFilters,
                  )
                else
                  ..._buildGroupedRows(filtered.take(_visibleCount).toList()),
                if (filtered.length > _visibleCount)
                  Padding(
                    padding: EdgeInsets.only(
                        top: OrganizaDesignTokens.of(context).spaceMd),
                    child: TextButton(
                      onPressed: () => setState(() => _visibleCount += 50),
                      child: Text(
                          'Mostrar mais (${filtered.length - _visibleCount} restantes)'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedRows(List<TransactionRecord> items) {
    final rows = <Widget>[];
    DateTime? previous;
    for (final item in items) {
      final current = item.occurredOn;
      final newMonth = previous == null ||
          previous.year != current.year ||
          previous.month != current.month;
      final newDay =
          previous == null || !DateUtils.isSameDay(previous, current);
      if (!_largestFirst) {
        if (newMonth) {
          rows.add(Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              '${sentenceCase(monthName(current.month))} ${current.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ));
        }
        if (newDay) {
          rows.add(Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 3),
            child: Text(
              shortDate(current),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ));
        }
      }
      rows.add(TransactionListRow(
        item: item,
        account: widget.store.accounts
            .where((account) => account.id == item.accountId)
            .firstOrNull,
        hideValues: widget.hideValues,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label:
                  item.isSettled ? 'Marcar como pendente' : 'Marcar como pago',
              child: IconButton(
                tooltip: item.isSettled
                    ? 'Marcar como pendente'
                    : 'Marcar como pago',
                onPressed: () =>
                    widget.onSettledChanged(item.id, !item.isSettled),
                icon: Icon(
                  item.isSettled
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  color: item.isSettled
                      ? OrganizaDesignTokens.of(context).positive
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Ações do lançamento',
              child: PopupMenuButton<String>(
                tooltip: 'Ações do lançamento',
                onSelected: (value) => value == 'edit'
                    ? widget.onEdit?.call(item)
                    : widget.onDelete(item.id),
                itemBuilder: (_) => [
                  if (widget.onEdit != null)
                    const PopupMenuItem(
                        value: 'edit', child: Text('Editar lançamento')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Excluir lançamento')),
                ],
              ),
            ),
          ],
        ),
      ));
      previous = current;
    }
    return rows;
  }
}

class _TransactionScopeBar extends StatelessWidget {
  const _TransactionScopeBar({
    required this.month,
    required this.accountId,
    required this.accounts,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onChooseMonth,
    required this.onAccountChanged,
    required this.onAllPeriodChanged,
    required this.onReset,
  });

  final DateTime? month;
  final String? accountId;
  final List<Account> accounts;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onChooseMonth;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<bool> onAllPeriodChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final monthControl = Container(
      constraints: BoxConstraints(minHeight: tokens.minTapTarget),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(children: [
        Semantics(
          button: true,
          label: 'Mês anterior',
          child: IconButton(
            tooltip: 'Mês anterior',
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: onChooseMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              month == null
                  ? 'Todo o histórico'
                  : '${sentenceCase(monthName(month!.month))} ${month!.year}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Próximo mês',
          child: IconButton(
            tooltip: 'Próximo mês',
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ]),
    );
    final accountControl = DropdownButtonFormField<String>(
      key: ValueKey(accountId),
      initialValue: accountId ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Conta',
        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Todas as contas')),
        ...accounts.map((account) => DropdownMenuItem(
              value: account.id,
              child: Row(children: [
                InstitutionMark(
                  institution: account.institution,
                  customIconKey: account.customIconKey,
                  size: tokens.spaceLg,
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: Text(account.name, overflow: TextOverflow.ellipsis),
                ),
              ]),
            )),
      ],
      onChanged: onAccountChanged,
    );
    final secondaryControls = Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceSm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          avatar: Icon(
            month == null
                ? Icons.check_circle_outline_rounded
                : Icons.history_rounded,
          ),
          label: const Text('Todo o período'),
          selected: month == null,
          onSelected: onAllPeriodChanged,
        ),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpar filtros'),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outline),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              monthControl,
              SizedBox(height: tokens.spaceSm),
              accountControl,
              SizedBox(height: tokens.spaceSm),
              secondaryControls,
            ],
          );
        }
        return Row(children: [
          Expanded(flex: 5, child: monthControl),
          SizedBox(width: tokens.spaceMd),
          Expanded(flex: 4, child: accountControl),
          SizedBox(width: tokens.spaceMd),
          Flexible(flex: 4, child: secondaryControls),
        ]);
      }),
    );
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Text(
        '$count ${count == 1 ? 'resultado' : 'resultados'}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
}

class _TransactionEmptyResult extends StatelessWidget {
  const _TransactionEmptyResult({
    required this.hasTransactions,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasTransactions;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceLg,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.spaceMd,
        runSpacing: tokens.spaceMd,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTile(
                  icon: hasTransactions
                      ? Icons.filter_alt_off_outlined
                      : Icons.receipt_long_outlined,
                ),
                SizedBox(width: tokens.spaceMd),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTransactions
                            ? 'Nenhum lançamento encontrado'
                            : 'Seu histórico começa aqui',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: tokens.spaceXs),
                      Text(
                        hasTransactions
                            ? 'Ajuste o período, a conta ou o termo de busca.'
                            : 'Registre uma receita, despesa ou transferência.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasTransactions)
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Restaurar filtros'),
            )
          else
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova transação'),
            ),
        ],
      ),
    );
  }
}

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({
    required this.filter,
    required this.onFilter,
    required this.pendingOnly,
    required this.onPending,
  });
  final TransactionType? filter;
  final ValueChanged<TransactionType?> onFilter;
  final bool pendingOnly;
  final ValueChanged<bool> onPending;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: OrganizaDesignTokens.of(context).spaceSm,
        runSpacing: OrganizaDesignTokens.of(context).spaceSm,
        children: [
          FilterChip(
              avatar: filter == null
                  ? const Icon(Icons.check_circle_outline_rounded)
                  : null,
              label: const Text('Todas'),
              selected: filter == null,
              onSelected: (_) => onFilter(null)),
          FilterChip(
              avatar: const Icon(Icons.south_west_rounded),
              label: const Text('Receitas'),
              selected: filter == TransactionType.income,
              onSelected: (_) => onFilter(TransactionType.income)),
          FilterChip(
              avatar: const Icon(Icons.north_east_rounded),
              label: const Text('Despesas'),
              selected: filter == TransactionType.expense,
              onSelected: (_) => onFilter(TransactionType.expense)),
          FilterChip(
              avatar: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferências'),
              selected: filter == TransactionType.transfer,
              onSelected: (_) => onFilter(TransactionType.transfer)),
          FilterChip(
              avatar: const Icon(Icons.schedule_rounded),
              label: const Text('Pendentes'),
              selected: pendingOnly,
              onSelected: onPending),
        ],
      );
}

class _TransactionFlowSummary extends StatelessWidget {
  const _TransactionFlowSummary(
      {required this.transactions, required this.hideValues});
  final List<TransactionRecord> transactions;
  final bool hideValues;
  @override
  Widget build(BuildContext context) {
    String money(int value) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(value);
    final incomes = transactions
        .where((t) => t.isSettled && t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountInCents);
    final expenses = transactions
        .where((t) => t.isSettled && t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountInCents);
    final metrics = [
      _FlowMetric(
          label: 'Entradas confirmadas',
          value: money(incomes),
          color: OrganizaDesignTokens.of(context).positive,
          icon: Icons.south_west_rounded),
      _FlowMetric(
          label: 'Saídas confirmadas',
          value: money(expenses),
          color: Theme.of(context).colorScheme.error,
          icon: Icons.north_east_rounded),
      _FlowMetric(
          label: 'Resultado do período',
          value: money(incomes - expenses),
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.account_balance_wallet_outlined,
          emphasized: true),
    ];
    final tokens = OrganizaDesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spaceLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outline),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(children: [
            for (var i = 0; i < metrics.length; i++) ...[
              metrics[i],
              if (i < metrics.length - 1) ...[
                SizedBox(height: tokens.spaceMd),
                const Divider(),
                SizedBox(height: tokens.spaceMd),
              ],
            ],
          ]);
        }
        return Row(children: [
          for (var i = 0; i < metrics.length; i++) ...[
            Expanded(
              flex: i == metrics.length - 1 ? 6 : 5,
              child: metrics[i],
            ),
            if (i < metrics.length - 1) _FlowDivider(),
          ],
        ]);
      }),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon,
      this.emphasized = false});
  final String label, value;
  final Color color;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Row(children: [
        Icon(icon, color: color),
        SizedBox(width: tokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceXs),
              Text(
                value,
                style: (emphasized
                        ? textTheme.headlineSmall
                        : textTheme.titleLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: OrganizaDesignTokens.of(context).hairlineThickness,
        height: OrganizaDesignTokens.of(context).minTapTarget,
        margin: EdgeInsets.symmetric(
          horizontal: OrganizaDesignTokens.of(context).spaceMd,
        ),
        color: Theme.of(context).dividerColor,
      );
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onDelete,
    required this.onEditBalance,
    required this.onEdit,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEditBalance;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) => _Page(
        heading: PageHeading(
          eyebrow: 'Bancos e carteiras',
          title: 'Contas',
          description: 'Saldos locais consolidados por conta.',
          actions: [_primaryAction('Nova conta', onAdd)],
        ),
        content: Panel(
          title: 'Contas cadastradas',
          subtitle:
              '${store.accounts.length} conta${store.accounts.length == 1 ? '' : 's'}',
          child: store.accounts.isEmpty
              ? EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Nenhuma conta',
                  description:
                      'Crie uma conta para registrar seu saldo inicial.',
                  actionLabel: 'Nova conta',
                  onAction: onAdd,
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth > 950
                      ? 3
                      : constraints.maxWidth > 620
                          ? 2
                          : 1;
                  return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: store.accounts.map((account) {
                        final transactions = store.transactions
                            .where((t) =>
                                t.accountId == account.id ||
                                t.destinationAccountId == account.id)
                            .toList();
                        final pending =
                            transactions.where((t) => !t.isSettled).length;
                        return SizedBox(
                            width: (constraints.maxWidth - 16 * (columns - 1)) /
                                columns,
                            child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        InstitutionMark(
                                            institution: account.institution,
                                            customIconKey:
                                                account.customIconKey,
                                            size: 44),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                            tooltip: 'Ações da conta',
                                            onSelected: (action) {
                                              if (action == 'edit') {
                                                onEdit(account.id);
                                              } else if (action == 'balance') {
                                                onEditBalance(account.id);
                                              } else {
                                                onDelete(account.id);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                      value: 'edit',
                                                      child:
                                                          Text('Editar conta')),
                                                  PopupMenuItem(
                                                      value: 'balance',
                                                      child:
                                                          Text('Editar saldo')),
                                                  PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                          'Excluir conta')),
                                                ]),
                                      ]),
                                      const SizedBox(height: 20),
                                      Text(account.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(
                                          institutionName(account.institution,
                                              account.customInstitutionName),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                      const SizedBox(height: 18),
                                      Text(
                                          hideValues
                                              ? '••••••'
                                              : FinancialRules.formatBrl(
                                                  FinancialRules.accountBalance(
                                                      account,
                                                      store.transactions)),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 16),
                                      Text(
                                          '${transactions.length} lançamentos · $pending pendentes',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                          onPressed: () =>
                                              onEditBalance(account.id),
                                          icon: const Icon(Icons.tune_rounded,
                                              size: 17),
                                          label: const Text('Ajustar saldo')),
                                    ])));
                      }).toList());
                }),
        ),
      );
}

class PlanningPage extends StatefulWidget {
  const PlanningPage({
    super.key,
    required this.store,
    this.hideValues = false,
    required this.onAdd,
    required this.onDeleteTask,
    required this.onAddBudget,
    required this.onDeleteBudget,
    required this.onCancelSalary,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final Future<void> Function(String id) onDeleteTask;
  final VoidCallback onAddBudget;
  final ValueChanged<String> onDeleteBudget;
  final ValueChanged<String> onCancelSalary;

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pending = store.tasks.where((task) => !task.isDone).length;
    final salary = store.salaryThisMonth;
    final allocated = store.allocatedSalaryPercent;
    final distributionStatus = allocated > 100
        ? 'Distribuído: $allocated% · sua distribuição ultrapassa a renda em ${allocated - 100}%'
        : 'Distribuído: $allocated% · disponível: ${100 - allocated}%';
    return _Page(
      heading: PageHeading(
        eyebrow: 'ORGANIZAÇÃO',
        title: 'Planejamento e orçamento',
        description: 'Distribua o salário e acompanhe limites por categoria.',
        actions: [
          OutlinedButton.icon(
            onPressed: () => _openBucketDialog(),
            icon: const Icon(Icons.add_chart_rounded, size: 18),
            label: const Text('Nova divisão'),
          ),
          _primaryAction('Nova tarefa', widget.onAdd),
        ],
      ),
      content: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      store.profileIncomeInCents > 0
                          ? 'Renda mensal do perfil'
                          : 'Salário cadastrado em Finanças',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(
                      widget.hideValues
                          ? '••••••'
                          : FinancialRules.formatBrl(salary),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                      salary == 0
                          ? 'Cadastre um salário em Finanças ou informe sua renda em Configurações.'
                          : store.profileIncomeInCents > 0
                              ? 'Valor informado no perfil, em Configurações.'
                              : 'Soma dos salários deste mês cadastrados em Finanças.',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            title: 'Distribuição e orçamento',
            subtitle:
                '$distributionStatus · gastos reais atualizam cada limite',
            trailing: Icon(
              store.allocatedSalaryPercent == 100
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: store.allocatedSalaryPercent == 100
                  ? const Color(0xFF2E9B73)
                  : Theme.of(context).colorScheme.primary,
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: store.salaryAllocationBuckets.length,
              onReorderItem: (oldIndex, newIndex) {
                store.reorderSalaryAllocationBucket(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final bucket = store.salaryAllocationBuckets[index];
                return _AllocationBucketCard(
                  key: ValueKey(bucket.id),
                  bucket: bucket,
                  limitInCents: store.allocationLimitInCents(bucket),
                  spentInCents: store.allocationSpentInCents(bucket),
                  hideValues: widget.hideValues,
                  onEdit: () => _openBucketDialog(bucket),
                  onDelete:
                      bucket.isSystem ? null : () => _deleteBucket(bucket.id),
                  dragHandle: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_indicator_rounded, size: 20),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ExpansionTile(
              initiallyExpanded: store.budgets.isNotEmpty,
              title: const Text('Limites específicos por categoria'),
              subtitle: const Text(
                  'Opcional: acompanhe categorias individuais além das divisões da renda.'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddBudget,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Novo limite específico'),
                  ),
                ),
                const SizedBox(height: 12),
                BudgetSection(
                    store: store,
                    hideValues: widget.hideValues,
                    onAdd: widget.onAddBudget,
                    onDelete: widget.onDeleteBudget,
                    compact: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (store.salarySchedules.isNotEmpty) ...[
            Panel(
              title: 'Salários programados',
              subtitle: 'Uma movimentação aparece somente no dia de pagamento',
              child: Column(
                  children: store.salarySchedules
                      .map((schedule) => DataListRow(
                          icon: Icons.event_repeat_rounded,
                          title: schedule.description,
                          subtitle:
                              'Todo dia ${schedule.paymentDay} · confirme o recebimento em Finanças',
                          value: widget.hideValues
                              ? '••••••'
                              : FinancialRules.formatBrl(
                                  schedule.amountInCents),
                          trailing: Semantics(
                              button: true,
                              label: 'Cancelar salário recorrente',
                              child: IconButton(
                                  tooltip: 'Cancelar salário recorrente',
                                  onPressed: () =>
                                      widget.onCancelSalary(schedule.id),
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18)))))
                      .toList()),
            ),
            const SizedBox(height: 14),
          ],
          Panel(
            title: 'Tarefas',
            subtitle: '$pending pendente${pending == 1 ? '' : 's'}',
            child: store.tasks.isEmpty
                ? EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'Nenhuma tarefa',
                    description: 'Crie tarefas simples para organizar o dia.',
                    actionLabel: 'Nova tarefa',
                    onAction: widget.onAdd)
                : Column(
                    children: store.tasks
                        .map((task) => CheckboxListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              value: task.isDone,
                              onChanged: (value) {
                                if (value != null) {
                                  store.toggleTask(task, value);
                                }
                              },
                              title: Text(task.title,
                                  style: TextStyle(
                                      decoration: task.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isDone
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                          : null)),
                              controlAffinity: ListTileControlAffinity.leading,
                              secondary: Semantics(
                                button: true,
                                label: 'Excluir tarefa',
                                child: IconButton(
                                  onPressed: () => widget.onDeleteTask(task.id),
                                  tooltip: 'Excluir tarefa',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBucketDialog([SalaryAllocationBucket? bucket]) async {
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.name)
        .toList();
    final value = await showDialog<_AllocationBucketInput>(
      context: context,
      builder: (_) => _AllocationBucketDialog(
        bucket: bucket,
        categories: categories,
      ),
    );
    if (value == null || !mounted) return;
    try {
      if (bucket == null) {
        widget.store.addSalaryAllocationBucket(
          name: value.name,
          percent: value.percent,
          iconKey: value.iconKey,
          colorValue: value.colorValue,
          linkedCategories: value.linkedCategories,
        );
      } else {
        widget.store.updateSalaryAllocationBucket(bucket.copyWith(
          name: value.name,
          percent: value.percent,
          iconKey: value.iconKey,
          colorValue: value.colorValue,
          linkedCategories: value.linkedCategories,
        ));
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }

  Future<void> _deleteBucket(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir divisão?'),
            content: const Text(
                'Os lançamentos e categorias vinculados serão preservados.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir')),
            ],
          ),
        ) ??
        false;
    if (confirmed) widget.store.deleteSalaryAllocationBucket(id);
  }
}

class _AllocationBucketCard extends StatelessWidget {
  const _AllocationBucketCard({
    super.key,
    required this.bucket,
    required this.limitInCents,
    required this.spentInCents,
    required this.hideValues,
    required this.onEdit,
    required this.onDelete,
    required this.dragHandle,
  });

  final SalaryAllocationBucket bucket;
  final int limitInCents;
  final int spentInCents;
  final bool hideValues;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final color = Color(bucket.colorValue);
    final progress =
        limitInCents == 0 ? 0.0 : (spentInCents / limitInCents).clamp(0.0, 1.0);
    final available = limitInCents - spentInCents;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: .42),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_allocationIcon(bucket.iconKey),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bucket.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            '${bucket.percent}% · limite ${hideValues ? '••••••' : FinancialRules.formatBrl(limitInCents)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções da divisão',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      if (onDelete != null)
                        const PopupMenuItem(
                            value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                  dragHandle,
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: available >= 0
                      ? color
                      : Theme.of(context).colorScheme.error,
                  backgroundColor: color.withValues(alpha: .12),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    available >= 0
                        ? '${hideValues ? '••••••' : FinancialRules.formatBrl(available)} livres'
                        : '${hideValues ? '••••••' : FinancialRules.formatBrl(-available)} acima',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: available >= 0
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Text(
                      'Gasto ${hideValues ? '••••••' : FinancialRules.formatBrl(spentInCents)}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              if (bucket.linkedCategories.isNotEmpty) ...[
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bucket.linkedCategories.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationBucketInput {
  const _AllocationBucketInput({
    required this.name,
    required this.percent,
    required this.iconKey,
    required this.colorValue,
    required this.linkedCategories,
  });
  final String name;
  final int percent;
  final String iconKey;
  final int colorValue;
  final List<String> linkedCategories;
}

class _AllocationBucketDialog extends StatefulWidget {
  const _AllocationBucketDialog({required this.categories, this.bucket});
  final List<String> categories;
  final SalaryAllocationBucket? bucket;

  @override
  State<_AllocationBucketDialog> createState() =>
      _AllocationBucketDialogState();
}

class _AllocationBucketDialogState extends State<_AllocationBucketDialog> {
  static const _icons = ['home', 'target', 'sparkles', 'wallet', 'health'];
  static const _colors = [
    0xFF3D7A67,
    0xFF4F6BED,
    0xFFB64F21,
    0xFF7B5CC7,
    0xFFD14F68,
  ];
  late final _name = TextEditingController(text: widget.bucket?.name ?? '');
  late final _percent =
      TextEditingController(text: '${widget.bucket?.percent ?? 10}');
  late var _iconKey = widget.bucket?.iconKey ?? 'wallet';
  late var _colorValue = widget.bucket?.colorValue ?? _colors.first;
  late final Set<String> _selected = {
    ...?widget.bucket?.linkedCategories,
  };
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _percent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.bucket == null ? 'Nova divisão' : 'Editar divisão'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _percent,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Percentual da renda', suffixText: '%'),
                ),
                const SizedBox(height: 16),
                Text('Ícone', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _icons
                      .map((key) => IconButton.filledTonal(
                            isSelected: _iconKey == key,
                            onPressed: () => setState(() => _iconKey = key),
                            icon: Icon(_allocationIcon(key)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Text('Cor', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _colors
                      .map((value) => InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: () => setState(() => _colorValue = value),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(value),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _colorValue == value
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Colors.transparent,
                                    width: 2.5),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text('Categorias que consomem este limite',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: widget.categories
                      .map((name) => FilterChip(
                            label: Text(name),
                            selected: _selected.contains(name),
                            onSelected: (value) => setState(() => value
                                ? _selected.add(name)
                                : _selected.remove(name)),
                          ))
                      .toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Salvar')),
        ],
      );

  void _submit() {
    final percent = int.tryParse(_percent.text);
    if (_name.text.trim().isEmpty ||
        percent == null ||
        percent < 0 ||
        percent > 100) {
      setState(() => _error = 'Informe nome e percentual entre 0 e 100.');
      return;
    }
    Navigator.pop(
      context,
      _AllocationBucketInput(
        name: _name.text.trim(),
        percent: percent,
        iconKey: _iconKey,
        colorValue: _colorValue,
        linkedCategories: _selected.toList(),
      ),
    );
  }
}

IconData _allocationIcon(String key) => switch (key) {
      'home' => Icons.home_work_outlined,
      'target' => Icons.track_changes_rounded,
      'sparkles' => Icons.auto_awesome_outlined,
      'health' => Icons.favorite_outline_rounded,
      _ => Icons.account_balance_wallet_outlined,
    };

class SettingsPage extends StatelessWidget {
  const SettingsPage(
      {super.key,
      this.hideValues = false,
      required this.onThemeChanged,
      this.themePreference = 'dark',
      required this.onAccentChanged,
      this.accentPreference = 'organiza',
      required this.quickPages,
      required this.onQuickPagesChanged,
      required this.profileName,
      required this.profileIncomeInCents,
      this.profilePhotoPath,
      required this.onEditProfile,
      required this.onExportBackup,
      required this.onRestoreBackup});

  final ValueChanged<ThemeMode> onThemeChanged;
  final bool hideValues;
  final String themePreference;
  final ValueChanged<String> onAccentChanged;
  final String accentPreference;
  final List<int> quickPages;
  final ValueChanged<List<int>> onQuickPagesChanged;
  final String profileName;
  final int profileIncomeInCents;
  final String? profilePhotoPath;
  final VoidCallback onEditProfile;
  final Future<void> Function() onExportBackup;
  final Future<void> Function() onRestoreBackup;
  static const _quickLabels = <int, String>{
    0: 'Início',
    1: 'Finanças',
    2: 'Contas',
    3: 'Cartões',
    5: 'Investimentos',
    6: 'Organização',
    7: 'Metas',
    8: 'Relatórios',
    10: 'Assinaturas',
    11: 'Lista de desejos'
  };

  @override
  Widget build(BuildContext context) => _Page(
        heading: const PageHeading(
          eyebrow: 'PREFERÊNCIAS',
          title: 'Configurações',
          description: 'Aparência e parâmetros locais do Organiza.',
        ),
        content: Column(
          children: [
            if (MediaQuery.sizeOf(context).width >= 600) ...[
              Panel(
                title: 'Perfil local',
                subtitle:
                    'Uma identificação rápida, salva somente neste aparelho.',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .15),
                      backgroundImage:
                          LocalImageService.exists(profilePhotoPath)
                              ? FileImage(File(profilePhotoPath!))
                              : null,
                      child: LocalImageService.exists(profilePhotoPath)
                          ? null
                          : Icon(Icons.person_outline_rounded,
                              color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileName.isEmpty
                                ? 'Ainda não configurado'
                                : profileName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profileIncomeInCents == 0
                                ? 'Adicione seu nome, renda e foto.'
                                : 'Renda mensal: ${hideValues ? '••••••' : FinancialRules.formatBrl(profileIncomeInCents)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onEditProfile,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label:
                          Text(profileName.isEmpty ? 'Criar perfil' : 'Editar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Panel(
              title: 'Geral',
              child: DataListRow(
                icon: Icons.payments_outlined,
                title: 'Moeda e formato',
                subtitle: 'BRL · R\$ · dd/MM/yyyy',
                value: 'Brasil',
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              title: 'Aparência',
              subtitle: 'Tema e cor de destaque do seu espaço',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _themeButton(Icons.brightness_auto_outlined, 'Sistema',
                          ThemeMode.system),
                      _themeButton(
                          Icons.light_mode_outlined, 'Claro', ThemeMode.light),
                      _themeButton(
                          Icons.dark_mode_outlined, 'Escuro', ThemeMode.dark),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Cor de destaque',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: OrganizaTheme.accentColors.entries
                        .map((entry) => Tooltip(
                              message: _accentName(entry.key),
                              child: Semantics(
                                button: true,
                                selected: accentPreference == entry.key,
                                label: 'Cor ${_accentName(entry.key)}',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () => onAccentChanged(entry.key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: entry.value,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accentPreference == entry.key
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: accentPreference == entry.key
                                          ? [
                                              BoxShadow(
                                                color: entry.value
                                                    .withValues(alpha: .34),
                                                blurRadius: 12,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: accentPreference == entry.key
                                        ? Icon(Icons.check_rounded,
                                            color: entry.key == 'neutral'
                                                ? Colors.black
                                                : Colors.white,
                                            size: 19)
                                        : null,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (MediaQuery.sizeOf(context).width < 600) ...[
              Panel(
                  title: 'Acesso rápido no celular',
                  subtitle:
                      'Escolha quatro áreas para a barra inferior. O botão Nova transação permanece no centro.',
                  child: Column(
                      children: List.generate(
                          4,
                          (slot) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    key: ValueKey(
                                        'quick-$slot-${quickPages[slot]}'),
                                    initialValue: quickPages[slot],
                                    decoration: InputDecoration(
                                        labelText: 'Atalho ${slot + 1}'),
                                    items: _quickLabels.entries
                                        .where((entry) =>
                                            entry.key == quickPages[slot] ||
                                            !quickPages.contains(entry.key))
                                        .map((entry) => DropdownMenuItem(
                                            value: entry.key,
                                            child: Text(entry.value)))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      final next = List<int>.of(quickPages);
                                      next[slot] = value;
                                      onQuickPagesChanged(next);
                                    }),
                              )))),
              const SizedBox(height: 14),
            ],
            Panel(
              title: 'Backup local',
              subtitle:
                  'Crie um arquivo protegido por senha para recuperar seus dados em outro dispositivo.',
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onExportBackup(),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('Criar backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onRestoreBackup(),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restaurar backup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Panel(
              title: 'Privacidade',
              child: DataListRow(
                icon: Icons.shield_outlined,
                title: 'Dados somente neste dispositivo',
                subtitle: 'Sem login online, analytics ou telemetria.',
                value: 'Local',
              ),
            ),
          ],
        ),
      );

  Widget _themeButton(IconData icon, String label, ThemeMode mode) =>
      OutlinedButton.icon(
        onPressed: () => onThemeChanged(mode),
        icon: Icon(
            themePreference == mode.name ? Icons.check_circle_outline : icon),
        label: Text(label),
      );

  String _accentName(String value) => switch (value) {
        'blue' => 'Azul',
        'green' => 'Verde',
        'purple' => 'Roxo',
        'pink' => 'Rosa',
        'red' => 'Vermelho',
        'teal' => 'Turquesa',
        'neutral' => 'Neutro',
        _ => 'Organiza',
      };
}

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Panel(
            title: title,
            subtitle: 'Módulo planejado',
            child: const EmptyState(
              icon: Icons.layers_outlined,
              title: 'Próxima etapa',
              description:
                  'Esta área ainda não registra dados. Contas, movimentações, cartões e tarefas já funcionam localmente.',
            ),
          ),
        ),
      );
}

class _Page extends StatelessWidget {
  const _Page({required this.heading, required this.content});

  final Widget heading;
  final Widget content;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: ListView(
          padding: pagePadding(context),
          children: [heading, const SizedBox(height: 24), content],
        ),
      );
}

Widget _primaryAction(String label, VoidCallback onPressed) =>
    FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
    );

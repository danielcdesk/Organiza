part of 'basic_pages.dart';

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
  DateTime? _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _accountId;
  bool _largestFirst = false;
  int _visibleCount = 50;
  final _search = TextEditingController();

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
        _month = DateTime(DateTime.now().year, DateTime.now().month);
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
      ..sort((a, b) => _largestFirst
          ? b.amountInCents.compareTo(a.amountInCents)
          : b.occurredOn.compareTo(a.occurredOn));
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
              final current = _month ?? DateTime.now();
              _month = DateTime(current.year, current.month - 1);
            }),
            onNextMonth: () => setState(() {
              final current = _month ?? DateTime.now();
              _month = DateTime(current.year, current.month + 1);
            }),
            onChooseMonth: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _month ?? DateTime.now(),
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
            onAllPeriodChanged: (value) => setState(() => _month = value
                ? null
                : DateTime(DateTime.now().year, DateTime.now().month)),
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
                  ...filtered
                      .take(_visibleCount)
                      .map((item) => TransactionListRow(
                            item: item,
                            account: widget.store.accounts
                                .where((a) => a.id == item.accountId)
                                .firstOrNull,
                            hideValues: widget.hideValues,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  button: true,
                                  label: item.isSettled
                                      ? 'Marcar como pendente'
                                      : 'Marcar como pago',
                                  child: IconButton(
                                    tooltip: item.isSettled
                                        ? 'Marcar como pendente'
                                        : 'Marcar como pago',
                                    onPressed: () => widget.onSettledChanged(
                                        item.id, !item.isSettled),
                                    icon: Icon(
                                      item.isSettled
                                          ? Icons.check_circle_rounded
                                          : Icons.schedule_rounded,
                                      color: item.isSettled
                                          ? OrganizaDesignTokens.of(context)
                                              .positive
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
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
                                            value: 'edit',
                                            child: Text('Editar lançamento')),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Excluir lançamento')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
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

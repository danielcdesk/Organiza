import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'dialogs.dart';
import 'budgets_page.dart';
import 'shared_widgets.dart';

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
          const SizedBox(height: 16),
          LayoutBuilder(
              builder: (context, constraints) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                            width: constraints.maxWidth < 540
                                ? constraints.maxWidth
                                : 300,
                            child: Row(children: [
                              IconButton(
                                  tooltip: 'Mês anterior',
                                  onPressed: () => setState(() {
                                        final current =
                                            _month ?? DateTime.now();
                                        _month = DateTime(
                                            current.year, current.month - 1);
                                      }),
                                  icon: const Icon(Icons.chevron_left_rounded)),
                              Expanded(
                                  child: TextButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _month ?? DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100, 12, 31),
                                            helpText:
                                                'Escolha uma data do mês desejado');
                                        if (date != null) {
                                          setState(() => _month =
                                              DateTime(date.year, date.month));
                                        }
                                      },
                                      child: Text(_month == null
                                          ? 'Todo o histórico'
                                          : '${sentenceCase(monthName(_month!.month))} ${_month!.year}'))),
                              IconButton(
                                  tooltip: 'Próximo mês',
                                  onPressed: () => setState(() {
                                        final current =
                                            _month ?? DateTime.now();
                                        _month = DateTime(
                                            current.year, current.month + 1);
                                      }),
                                  icon:
                                      const Icon(Icons.chevron_right_rounded)),
                            ])),
                        SizedBox(
                            width: constraints.maxWidth < 540
                                ? constraints.maxWidth
                                : 230,
                            child: DropdownButtonFormField<String>(
                                key: ValueKey(_accountId),
                                initialValue: _accountId ?? '',
                                isExpanded: true,
                                decoration:
                                    const InputDecoration(labelText: 'Conta'),
                                items: [
                                  const DropdownMenuItem(
                                      value: '',
                                      child: Text('Todas as contas')),
                                  ...widget.store.accounts
                                      .map((account) => DropdownMenuItem(
                                          value: account.id,
                                          child: Row(children: [
                                            InstitutionMark(
                                                institution:
                                                    account.institution,
                                                size: 22),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(account.name,
                                                    overflow:
                                                        TextOverflow.ellipsis))
                                          ])))
                                ],
                                onChanged: (value) => setState(() =>
                                    _accountId = value == '' ? null : value))),
                        FilterChip(
                            label: const Text('Todo o período'),
                            selected: _month == null,
                            onSelected: (value) => setState(() => _month = value
                                ? null
                                : DateTime(DateTime.now().year,
                                    DateTime.now().month))),
                        TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Limpar filtros')),
                      ])),
          const SizedBox(height: 14),
          Panel(
            title: 'Histórico',
            subtitle:
                '${filtered.length} resultado${filtered.length == 1 ? '' : 's'}',
            trailing: _TransactionFilters(
              filter: _filter,
              onFilter: (value) => setState(() => _filter = value),
              pendingOnly: _pendingOnly,
              onPending: (value) => setState(() => _pendingOnly = value),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por descrição, categoria ou subcategoria',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _largestFirst = !_largestFirst),
                        icon: const Icon(Icons.sort_rounded, size: 18),
                        label: Text(_largestFirst
                            ? 'Maior valor primeiro'
                            : 'Mais recentes primeiro'))),
                if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: widget.store.transactions.isEmpty
                        ? 'Sem movimentações'
                        : 'Nenhum resultado',
                    description: widget.store.transactions.isEmpty
                        ? 'Registre sua primeira receita, despesa ou transferência.'
                        : 'Tente outro filtro ou termo de busca.',
                    actionLabel: widget.store.transactions.isEmpty
                        ? 'Nova transação'
                        : null,
                    onAction:
                        widget.store.transactions.isEmpty ? widget.onAdd : null,
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
                                IconButton(
                                  tooltip: item.isSettled
                                      ? 'Marcar como pendente'
                                      : 'Marcar como pago',
                                  onPressed: () => widget.onSettledChanged(
                                      item.id, !item.isSettled),
                                  icon: Icon(
                                    item.isSettled
                                        ? Icons.check_circle_rounded
                                        : Icons.schedule_rounded,
                                    size: 18,
                                    color: item.isSettled
                                        ? const Color(0xFF258A5A)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                                PopupMenuButton<String>(
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
                              ],
                            ),
                          )),
                if (filtered.length > _visibleCount)
                  TextButton(
                      onPressed: () => setState(() => _visibleCount += 50),
                      child: Text(
                          'Mostrar mais (${filtered.length - _visibleCount} restantes)')),
              ],
            ),
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
        spacing: 6,
        children: [
          FilterChip(
              label: const Text('Todas'),
              selected: filter == null,
              onSelected: (_) => onFilter(null)),
          FilterChip(
              label: const Text('Receitas'),
              selected: filter == TransactionType.income,
              onSelected: (_) => onFilter(TransactionType.income)),
          FilterChip(
              label: const Text('Despesas'),
              selected: filter == TransactionType.expense,
              onSelected: (_) => onFilter(TransactionType.expense)),
          FilterChip(
              label: const Text('Transferências'),
              selected: filter == TransactionType.transfer,
              onSelected: (_) => onFilter(TransactionType.transfer)),
          FilterChip(
              avatar: const Icon(Icons.schedule_rounded, size: 15),
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
          label: 'Recebido no filtro',
          value: money(incomes),
          color: const Color(0xFF258A5A),
          icon: Icons.south_west_rounded),
      _FlowMetric(
          label: 'Pago no filtro',
          value: money(expenses),
          color: const Color(0xFFC94D4D),
          icon: Icons.north_east_rounded),
      _FlowMetric(
          label: 'Resultado',
          value: money(incomes - expenses),
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.account_balance_outlined),
    ];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 450) {
                return Column(children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    metrics[i],
                    if (i < metrics.length - 1) const SizedBox(height: 16),
                  ]
                ]);
              }
              return Row(children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(child: metrics[i]),
                  if (i < metrics.length - 1) _FlowDivider(),
                ]
              ]);
            })));
  }
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color))
        ]))
      ]);
}

class _FlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 38, color: Theme.of(context).dividerColor);
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onDelete,
    required this.onEditBalance,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEditBalance;

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
                                            size: 44),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                            tooltip: 'Ações da conta',
                                            onSelected: (action) =>
                                                action == 'balance'
                                                    ? onEditBalance(account.id)
                                                    : onDelete(account.id),
                                            itemBuilder: (_) => const [
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
                                      Text(institutionName(account.institution),
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
    required this.onAdd,
    required this.onDeleteTask,
    required this.onAddBudget,
    required this.onDeleteBudget,
    required this.onCancelSalary,
    this.budgetFirst = false,
  });

  final OrganizaStore store;
  final VoidCallback onAdd;
  final Future<void> Function(String id) onDeleteTask;
  final VoidCallback onAddBudget;
  final ValueChanged<String> onDeleteBudget;
  final ValueChanged<String> onCancelSalary;
  final bool budgetFirst;

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  late final Map<String, double> _allocations;

  @override
  void initState() {
    super.initState();
    final saved = widget.store.salaryAllocation;
    _allocations = {
      'Essenciais': saved.essentialsPercent / 100,
      'Objetivos': saved.goalsPercent / 100,
      'Livre': saved.freePercent / 100,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pending = store.tasks.where((task) => !task.isDone).length;
    final salary = store.salaryThisMonth;
    return _Page(
      heading: PageHeading(
        eyebrow: 'ORGANIZAÇÃO',
        title: 'Planejamento e orçamento',
        description: 'Distribua o salário e acompanhe limites por categoria.',
        actions: [
          OutlinedButton.icon(
            onPressed: _openSalaryDialog,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Organizar salário'),
          ),
          _primaryAction('Nova tarefa', widget.onAdd),
        ],
      ),
      content: Column(
        children: [
          if (widget.budgetFirst) ...[
            BudgetSection(
                store: store,
                onAdd: widget.onAddBudget,
                onDelete: widget.onDeleteBudget),
            const SizedBox(height: 20),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Salário identificado no mês',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Text(FinancialRules.formatBrl(salary),
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text('Somente receitas na categoria Salário',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                      onPressed: _openSalaryDialog,
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: const Text('Distribuir')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            title: 'Distribuição sugerida',
            subtitle: 'Ajuste os blocos para o seu momento',
            child: Column(
              children: _allocations.entries
                  .map((entry) => _AllocationRow(
                        label: entry.key,
                        ratio: entry.value,
                        amount: (salary * entry.value).round(),
                        onChanged: (value) =>
                            _changeAllocation(entry.key, value),
                        onChangeEnd: (_) => _persistAllocations(),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (store.salarySchedules.isNotEmpty) ...[
            Panel(
                title: 'Salários programados',
                subtitle:
                    'Uma movimentação aparece somente no dia de pagamento',
                child: Column(
                    children: store.salarySchedules
                        .map((schedule) => DataListRow(
                            icon: Icons.event_repeat_rounded,
                            title: schedule.description,
                            subtitle:
                                'Todo dia ${schedule.paymentDay} · confirme o recebimento em Finanças',
                            value: FinancialRules.formatBrl(
                                schedule.amountInCents),
                            trailing: IconButton(
                                tooltip: 'Cancelar salário recorrente',
                                onPressed: () =>
                                    widget.onCancelSalary(schedule.id),
                                icon:
                                    const Icon(Icons.close_rounded, size: 18))))
                        .toList())),
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
                              secondary: IconButton(
                                onPressed: () => widget.onDeleteTask(task.id),
                                tooltip: 'Excluir tarefa',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
          if (!widget.budgetFirst) ...[
            const SizedBox(height: 24),
            BudgetSection(
                store: store,
                onAdd: widget.onAddBudget,
                onDelete: widget.onDeleteBudget),
          ],
        ],
      ),
    );
  }

  Future<void> _openSalaryDialog() async {
    final values = await showDialog<List<int>>(
        context: context,
        builder: (_) => _SalaryDialog(salary: widget.store.salaryThisMonth));
    if (values == null || !mounted || widget.store.salaryThisMonth == 0) return;
    final total = values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    setState(() {
      _allocations['Essenciais'] = values[0] / total;
      _allocations['Objetivos'] = values[1] / total;
      _allocations['Livre'] = values[2] / total;
    });
    _persistAllocations();
  }

  void _changeAllocation(String changed, double value) {
    final safeValue = value.clamp(.05, .90);
    final others = _allocations.keys.where((key) => key != changed).toList();
    final oldOtherTotal =
        others.fold<double>(0, (sum, key) => sum + _allocations[key]!);
    final remaining = 1 - safeValue;
    setState(() {
      _allocations[changed] = safeValue;
      for (final key in others) {
        _allocations[key] = oldOtherTotal == 0
            ? remaining / others.length
            : remaining * (_allocations[key]! / oldOtherTotal);
      }
    });
  }

  void _persistAllocations() {
    final essentials = (_allocations['Essenciais']! * 100).round();
    final goals = (_allocations['Objetivos']! * 100).round();
    final free = 100 - essentials - goals;
    widget.store.updateSalaryAllocation(
      essentialsPercent: essentials,
      goalsPercent: goals,
      freePercent: free,
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow(
      {required this.label,
      required this.ratio,
      required this.amount,
      required this.onChanged,
      required this.onChangeEnd});
  final String label;
  final double ratio;
  final int amount;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${(ratio * 100).round()}%',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 14),
              Text(FinancialRules.formatBrl(amount),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12)),
            ]),
            Slider(
                value: ratio.clamp(0, 1),
                onChanged: onChanged,
                onChangeEnd: onChangeEnd),
          ],
        ),
      );
}

class _SalaryDialog extends StatefulWidget {
  const _SalaryDialog({required this.salary});
  final int salary;
  @override
  State<_SalaryDialog> createState() => _SalaryDialogState();
}

class _SalaryDialogState extends State<_SalaryDialog> {
  late final List<TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    String money(double ratio) =>
        ((widget.salary * ratio) / 100).toStringAsFixed(2).replaceAll('.', ',');
    _controllers = [
      TextEditingController(text: money(.5)),
      TextEditingController(text: money(.3)),
      TextEditingController(text: money(.2))
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Distribuir salário'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                3,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[index],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: [
                              'Essenciais',
                              'Objetivos',
                              'Livre'
                            ][index],
                            prefixText: 'R\$ '),
                      ),
                    )),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context,
                  _controllers.map((c) => parseMoney(c.text) ?? 0).toList()),
              child: const Text('Aplicar')),
        ],
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage(
      {super.key,
      required this.onThemeChanged,
      this.themePreference = 'light',
      required this.quickPages,
      required this.onQuickPagesChanged});

  final ValueChanged<ThemeMode> onThemeChanged;
  final String themePreference;
  final List<int> quickPages;
  final ValueChanged<List<int>> onQuickPagesChanged;
  static const _quickLabels = <int, String>{
    0: 'Início',
    1: 'Finanças',
    2: 'Contas',
    3: 'Cartões',
    4: 'Orçamento',
    5: 'Investimentos',
    6: 'Planejamento',
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
              subtitle: 'Escolha como o aplicativo deve ser exibido',
              child: Wrap(
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
  Widget build(BuildContext context) => ListView(
        padding: pagePadding(context),
        children: [heading, const SizedBox(height: 24), content],
      );
}

Widget _primaryAction(String label, VoidCallback onPressed) =>
    FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
    );

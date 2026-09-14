import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'dialogs.dart';
import 'shared_widgets.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onDelete,
    required this.onSettledChanged,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final void Function(String id, bool value) onSettledChanged;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  TransactionType? _filter;
  var _query = '';
  var _pendingOnly = false;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.transactions.where((item) {
      final matchesType = _filter == null || item.type == _filter;
      final matchesStatus = !_pendingOnly || !item.isSettled;
      final needle = _query.toLowerCase();
      final matchesQuery = needle.isEmpty ||
          item.description.toLowerCase().contains(needle) ||
          item.category.toLowerCase().contains(needle) ||
          item.subcategory.toLowerCase().contains(needle);
      return matchesType && matchesStatus && matchesQuery;
    }).toList();
    return _Page(
      heading: PageHeading(
        eyebrow: 'Bancos e carteiras',
        title: 'Movimentações',
        description: 'Explore seu fluxo por tipo, categoria e descrição.',
        actions: [_primaryAction('Nova transação', widget.onAdd)],
      ),
      content: Column(
        children: [
          _TransactionFlowSummary(
              store: widget.store, hideValues: widget.hideValues),
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
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por descrição, categoria ou subcategoria',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
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
                  ...filtered.map((item) => TransactionListRow(
                        item: item,
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
                            IconButton(
                              tooltip: 'Excluir lançamento',
                              onPressed: () => widget.onDelete(item.id),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                            ),
                          ],
                        ),
                      )),
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
      {required this.store, required this.hideValues});
  final OrganizaStore store;
  final bool hideValues;
  @override
  Widget build(BuildContext context) {
    String money(int value) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(value);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                  child: _FlowMetric(
                      label: 'Entradas no mês',
                      value: money(store.incomes),
                      color: const Color(0xFF258A5A),
                      icon: Icons.south_west_rounded)),
              _FlowDivider(),
              Expanded(
                  child: _FlowMetric(
                      label: 'Saídas no mês',
                      value: money(store.expenses),
                      color: const Color(0xFFC94D4D),
                      icon: Icons.north_east_rounded)),
              _FlowDivider(),
              Expanded(
                  child: _FlowMetric(
                      label: 'Resultado',
                      value: money(store.incomes - store.expenses),
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.account_balance_outlined)),
            ])));
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
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

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
              : Column(
                  children: store.accounts.map((account) {
                    return DataListRow(
                      icon: Icons.account_balance_outlined,
                      leading:
                          InstitutionMark(institution: account.institution),
                      title: account.name,
                      subtitle: institutionName(account.institution),
                      value: hideValues
                          ? '••••••'
                          : FinancialRules.formatBrl(
                              FinancialRules.accountBalance(
                                  account, store.transactions),
                            ),
                      trailing: IconButton(
                        tooltip: 'Excluir conta',
                        onPressed: () => onDelete(account.id),
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                      ),
                    );
                  }).toList(),
                ),
        ),
      );
}

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key, required this.store, required this.onAdd});

  final OrganizaStore store;
  final VoidCallback onAdd;

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
    final salary = store.incomes;
    return _Page(
      heading: PageHeading(
        eyebrow: 'ORGANIZAÇÃO',
        title: 'Planejamento',
        description: 'Veja seu salário e transforme o mês em decisões simples.',
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
                        Text('Baseado nas receitas registradas',
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
                      icon: const Icon(Icons.auto_awesome_outlined, size: 17),
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
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSalaryDialog() async {
    final values = await showDialog<List<int>>(
        context: context,
        builder: (_) => _SalaryDialog(salary: widget.store.incomes));
    if (values == null || !mounted || widget.store.incomes == 0) return;
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
  const SettingsPage({super.key, required this.onThemeChanged});

  final ValueChanged<ThemeMode> onThemeChanged;

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
            const Panel(
              title: 'Privacidade',
              child: DataListRow(
                icon: Icons.shield_outlined,
                title: 'Dados somente neste computador',
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
        icon: Icon(icon),
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
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
        children: [heading, const SizedBox(height: 24), content],
      );
}

Widget _primaryAction(String label, VoidCallback onPressed) =>
    FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
    );

part of 'basic_pages.dart';

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
    this.hideValues = false,
  });

  final OrganizaStore store;
  final VoidCallback onAdd;
  final Future<void> Function(String id) onDeleteTask;
  final VoidCallback onAddBudget;
  final ValueChanged<String> onDeleteBudget;
  final ValueChanged<String> onCancelSalary;
  final bool budgetFirst;
  final bool hideValues;

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
          MonthlyPlanningPage(store: store, hideValues: widget.hideValues),
          const SizedBox(height: 20),
          FinancialCommitmentsPage(store: store, hideValues: widget.hideValues),
          const SizedBox(height: 20),
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
              child: LayoutBuilder(builder: (context, constraints) {
                final details = Column(
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
                );
                final action = FilledButton.icon(
                    onPressed: _openSalaryDialog,
                    icon: const Icon(Icons.tune_rounded, size: 17),
                    label: const Text('Distribuir'));
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: 14),
                      action,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: details),
                    action,
                  ],
                );
              }),
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
              subtitle: 'Uma movimentação aparece somente no dia de pagamento',
              child: Column(
                  children: store.salarySchedules
                      .map((schedule) => DataListRow(
                          icon: Icons.event_repeat_rounded,
                          title: schedule.description,
                          subtitle:
                              'Todo dia ${schedule.paymentDay} · confirme o recebimento em Finanças',
                          value:
                              FinancialRules.formatBrl(schedule.amountInCents),
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
        formatMoneyInput((widget.salary * ratio).round());
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
                        inputFormatters: [BrlCentsInputFormatter()],
                        decoration: InputDecoration(
                          labelText: [
                            'Essenciais',
                            'Objetivos',
                            'Livre'
                          ][index],
                        ),
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

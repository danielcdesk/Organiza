part of 'dialogs.dart';

class BudgetInput {
  const BudgetInput({required this.category, required this.limitInCents});
  final String category;
  final int limitInCents;
}

class SubscriptionInput {
  const SubscriptionInput(
      {required this.name,
      required this.amountInCents,
      required this.billingDay,
      required this.category,
      required this.iconKey});
  final String name;
  final int amountInCents;
  final int billingDay;
  final String category;
  final String iconKey;
}

class SubscriptionDialog extends StatefulWidget {
  const SubscriptionDialog(
      {super.key, required this.categories, this.subscription});

  final List<String> categories;
  final Subscription? subscription;

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '10');
  late String _category;
  String _iconKey = 'auto';
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.subscription;
    _category = item != null && widget.categories.contains(item.category)
        ? item.category
        : widget.categories.contains('Lazer')
            ? 'Lazer'
            : widget.categories.first;
    if (item != null) {
      _iconKey = item.iconKey ?? 'auto';
      _name.text = item.name;
      _amount.text = _investmentMoneyInput(item.amountInCents);
      _day.text = item.billingDay.toString();
    }
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.subscription == null
            ? 'Nova assinatura'
            : 'Editar assinatura'),
        content: SizedBox(
          width: 430,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Ex.: streaming, academia...')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [BrlCentsInputFormatter()],
                      decoration: const InputDecoration(
                          labelText: 'Valor mensal (R\$)'))),
              const SizedBox(width: 12),
              SizedBox(
                  width: 110,
                  child: TextField(
                      controller: _day,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Dia'))),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: widget.categories
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!)),
            const SizedBox(height: 12),
            Row(children: [
              SubscriptionBrandIcon(name: _name.text, iconKey: _iconKey),
              const SizedBox(width: 12),
              Expanded(
                  child: DropdownButtonFormField<String>(
                initialValue: _iconKey,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ícone'),
                items: [
                  const DropdownMenuItem(
                      value: 'auto', child: Text('Automático pelo nome')),
                  const DropdownMenuItem(
                      value: 'generic', child: Text('Genérico')),
                  for (final brand in subscriptionBrands)
                    DropdownMenuItem(value: brand.key, child: Text(brand.name)),
                ],
                onChanged: (value) => setState(() => _iconKey = value!),
              )),
            ]),
            _DialogError(_error),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _submit, child: const Text('Salvar assinatura')),
        ],
      );

  void _submit() {
    final amount = parseMoney(_amount.text);
    final day = int.tryParse(_day.text);
    if (_name.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        day == null ||
        day < 1 ||
        day > 31) {
      setState(() => _error = 'Informe nome, valor e um dia entre 1 e 31.');
      return;
    }
    Navigator.pop(
        context,
        SubscriptionInput(
            name: _name.text,
            amountInCents: amount,
            billingDay: day,
            category: _category,
            iconKey: _iconKey));
  }
}

class BudgetDialog extends StatefulWidget {
  const BudgetDialog(
      {super.key, required this.categories, required this.onCreateCategory});

  final List<String> categories;
  final FinanceCategory Function(String name, TransactionType type)
      onCreateCategory;

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late String _category;
  late List<String> _categories;
  final _limit = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
    _category = _categories.first;
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Novo orçamento'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: _categories
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value!),
                )),
                IconButton.filledTonal(
                    tooltip: 'Criar categoria de orçamento',
                    onPressed: _createCategory,
                    icon: const Icon(Icons.add_rounded))
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _limit,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [BrlCentsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Limite mensal (R\$)',
                  hintText: 'Ex.: 1.500,00',
                ),
              ),
              _DialogError(_error),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _submit, child: const Text('Criar orçamento')),
        ],
      );

  void _submit() {
    final limit = parseMoney(_limit.text);
    if (limit == null || limit <= 0) {
      setState(() => _error = 'Informe um limite mensal maior que zero.');
      return;
    }
    Navigator.pop(
        context, BudgetInput(category: _category, limitInCents: limit));
  }

  Future<void> _createCategory() async {
    final name = await showDialog<String>(
        context: context,
        builder: (_) => const _NameDialog(
            title: 'Nova categoria', label: 'Nome da categoria'));
    if (name == null || !mounted) return;
    try {
      final category = widget.onCreateCategory(name, TransactionType.expense);
      setState(() {
        _categories.add(category.name);
        _category = category.name;
      });
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
    }
  }
}

class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class FinancialGoalInput {
  const FinancialGoalInput({
    required this.name,
    required this.targetInCents,
    required this.initialSavedInCents,
    required this.deadline,
    required this.iconKey,
    required this.category,
    required this.colorValue,
    required this.note,
    this.imagePath,
    this.removeImage = false,
  });

  final String name;
  final int targetInCents;
  final int initialSavedInCents;
  final DateTime? deadline;
  final String iconKey;
  final String category;
  final int colorValue;
  final String note;
  final String? imagePath;
  final bool removeImage;
}

class FinancialGoalDialog extends StatefulWidget {
  const FinancialGoalDialog(
      {super.key,
      required this.categories,
      required this.onCreateCategory,
      this.goal});
  final List<String> categories;
  final void Function(String name) onCreateCategory;
  final FinancialGoal? goal;

  @override
  State<FinancialGoalDialog> createState() => _FinancialGoalDialogState();
}

class _FinancialGoalDialogState extends State<FinancialGoalDialog> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _initial = TextEditingController(text: '0,00');
  final _note = TextEditingController();
  DateTime? _deadline;
  var _iconKey = 'savings';
  var _colorValue = 0xFFFF9800;
  String? _imagePath;
  bool _removeImage = false;
  late List<String> _categories;
  late String _category;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
    final goal = widget.goal;
    _category = goal != null && _categories.contains(goal.category)
        ? goal.category
        : _categories.contains('Reserva')
            ? 'Reserva'
            : _categories.first;
    if (goal != null) {
      _name.text = goal.name;
      _target.text = formatMoneyInput(goal.targetInCents);
      _initial.text = formatMoneyInput(goal.savedInCents);
      _note.text = goal.note;
      _deadline = goal.deadline;
      _iconKey = goal.iconKey;
      _colorValue = goal.colorValue;
      _imagePath = goal.imagePath;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _initial.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.goal == null ? 'Nova meta financeira' : 'Editar meta'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome da meta',
                  hintText: 'Ex.: Reserva de emergência',
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _target,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [BrlCentsInputFormatter()],
                    decoration:
                        const InputDecoration(labelText: 'Objetivo (R\$)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _initial,
                    enabled: widget.goal == null,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [BrlCentsInputFormatter()],
                    decoration:
                        const InputDecoration(labelText: 'Já guardado (R\$)'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  decoration:
                      const InputDecoration(labelText: 'Categoria da meta'),
                  items: _categories
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value!),
                )),
                IconButton.filledTonal(
                    tooltip: 'Criar categoria de meta',
                    onPressed: _createCategory,
                    icon: const Icon(Icons.add_rounded))
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _iconKey,
                decoration: const InputDecoration(labelText: 'Tipo de meta'),
                items: const [
                  DropdownMenuItem(value: 'savings', child: Text('Reserva')),
                  DropdownMenuItem(value: 'home', child: Text('Casa')),
                  DropdownMenuItem(value: 'travel', child: Text('Viagem')),
                  DropdownMenuItem(value: 'education', child: Text('Estudos')),
                  DropdownMenuItem(value: 'car', child: Text('Veículo')),
                  DropdownMenuItem(
                      value: 'custom', child: Text('Personalizada')),
                ],
                onChanged: (value) => setState(() => _iconKey = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                for (final color in const [
                  0xFFFF9800,
                  0xFF258A5A,
                  0xFF5472B8,
                  0xFF9B59B6,
                  0xFFC94D4D
                ])
                  IconButton(
                    tooltip: 'Cor da meta',
                    onPressed: () => setState(() => _colorValue = color),
                    icon: Icon(
                        _colorValue == color
                            ? Icons.check_circle
                            : Icons.circle,
                        color: Color(color)),
                  ),
              ]),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await LocalImageService.pickAndStore();
                  if (selected != null && mounted) {
                    setState(() {
                      _imagePath = selected;
                      _removeImage = false;
                    });
                  }
                },
                icon: const Icon(Icons.image_outlined),
                label: Text(
                    _imagePath == null ? 'Adicionar imagem' : 'Trocar imagem'),
              ),
              if (_imagePath != null)
                TextButton(
                    onPressed: () => setState(() {
                          _imagePath = null;
                          _removeImage = true;
                        }),
                    child: const Text('Remover imagem')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.event_outlined, size: 17),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_deadline == null
                        ? 'Definir prazo (opcional)'
                        : 'Prazo: ${shortDate(_deadline!)}'),
                  ),
                ),
              ),
              _DialogError(_error),
            ],
          )),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _submit,
              child: Text(widget.goal == null ? 'Criar meta' : 'Salvar meta')),
        ],
      );

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 180)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (value != null && mounted) setState(() => _deadline = value);
  }

  void _submit() {
    final target = parseMoney(_target.text);
    final initial = parseMoney(_initial.text) ?? 0;
    if (_name.text.trim().isEmpty ||
        target == null ||
        target <= 0 ||
        initial < 0 ||
        initial > target) {
      setState(() => _error =
          'Informe um nome, um objetivo válido e um valor inicial menor que a meta.');
      return;
    }
    Navigator.pop(
      context,
      FinancialGoalInput(
        name: _name.text,
        targetInCents: target,
        initialSavedInCents: initial,
        deadline: _deadline,
        iconKey: _iconKey,
        category: _category,
        colorValue: _colorValue,
        note: _note.text,
        imagePath: _imagePath,
        removeImage: _removeImage,
      ),
    );
  }

  Future<void> _createCategory() async {
    final name = await showDialog<String>(
        context: context,
        builder: (_) => const _NameDialog(
            title: 'Nova categoria de meta', label: 'Nome da categoria'));
    if (name == null || !mounted) return;
    try {
      widget.onCreateCategory(name);
      setState(() {
        _categories.add(name.trim());
        _category = name.trim();
      });
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
    }
  }
}

class GoalContributionDialog extends StatefulWidget {
  const GoalContributionDialog({super.key, required this.goalName});

  final String goalName;

  @override
  State<GoalContributionDialog> createState() => _GoalContributionDialogState();
}

class _GoalContributionDialogState extends State<GoalContributionDialog> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Aportar em ${widget.goalName}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [BrlCentsInputFormatter()],
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
              _DialogError(_error),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final amount = parseMoney(_amount.text);
              if (amount == null || amount <= 0) {
                setState(() => _error = 'Informe um aporte maior que zero.');
                return;
              }
              Navigator.pop(context, amount);
            },
            child: const Text('Confirmar aporte'),
          ),
        ],
      );
}

class _TaskDialogState extends State<TaskDialog> {
  final _title = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nova tarefa'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Título')),
              _DialogError(_error),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().isEmpty) {
                setState(() => _error = 'Informe o título da tarefa.');
                return;
              }
              Navigator.pop(context, _title.text);
            },
            child: const Text('Salvar tarefa'),
          ),
        ],
      );
}

class _DialogError extends StatelessWidget {
  const _DialogError(this.message);

  final String? message;

  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        );
}

int? parseMoney(String raw) {
  return parseMoneyInput(raw);
}

int? parseSignedMoney(String raw) {
  return parseMoneyInput(raw, allowNegative: true);
}

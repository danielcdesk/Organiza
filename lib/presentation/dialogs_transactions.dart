part of 'dialogs.dart';

class TransactionInput {
  const TransactionInput({
    required this.accountId,
    required this.destinationAccountId,
    required this.type,
    required this.amountInCents,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.occurredOn,
    required this.scheduleType,
    required this.repeatCount,
    this.incomeSource,
    this.essentialityOverride,
  });
  final String accountId;
  final String? destinationAccountId;
  final TransactionType type;
  final int amountInCents;
  final String description;
  final String category;
  final String subcategory;
  final DateTime occurredOn;
  final TransactionScheduleType scheduleType;
  final int repeatCount;
  final String? incomeSource;
  final ExpenseEssentiality? essentialityOverride;
}

const budgetCategories = <String>[
  'Alimentação',
  'Moradia',
  'Transporte',
  'Contas e serviços',
  'Compras',
  'Família',
  'Impostos',
  'Pets',
  'Lazer',
  'Saúde',
  'Educação',
  'Outros',
];

const incomeCategories = <String>[
  'Salário',
  'Freelance',
  'Benefícios',
  'Rendimentos',
  'Vendas',
  'Reembolsos',
  'Outros',
];

const categorySubcategories = <String, List<String>>{
  'Alimentação': ['Mercado', 'Restaurantes', 'Delivery', 'Café'],
  'Moradia': ['Aluguel', 'Condomínio', 'Energia', 'Internet', 'Manutenção'],
  'Transporte': [
    'Combustível',
    'Aplicativos',
    'Transporte público',
    'Manutenção'
  ],
  'Contas e serviços': ['Água', 'Energia', 'Internet', 'Telefone', 'Seguros'],
  'Compras': ['Roupas', 'Eletrônicos', 'Casa', 'Cuidados pessoais'],
  'Família': ['Filhos', 'Pais', 'Mesada', 'Cuidados'],
  'Impostos': ['IPTU', 'IPVA', 'Imposto de renda', 'Taxas'],
  'Pets': ['Ração', 'Veterinário', 'Banho e tosa', 'Acessórios'],
  'Lazer': ['Streaming', 'Viagens', 'Eventos', 'Hobbies'],
  'Saúde': ['Farmácia', 'Consultas', 'Exames', 'Academia'],
  'Educação': ['Cursos', 'Livros', 'Material'],
  'Salário': ['Salário mensal', 'Adiantamento', '13º salário', 'Bônus'],
  'Freelance': ['Projeto', 'Consultoria', 'Serviço'],
  'Benefícios': ['Vale-refeição', 'Vale-alimentação', 'Auxílio'],
  'Rendimentos': ['Juros', 'Dividendos', 'Aluguel', 'Resgate'],
  'Vendas': ['Produto', 'Bem usado', 'Comissão'],
  'Reembolsos': ['Trabalho', 'Saúde', 'Compra cancelada'],
  'Transferência': ['Entre contas'],
  'Outros': ['Geral', 'Presentes', 'Imprevistos'],
};

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({
    super.key,
    this.initialType = TransactionType.expense,
    required this.accounts,
    required this.categories,
    required this.subcategories,
    required this.onCreateCategory,
    required this.onCreateSubcategory,
  });

  final TransactionType initialType;
  final List<Account> accounts;
  final List<FinanceCategory> categories;
  final List<FinanceSubcategory> subcategories;
  final FinanceCategory Function(String name, TransactionType type)
      onCreateCategory;
  final FinanceSubcategory Function(
          String categoryName, String name, TransactionType type)
      onCreateSubcategory;

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  late String _accountId;
  String? _destinationId;
  late TransactionType _type;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _repeatCount = TextEditingController(text: '12');
  final _incomeSource = TextEditingController();
  ExpenseEssentiality? _essentialityOverride;
  late List<FinanceCategory> _categories;
  late List<FinanceSubcategory> _subcategories;
  late String _category;
  late String _subcategory;
  var _occurredOn = DateTime.now();
  var _scheduleType = TransactionScheduleType.single;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _accountId = widget.accounts.first.id;
    _categories = List.of(widget.categories);
    _subcategories = List.of(widget.subcategories);
    _resetCategory();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _repeatCount.dispose();
    _incomeSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(switch (_type) {
          TransactionType.expense => 'Nova despesa',
          TransactionType.income => 'Nova receita',
          TransactionType.transfer => 'Nova transferência',
        }),
        content: SizedBox(
          width: 500,
          height: 510,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionType>(
                  isExpanded: true,
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: TransactionType.values.map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value == TransactionType.income
                          ? 'Receita'
                          : value == TransactionType.expense
                              ? 'Despesa'
                              : 'Transferência'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() {
                    _type = value!;
                    _resetCategory();
                    if (_type != TransactionType.transfer) {
                      _destinationId = null;
                    } else {
                      _scheduleType = TransactionScheduleType.single;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Conta'),
                  items: widget.accounts
                      .map((account) => DropdownMenuItem(
                            value: account.id,
                            child: _AccountOption(account),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _accountId = value!;
                    if (_destinationId == value) _destinationId = null;
                  }),
                ),
                if (_type == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _destinationId,
                    decoration:
                        const InputDecoration(labelText: 'Conta de destino'),
                    items: widget.accounts
                        .where((account) => account.id != _accountId)
                        .map((account) => DropdownMenuItem(
                              value: account.id,
                              child: _AccountOption(account),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _destinationId = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                    controller: _description,
                    decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)')),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('${_type.name}-$_category'),
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: _categoriesForType(_type)
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _category = value!;
                        _subcategory = _subcategoriesFor(_category).first;
                        if (_type == TransactionType.income &&
                            _category.toLowerCase() == 'salário' &&
                            _scheduleType ==
                                TransactionScheduleType.installment) {
                          _scheduleType = TransactionScheduleType.single;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _type == TransactionType.transfer
                        ? null
                        : _createCategory,
                    tooltip: 'Criar categoria',
                    icon:
                        const Icon(Icons.create_new_folder_outlined, size: 18),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('subcategory-$_category-$_subcategory'),
                      initialValue: _subcategory,
                      decoration:
                          const InputDecoration(labelText: 'Subcategoria'),
                      items: _subcategoriesFor(_category)
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _subcategory = value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _type == TransactionType.transfer
                        ? null
                        : _createSubcategory,
                    tooltip: 'Criar subcategoria',
                    icon: const Icon(Icons.add_rounded, size: 19),
                  ),
                ]),
                const SizedBox(height: 12),
                if (_type == TransactionType.income) ...[
                  TextField(
                    controller: _incomeSource,
                    decoration: const InputDecoration(
                        labelText: 'Fonte da receita (opcional)'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_type == TransactionType.expense) ...[
                  DropdownButtonFormField<String>(
                    key:
                        ValueKey('essentiality-${_essentialityOverride?.name}'),
                    isExpanded: true,
                    initialValue: _essentialityOverride?.name ?? 'category',
                    decoration:
                        const InputDecoration(labelText: 'Essencialidade'),
                    items: const [
                      DropdownMenuItem(
                          value: 'category',
                          child: Text('Padrão da categoria')),
                      DropdownMenuItem(
                          value: 'essential', child: Text('Essencial')),
                      DropdownMenuItem(
                          value: 'nonEssential', child: Text('Não essencial')),
                      DropdownMenuItem(
                          value: 'unclassified',
                          child: Text('Não classificada')),
                    ],
                    onChanged: (value) => setState(() => _essentialityOverride =
                        value == 'category'
                            ? null
                            : ExpenseEssentiality.values.byName(value!)),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Data: ${shortDate(_occurredOn)}'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_type != TransactionType.transfer) ...[
                  DropdownButtonFormField<TransactionScheduleType>(
                    key: ValueKey(
                        'schedule-${_type.name}-$_category-${_scheduleType.name}'),
                    isExpanded: true,
                    initialValue: _scheduleType,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de lançamento'),
                    items: [
                      DropdownMenuItem(
                          value: TransactionScheduleType.single,
                          child: Text('Único')),
                      DropdownMenuItem(
                          value: TransactionScheduleType.recurring,
                          child: Text('Recorrente mensal')),
                      if (!(_type == TransactionType.income &&
                          _category.toLowerCase() == 'salário'))
                        DropdownMenuItem(
                            value: TransactionScheduleType.installment,
                            child: Text('Parcelado')),
                    ],
                    onChanged: (value) =>
                        setState(() => _scheduleType = value!),
                  ),
                  if (_scheduleType != TransactionScheduleType.single &&
                      !(_type == TransactionType.income &&
                          _category.toLowerCase() == 'salário')) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _repeatCount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText:
                            _scheduleType == TransactionScheduleType.installment
                                ? 'Número de parcelas'
                                : 'Quantidade de meses',
                        helperText: 'Entre 2 e 60',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [BrlCentsInputFormatter()],
                  decoration: InputDecoration(
                    labelText:
                        _scheduleType == TransactionScheduleType.installment
                            ? 'Valor total (R\$)'
                            : 'Valor (R\$)',
                  ),
                ),
                _DialogError(_error),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _submit, child: const Text('Salvar transação')),
        ],
      );

  void _submit() {
    final cents = parseMoney(_amount.text);
    final invalidTransfer =
        _type == TransactionType.transfer && _destinationId == null;
    final salaryRecurring = _type == TransactionType.income &&
        _category.toLowerCase() == 'salário' &&
        _scheduleType == TransactionScheduleType.recurring;
    final count =
        _scheduleType == TransactionScheduleType.single || salaryRecurring
            ? 1
            : int.tryParse(_repeatCount.text);
    if (cents == null ||
        cents <= 0 ||
        invalidTransfer ||
        count == null ||
        count < 1 ||
        count > 60) {
      setState(() => _error = invalidTransfer
          ? 'Escolha uma conta de destino diferente.'
          : 'Informe um valor maior que zero.');
      return;
    }
    Navigator.pop(
      context,
      TransactionInput(
        accountId: _accountId,
        destinationAccountId: _destinationId,
        type: _type,
        amountInCents: cents,
        description: _description.text,
        category: _category,
        subcategory: _subcategory,
        occurredOn: _occurredOn,
        scheduleType: _scheduleType,
        repeatCount: count,
        incomeSource:
            _type == TransactionType.income ? _incomeSource.text : null,
        essentialityOverride:
            _type == TransactionType.expense ? _essentialityOverride : null,
      ),
    );
  }

  List<String> _categoriesForType(TransactionType type) {
    if (type == TransactionType.transfer) return const ['Transferência'];
    final values = _categories
        .where((item) => item.type == type)
        .map((item) => item.name)
        .toList();
    return values.isEmpty ? const ['Outros'] : values;
  }

  List<String> _subcategoriesFor(String categoryName) {
    if (_type == TransactionType.transfer) return const ['Entre contas'];
    FinanceCategory? category;
    for (final item in _categories) {
      if (item.type == _type && item.name == categoryName) {
        category = item;
        break;
      }
    }
    if (category == null) return const ['Geral'];
    final values = _subcategories
        .where((item) => item.categoryId == category!.id)
        .map((item) => item.name)
        .toList();
    return values.isEmpty ? const ['Geral'] : values;
  }

  void _resetCategory() {
    _category = _categoriesForType(_type).first;
    _subcategory = _subcategoriesFor(_category).first;
  }

  Future<void> _createCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(
        title: 'Nova categoria',
        label: 'Nome da categoria',
      ),
    );
    if (name == null || !mounted) return;
    try {
      final category = widget.onCreateCategory(name, _type);
      setState(() {
        _categories.add(category);
        _category = category.name;
        _subcategory = 'Geral';
      });
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
    }
  }

  Future<void> _createSubcategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: 'Nova subcategoria',
        label: 'Dentro de $_category',
      ),
    );
    if (name == null || !mounted) return;
    try {
      final subcategory = widget.onCreateSubcategory(_category, name, _type);
      setState(() {
        _subcategories.add(subcategory);
        _subcategory = subcategory.name;
      });
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _occurredOn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null && mounted) setState(() => _occurredOn = value);
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption(this.account);

  final Account account;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: MediaQuery.sizeOf(context).width < 600 ? 130 : 220,
        child: Row(children: [
          InstitutionMark(
              institution: account.institution,
              customIconKey: account.customIconKey,
              size: 25),
          const SizedBox(width: 9),
          Expanded(
              child: Text(account.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.label),
            onSubmitted: (_) => _submit(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Criar')),
        ],
      );

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }
}

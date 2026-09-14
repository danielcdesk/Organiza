import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'shared_widgets.dart';

class AccountInput {
  const AccountInput(this.name, this.openingCents, this.institution);
  final String name;
  final int openingCents;
  final AccountInstitution institution;
}

class AccountDialog extends StatefulWidget {
  const AccountDialog({super.key});

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final _name = TextEditingController();
  final _balance = TextEditingController(text: '0,00');
  var _institution = AccountInstitution.generic;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nova conta'),
        content: SizedBox(
          width: 410,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AccountInstitution>(
                initialValue: _institution,
                decoration: const InputDecoration(labelText: 'Instituição'),
                items: AccountInstitution.values
                    .map(
                      (institution) => DropdownMenuItem(
                        value: institution,
                        child: Row(
                          children: [
                            InstitutionMark(institution: institution, size: 28),
                            const SizedBox(width: 10),
                            Text(institutionName(institution)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _institution = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 12),
              TextField(
                controller: _balance,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Saldo inicial (R\$)'),
              ),
              _DialogError(_error),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Salvar conta')),
        ],
      );

  void _submit() {
    final cents = parseMoney(_balance.text);
    if (_name.text.trim().isEmpty || cents == null) {
      setState(() => _error = 'Preencha o nome e informe um saldo válido.');
      return;
    }
    Navigator.pop(
      context,
      AccountInput(_name.text, cents, _institution),
    );
  }
}

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
    required this.accounts,
    required this.categories,
    required this.subcategories,
    required this.onCreateCategory,
    required this.onCreateSubcategory,
  });

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
  var _type = TransactionType.expense;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _repeatCount = TextEditingController(text: '12');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nova transação'),
        content: SizedBox(
          width: 500,
          height: 590,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionType>(
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
                    decoration: const InputDecoration(labelText: 'Descrição')),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                    initialValue: _scheduleType,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de lançamento'),
                    items: const [
                      DropdownMenuItem(
                          value: TransactionScheduleType.single,
                          child: Text('Único')),
                      DropdownMenuItem(
                          value: TransactionScheduleType.recurring,
                          child: Text('Recorrente mensal')),
                      DropdownMenuItem(
                          value: TransactionScheduleType.installment,
                          child: Text('Parcelado')),
                    ],
                    onChanged: (value) =>
                        setState(() => _scheduleType = value!),
                  ),
                  if (_scheduleType != TransactionScheduleType.single) ...[
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
    final count = _scheduleType == TransactionScheduleType.single
        ? 1
        : int.tryParse(_repeatCount.text);
    if (_description.text.trim().isEmpty ||
        cents == null ||
        cents <= 0 ||
        invalidTransfer ||
        count == null ||
        count < 1 ||
        count > 60) {
      setState(() => _error = invalidTransfer
          ? 'Escolha uma conta de destino diferente.'
          : 'Preencha a descrição e informe um valor maior que zero.');
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
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InstitutionMark(institution: account.institution, size: 25),
          const SizedBox(width: 9),
          Text(account.name),
        ],
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

class CardInput {
  const CardInput({
    required this.name,
    required this.brand,
    required this.lastFour,
    required this.limitInCents,
    required this.closingDay,
    required this.dueDay,
    required this.colorValue,
  });
  final String name;
  final CardBrand brand;
  final String lastFour;
  final int limitInCents;
  final int closingDay;
  final int dueDay;
  final int colorValue;
}

class CardDialog extends StatefulWidget {
  const CardDialog({super.key});

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  static const _colors = [
    Color(0xFF245943),
    Color(0xFFAE4F2D),
    Color(0xFF3F4F68),
    Color(0xFF6B4A82),
  ];

  final _name = TextEditingController();
  final _lastFour = TextEditingController();
  final _limit = TextEditingController();
  final _closingDay = TextEditingController(text: '10');
  final _dueDay = TextEditingController(text: '17');
  var _brand = CardBrand.visa;
  var _color = _colors.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _lastFour.dispose();
    _limit.dispose();
    _closingDay.dispose();
    _dueDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Novo cartão'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _name,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Nome do cartão')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CardBrand>(
                        initialValue: _brand,
                        decoration:
                            const InputDecoration(labelText: 'Bandeira'),
                        items: CardBrand.values
                            .map((brand) => DropdownMenuItem(
                                value: brand, child: Text(brandName(brand))))
                            .toList(),
                        onChanged: (value) => setState(() => _brand = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastFour,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Últimos 4 dígitos', counterText: ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _limit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Limite (R\$)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _dayField(_closingDay, 'Dia de fechamento')),
                    const SizedBox(width: 12),
                    Expanded(child: _dayField(_dueDay, 'Dia de vencimento')),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cor do cartão',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 9,
                    children: _colors.map((color) {
                      final selected = color == _color;
                      return InkWell(
                        onTap: () => setState(() => _color = color),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
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
          FilledButton(onPressed: _submit, child: const Text('Salvar cartão')),
        ],
      );

  Widget _dayField(TextEditingController controller, String label) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );

  void _submit() {
    final cents = parseMoney(_limit.text);
    final closing = int.tryParse(_closingDay.text);
    final due = int.tryParse(_dueDay.text);
    final validDays = closing != null &&
        due != null &&
        closing >= 1 &&
        closing <= 28 &&
        due >= 1 &&
        due <= 28;
    if (_name.text.trim().isEmpty ||
        _lastFour.text.length != 4 ||
        cents == null ||
        cents <= 0 ||
        !validDays) {
      setState(() =>
          _error = 'Revise nome, quatro dígitos, limite e dias entre 1 e 28.');
      return;
    }
    Navigator.pop(
      context,
      CardInput(
        name: _name.text,
        brand: _brand,
        lastFour: _lastFour.text,
        limitInCents: cents,
        closingDay: closing,
        dueDay: due,
        colorValue: _color.toARGB32(),
      ),
    );
  }
}

class CardPurchaseInput {
  const CardPurchaseInput({
    required this.cardId,
    required this.description,
    required this.amountInCents,
    required this.installments,
  });
  final String cardId;
  final String description;
  final int amountInCents;
  final int installments;
}

class CardPurchaseDialog extends StatefulWidget {
  const CardPurchaseDialog({
    super.key,
    required this.cards,
    this.initialCardId,
  });

  final List<CreditCard> cards;
  final String? initialCardId;

  @override
  State<CardPurchaseDialog> createState() => _CardPurchaseDialogState();
}

class _CardPurchaseDialogState extends State<CardPurchaseDialog> {
  late String _cardId;
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _installments = TextEditingController(text: '1');
  String? _error;

  @override
  void initState() {
    super.initState();
    _cardId = widget.initialCardId ?? widget.cards.first.id;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _installments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Registrar compra'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _cardId,
                decoration: const InputDecoration(labelText: 'Cartão'),
                items: widget.cards
                    .map((card) => DropdownMenuItem(
                        value: card.id,
                        child: Text('${card.name} •••• ${card.lastFour}')))
                    .toList(),
                onChanged: (value) => setState(() => _cardId = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _description,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Valor total (R\$)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _installments,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Parcelas'),
                    ),
                  ),
                ],
              ),
              _DialogError(_error),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Salvar compra')),
        ],
      );

  void _submit() {
    final cents = parseMoney(_amount.text);
    final installments = int.tryParse(_installments.text);
    if (_description.text.trim().isEmpty ||
        cents == null ||
        cents <= 0 ||
        installments == null ||
        installments < 1 ||
        installments > 48) {
      setState(() =>
          _error = 'Preencha a descrição, valor e parcelas entre 1 e 48.');
      return;
    }
    Navigator.pop(
      context,
      CardPurchaseInput(
        cardId: _cardId,
        description: _description.text,
        amountInCents: cents,
        installments: installments,
      ),
    );
  }
}

class InvestmentInput {
  const InvestmentInput({
    required this.name,
    required this.type,
    required this.investedAmountInCents,
    required this.currentValueInCents,
    required this.fixedIncomeType,
    required this.institutionName,
    required this.maturityDate,
  });

  final String name;
  final InvestmentType type;
  final int investedAmountInCents;
  final int currentValueInCents;
  final FixedIncomeType? fixedIncomeType;
  final String? institutionName;
  final DateTime? maturityDate;
}

class InvestmentDialog extends StatefulWidget {
  const InvestmentDialog({super.key});

  @override
  State<InvestmentDialog> createState() => _InvestmentDialogState();
}

class _InvestmentDialogState extends State<InvestmentDialog> {
  final _name = TextEditingController();
  final _invested = TextEditingController();
  final _current = TextEditingController();
  final _institution = TextEditingController();
  var _type = InvestmentType.fixedIncome;
  var _fixedIncomeType = FixedIncomeType.cdb;
  DateTime? _maturityDate;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _invested.dispose();
    _current.dispose();
    _institution.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Novo investimento'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InvestmentType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: InvestmentType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(investmentTypeIcon(type), size: 19),
                            const SizedBox(width: 10),
                            Text(investmentTypeName(type)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome ou código do ativo',
                  hintText: 'Ex.: Tesouro Selic 2029 ou IVVB11',
                ),
              ),
              const SizedBox(height: 12),
              if (_type == InvestmentType.fixedIncome) ...[
                DropdownButtonFormField<FixedIncomeType>(
                  initialValue: _fixedIncomeType,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de renda fixa'),
                  items: FixedIncomeType.values
                      .map((type) => DropdownMenuItem(
                          value: type, child: Text(fixedIncomeTypeName(type))))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _fixedIncomeType = value!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _institution,
                      decoration: const InputDecoration(
                        labelText: 'Instituição ou emissor',
                        hintText: 'Opcional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickMaturity,
                      icon: const Icon(Icons.event_outlined, size: 17),
                      label: Text(_maturityDate == null
                          ? 'Vencimento'
                          : shortDate(_maturityDate!)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _invested,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Total investido'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _current,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Saldo atual',
                        hintText: 'Opcional',
                      ),
                    ),
                  ),
                ],
              ),
              _DialogError(_error),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Salvar ativo')),
        ],
      );

  void _submit() {
    final invested = parseMoney(_invested.text);
    final current =
        _current.text.trim().isEmpty ? invested : parseMoney(_current.text);
    if (_name.text.trim().isEmpty ||
        invested == null ||
        invested <= 0 ||
        current == null ||
        current < 0) {
      setState(() => _error =
          'Informe o ativo, o total investido e um saldo atual válido.');
      return;
    }
    Navigator.pop(
      context,
      InvestmentInput(
        name: _name.text,
        type: _type,
        investedAmountInCents: invested,
        currentValueInCents: current,
        fixedIncomeType:
            _type == InvestmentType.fixedIncome ? _fixedIncomeType : null,
        institutionName:
            _institution.text.trim().isEmpty ? null : _institution.text.trim(),
        maturityDate:
            _type == InvestmentType.fixedIncome ? _maturityDate : null,
      ),
    );
  }

  Future<void> _pickMaturity() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _maturityDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 40),
    );
    if (value != null && mounted) setState(() => _maturityDate = value);
  }
}

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
      required this.category});
  final String name;
  final int amountInCents;
  final int billingDay;
  final String category;
}

class SubscriptionDialog extends StatefulWidget {
  const SubscriptionDialog({super.key, required this.categories});

  final List<String> categories;

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '10');
  late String _category;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category =
        widget.categories.contains('Lazer') ? 'Lazer' : widget.categories.first;
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
        title: const Text('Nova assinatura'),
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
                      decoration: const InputDecoration(
                          labelText: 'Valor mensal (R\$)'))),
              const SizedBox(width: 12),
              SizedBox(
                  width: 110,
                  child: TextField(
                      controller: _day,
                      keyboardType: TextInputType.number,
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
            category: _category));
  }
}

class BudgetDialog extends StatefulWidget {
  const BudgetDialog({super.key, required this.categories});

  final List<String> categories;

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late String _category;
  final _limit = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _category = widget.categories.first;
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
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: widget.categories
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _limit,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
  });

  final String name;
  final int targetInCents;
  final int initialSavedInCents;
  final DateTime? deadline;
  final String iconKey;
}

class FinancialGoalDialog extends StatefulWidget {
  const FinancialGoalDialog({super.key});

  @override
  State<FinancialGoalDialog> createState() => _FinancialGoalDialogState();
}

class _FinancialGoalDialogState extends State<FinancialGoalDialog> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _initial = TextEditingController(text: '0,00');
  DateTime? _deadline;
  var _iconKey = 'savings';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _initial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nova meta financeira'),
        content: SizedBox(
          width: 460,
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
                    decoration:
                        const InputDecoration(labelText: 'Objetivo (R\$)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _initial,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Já guardado (R\$)'),
                  ),
                ),
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
                ],
                onChanged: (value) => setState(() => _iconKey = value!),
              ),
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
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Criar meta')),
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
      ),
    );
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
  final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null || value.isNegative || value > 1000000000) return null;
  return (value * 100).round();
}

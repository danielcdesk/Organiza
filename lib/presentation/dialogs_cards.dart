part of 'dialogs.dart';

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
  const CardDialog({super.key, this.card});
  final CreditCard? card;

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
  void initState() {
    super.initState();
    final card = widget.card;
    if (card == null) return;
    _name.text = card.name;
    _lastFour.text = card.lastFour;
    _limit.text =
        (card.limitInCents / 100).toStringAsFixed(2).replaceAll('.', ',');
    _closingDay.text = card.closingDay.toString();
    _dueDay.text = card.dueDay.toString();
    _brand = card.brand;
    _color = Color(card.colorValue);
  }

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
          FilledButton(
              onPressed: _submit,
              child: Text(
                  widget.card == null ? 'Salvar cartão' : 'Salvar alterações')),
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
        closing <= 31 &&
        due >= 1 &&
        due <= 31;
    if (_name.text.trim().isEmpty ||
        _lastFour.text.length != 4 ||
        cents == null ||
        cents <= 0 ||
        !validDays) {
      setState(() =>
          _error = 'Revise nome, quatro dígitos, limite e dias entre 1 e 31.');
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
    required this.purchasedOn,
    required this.category,
    required this.subcategory,
  });
  final String cardId;
  final String description;
  final int amountInCents;
  final int installments;
  final DateTime purchasedOn;
  final String category;
  final String subcategory;
}

class CardPurchaseDialog extends StatefulWidget {
  const CardPurchaseDialog({
    super.key,
    required this.cards,
    this.initialCardId,
    this.purchase,
  });

  final List<CreditCard> cards;
  final String? initialCardId;
  final CardPurchase? purchase;

  @override
  State<CardPurchaseDialog> createState() => _CardPurchaseDialogState();
}

class _CardPurchaseDialogState extends State<CardPurchaseDialog> {
  late String _cardId;
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _installments = TextEditingController(text: '1');
  final _category = TextEditingController(text: 'Outros');
  final _subcategory = TextEditingController(text: 'Geral');
  DateTime _purchasedOn = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    final purchase = widget.purchase;
    _cardId = purchase?.cardId ?? widget.initialCardId ?? widget.cards.first.id;
    if (purchase != null) {
      _description.text = purchase.description;
      _amount.text = (purchase.amountInCents / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _installments.text = purchase.installments.toString();
      _category.text = purchase.category;
      _subcategory.text = purchase.subcategory;
      _purchasedOn = purchase.purchasedOn;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _installments.dispose();
    _category.dispose();
    _subcategory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.purchase == null ? 'Registrar compra' : 'Editar compra'),
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
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('Data da compra: ${shortDate(_purchasedOn)}'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _category,
                        decoration:
                            const InputDecoration(labelText: 'Categoria'))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: _subcategory,
                        decoration:
                            const InputDecoration(labelText: 'Subcategoria'))),
              ]),
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
          FilledButton(
              onPressed: _submit,
              child: Text(widget.purchase == null
                  ? 'Salvar compra'
                  : 'Salvar alterações')),
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
        purchasedOn:
            DateTime(_purchasedOn.year, _purchasedOn.month, _purchasedOn.day),
        category:
            _category.text.trim().isEmpty ? 'Outros' : _category.text.trim(),
        subcategory: _subcategory.text.trim().isEmpty
            ? 'Geral'
            : _subcategory.text.trim(),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchasedOn,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _purchasedOn = selected);
  }
}

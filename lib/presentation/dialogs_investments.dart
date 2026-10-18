part of 'dialogs.dart';

class InvestmentInput {
  const InvestmentInput({
    required this.name,
    required this.type,
    required this.investedAmountInCents,
    required this.currentValueInCents,
    required this.fixedIncomeType,
    required this.institutionName,
    required this.maturityDate,
    required this.quotedRateBasisPoints,
    required this.quotedRatePeriod,
    this.yieldPaymentDay,
  });

  final String name;
  final InvestmentType type;
  final int investedAmountInCents;
  final int currentValueInCents;
  final FixedIncomeType? fixedIncomeType;
  final String? institutionName;
  final DateTime? maturityDate;
  final int? quotedRateBasisPoints;
  final InvestmentRatePeriod? quotedRatePeriod;
  final int? yieldPaymentDay;
}

class InvestmentDialog extends StatefulWidget {
  const InvestmentDialog({super.key, this.position});

  final InvestmentPosition? position;

  @override
  State<InvestmentDialog> createState() => _InvestmentDialogState();
}

class _InvestmentDialogState extends State<InvestmentDialog> {
  final _name = TextEditingController();
  final _invested = TextEditingController();
  final _current = TextEditingController();
  final _institution = TextEditingController();
  final _quotedRate = TextEditingController();
  final _yieldDay = TextEditingController();
  var _type = InvestmentType.fixedIncome;
  var _fixedIncomeType = FixedIncomeType.cdb;
  var _ratePeriod = InvestmentRatePeriod.annual;
  DateTime? _maturityDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final position = widget.position;
    if (position == null) return;
    _name.text = position.name;
    _invested.text = _investmentMoneyInput(position.investedAmountInCents);
    _current.text = _investmentMoneyInput(position.currentValueInCents);
    _institution.text = position.institutionName ?? '';
    _type = position.type;
    _fixedIncomeType = position.fixedIncomeType ?? FixedIncomeType.cdb;
    _maturityDate = position.maturityDate;
    if (position.yieldPaymentDay != null) {
      _yieldDay.text = position.yieldPaymentDay.toString();
    }
    _ratePeriod = position.quotedRatePeriod ??
        (position.fixedIncomeType == FixedIncomeType.savings
            ? InvestmentRatePeriod.monthly
            : InvestmentRatePeriod.annual);
    if (position.quotedRateBasisPoints != null) {
      _quotedRate.text = (position.quotedRateBasisPoints! / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _invested.dispose();
    _current.dispose();
    _institution.dispose();
    _quotedRate.dispose();
    _yieldDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.position == null
            ? 'Novo investimento'
            : 'Editar investimento'),
        content: SizedBox(
          width: 460,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .68),
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<InvestmentType>(
                  isExpanded: true,
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
                    isExpanded: true,
                    initialValue: _fixedIncomeType,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de renda fixa'),
                    items: FixedIncomeType.values
                        .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(fixedIncomeTypeName(type))))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _fixedIncomeType = value!;
                      if (value == FixedIncomeType.savings) {
                        _ratePeriod = InvestmentRatePeriod.monthly;
                        if (_name.text.trim().isEmpty) _name.text = 'Poupança';
                      }
                    }),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Total aplicado (R\$)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _current,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor atual (R\$)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quotedRate,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Rentabilidade informada (%)',
                    hintText: 'Ex.: 0,5',
                    helperText: 'Opcional; não altera o valor atual',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InvestmentRatePeriod>(
                  isExpanded: true,
                  initialValue: _ratePeriod,
                  decoration:
                      const InputDecoration(labelText: 'Período da taxa'),
                  items: const [
                    DropdownMenuItem(
                        value: InvestmentRatePeriod.monthly,
                        child: Text('Ao mês')),
                    DropdownMenuItem(
                        value: InvestmentRatePeriod.annual,
                        child: Text('Ao ano')),
                  ],
                  onChanged: (value) => setState(() => _ratePeriod = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _yieldDay,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Dia do crédito do rendimento (opcional)',
                    hintText: 'Ex.: 10',
                    helperText: 'Para créditos mensais; informe de 1 a 31',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'O resultado acumulado é calculado pelo valor atual menos o total aplicado. A taxa informada é exibida separadamente.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                _DialogError(_error),
              ],
            )),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _submit,
              child: Text(widget.position == null
                  ? 'Salvar ativo'
                  : 'Salvar alterações')),
        ],
      );

  void _submit() {
    final invested = parseMoney(_invested.text);
    final current = parseMoney(_current.text);
    final quotedRate = _quotedRate.text.trim().isEmpty
        ? null
        : parseInvestmentRateBasisPoints(_quotedRate.text);
    final yieldDay = _yieldDay.text.trim().isEmpty
        ? null
        : int.tryParse(_yieldDay.text.trim());
    if (_name.text.trim().isEmpty ||
        invested == null ||
        invested <= 0 ||
        current == null ||
        current < 0 ||
        (_quotedRate.text.trim().isNotEmpty && quotedRate == null) ||
        (_yieldDay.text.trim().isNotEmpty &&
            (yieldDay == null || yieldDay < 1 || yieldDay > 31))) {
      setState(() => _error =
          'Informe o ativo, o total aplicado, o valor atual e uma taxa válida.');
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
        quotedRateBasisPoints: quotedRate,
        quotedRatePeriod: quotedRate == null ? null : _ratePeriod,
        yieldPaymentDay: yieldDay,
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

String _investmentMoneyInput(int cents) =>
    (cents / 100).toStringAsFixed(2).replaceAll('.', ',');

int? parseInvestmentRateBasisPoints(String raw) {
  final value =
      double.tryParse(raw.trim().replaceAll('%', '').replaceAll(',', '.'));
  if (value == null || value < -100 || value > 1000) return null;
  return (value * 100).round();
}

part of 'dialogs.dart';

class AccountInput {
  const AccountInput({
    required this.name,
    required this.openingCents,
    required this.institution,
    this.customInstitutionName,
    this.customIconKey,
  });

  final String name;
  final int openingCents;
  final AccountInstitution institution;
  final String? customInstitutionName;
  final String? customIconKey;
}

class TransactionEditDialog extends StatefulWidget {
  const TransactionEditDialog(
      {super.key, required this.item, required this.accounts});
  final TransactionRecord item;
  final List<Account> accounts;
  @override
  State<TransactionEditDialog> createState() => _TransactionEditDialogState();
}

class _TransactionEditDialogState extends State<TransactionEditDialog> {
  late final _amount = TextEditingController(
      text: (widget.item.amountInCents / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ','));
  late final _description =
      TextEditingController(text: widget.item.description);
  late final _category = TextEditingController(text: widget.item.category);
  late final _subcategory =
      TextEditingController(text: widget.item.subcategory);
  late String _accountId = widget.item.accountId;
  late DateTime _occurredOn = widget.item.occurredOn;
  TransactionSeriesScope _scope = TransactionSeriesScope.occurrence;
  String? _error;
  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _category.dispose();
    _subcategory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Editar lançamento'),
        content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.item.seriesId != null)
                DropdownButtonFormField<TransactionSeriesScope>(
                  initialValue: _scope,
                  decoration: const InputDecoration(labelText: 'Aplicar em'),
                  items: const [
                    DropdownMenuItem(
                        value: TransactionSeriesScope.occurrence,
                        child: Text('Somente esta')),
                    DropdownMenuItem(
                        value: TransactionSeriesScope.fromHere,
                        child: Text('Esta e as próximas')),
                    DropdownMenuItem(
                        value: TransactionSeriesScope.entireSeries,
                        child: Text('Todas')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _scope = value);
                  },
                ),
              const SizedBox(height: 18),
              TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor (R\$)')),
              const SizedBox(height: 14),
              TextField(
                  controller: _description,
                  decoration:
                      const InputDecoration(labelText: 'Descrição (opcional)')),
              TextField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Categoria')),
              TextField(
                  controller: _subcategory,
                  decoration: const InputDecoration(labelText: 'Subcategoria')),
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Conta'),
                items: [
                  for (final account in widget.accounts)
                    DropdownMenuItem(
                        value: account.id, child: Text(account.name))
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _accountId = value);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(
                    '${_occurredOn.day.toString().padLeft(2, '0')}/${_occurredOn.month.toString().padLeft(2, '0')}/${_occurredOn.year}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: _occurredOn,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200));
                  if (date != null) setState(() => _occurredOn = date);
                },
              ),
              _DialogError(_error),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                final cents = parseMoney(_amount.text);
                if (cents == null || cents <= 0 || cents >= 100000000000) {
                  setState(() => _error = 'Informe um valor válido.');
                  return;
                }
                Navigator.pop(
                    context,
                    TransactionEditInput(
                      amountInCents: cents,
                      description: _description.text,
                      category: _category.text,
                      subcategory: _subcategory.text,
                      accountId: _accountId,
                      occurredOn: _occurredOn,
                      scope: _scope,
                      destinationAccountId: widget.item.destinationAccountId,
                    ));
              },
              child: const Text('Salvar alteração'))
        ],
      );
}

class TransactionEditInput {
  const TransactionEditInput(
      {required this.amountInCents,
      required this.description,
      required this.category,
      required this.subcategory,
      required this.accountId,
      required this.occurredOn,
      required this.scope,
      required this.destinationAccountId});
  final int amountInCents;
  final String description, category, subcategory, accountId;
  final DateTime occurredOn;
  final TransactionSeriesScope scope;
  final String? destinationAccountId;
}

class AccountDialog extends StatefulWidget {
  const AccountDialog({
    super.key,
    this.account,
    this.currentBalanceCents,
  });

  final Account? account;
  final int? currentBalanceCents;

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class AccountBalanceDialog extends StatefulWidget {
  const AccountBalanceDialog(
      {super.key, required this.name, required this.currentCents});
  final String name;
  final int currentCents;
  @override
  State<AccountBalanceDialog> createState() => _AccountBalanceDialogState();
}

class _AccountBalanceDialogState extends State<AccountBalanceDialog> {
  late final TextEditingController _value;
  String? _error;
  @override
  void initState() {
    super.initState();
    _value =
        TextEditingController(text: _investmentMoneyInput(widget.currentCents));
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text('Ajustar saldo · ${widget.name}'),
          content: SizedBox(
              width: 380,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'O saldo atual será ajustado sem apagar suas movimentações.'),
                const SizedBox(height: 16),
                TextField(
                    controller: _value,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Novo saldo atual (R\$)')),
                _DialogError(_error),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  final cents = parseSignedMoney(_value.text);
                  if (cents == null || cents.abs() >= 100000000000) {
                    setState(() => _error = 'Informe um saldo válido.');
                    return;
                  }
                  Navigator.pop(context, cents);
                },
                child: const Text('Salvar saldo'))
          ]);
}

class _AccountDialogState extends State<AccountDialog> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _customName;
  late AccountInstitution _institution;
  late String? _customIconKey;
  String? _error;

  static const _customIcons = <String, (String, IconData)>{
    'wallet': ('Carteira', Icons.account_balance_wallet_rounded),
    'bank': ('Banco', Icons.account_balance_rounded),
    'payments': ('Pagamentos', Icons.payments_rounded),
    'savings': ('Poupança', Icons.savings_rounded),
    'business': ('Empresa', Icons.business_rounded),
    'store': ('Loja', Icons.storefront_rounded),
    'phone': ('Carteira digital', Icons.phone_android_rounded),
  };

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.name ?? '');
    _balance = TextEditingController(
      text: _investmentMoneyInput(
          widget.currentBalanceCents ?? (account == null ? 0 : 0)),
    );
    _institution = account?.institution ?? AccountInstitution.generic;
    _customName =
        TextEditingController(text: account?.customInstitutionName ?? '');
    _customIconKey = account?.customIconKey ?? 'wallet';
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _customName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.account == null ? 'Nova conta' : 'Editar conta'),
        content: SizedBox(
          width: 410,
          child: SingleChildScrollView(
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
                              InstitutionMark(
                                  institution: institution,
                                  customIconKey: _customIconKey,
                                  size: 28),
                              const SizedBox(width: 10),
                              Text(institutionName(institution)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _institution = value!),
                ),
                if (_institution == AccountInstitution.custom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customName,
                    decoration: const InputDecoration(
                      labelText: 'Nome do banco ou carteira',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Escolha um ícone',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customIcons.entries
                        .map((entry) => ChoiceChip(
                              label: Text(entry.value.$1),
                              avatar: Icon(entry.value.$2, size: 17),
                              selected: _customIconKey == entry.key,
                              onSelected: (_) =>
                                  setState(() => _customIconKey = entry.key),
                            ))
                        .toList(),
                  ),
                ],
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
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _submit,
              child: Text(widget.account == null
                  ? 'Salvar conta'
                  : 'Salvar alterações')),
        ],
      );

  void _submit() {
    final cents = parseSignedMoney(_balance.text);
    if (_name.text.trim().isEmpty || cents == null) {
      setState(() => _error = 'Preencha o nome e informe um saldo válido.');
      return;
    }
    if (_institution == AccountInstitution.custom &&
        _customName.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome do banco personalizado.');
      return;
    }
    Navigator.pop(
      context,
      AccountInput(
        name: _name.text,
        openingCents: cents,
        institution: _institution,
        customInstitutionName: _customName.text.trim(),
        customIconKey: _customIconKey,
      ),
    );
  }
}

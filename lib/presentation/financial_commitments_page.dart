import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'dialogs.dart' show parseMoney;
import 'shared_widgets.dart';
import 'recurring_obligations_section.dart';

class FinancialCommitmentsPage extends StatefulWidget {
  const FinancialCommitmentsPage(
      {super.key, required this.store, required this.hideValues});
  final OrganizaStore store;
  final bool hideValues;

  @override
  State<FinancialCommitmentsPage> createState() =>
      _FinancialCommitmentsPageState();
}

class _FinancialCommitmentsPageState extends State<FinancialCommitmentsPage> {
  String _money(int cents) =>
      widget.hideValues ? '••••' : FinancialRules.formatBrl(cents);

  @override
  Widget build(BuildContext context) => Column(children: [
        Panel(
          title: 'Dívidas',
          subtitle:
              'O principal reduz a dívida; só juros entram nas despesas analíticas',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                    onPressed: () => _openDebtDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova dívida'))),
            if (widget.store.debts.isEmpty)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Nenhuma dívida cadastrada')),
            for (final debt in widget.store.debts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(debt.name),
                subtitle: Text(
                    '${debt.installmentsRemaining} parcelas restantes · '
                    'Saldo devedor ${_money(debt.outstandingPrincipalInCents)}'),
                trailing: Wrap(spacing: 0, children: [
                  IconButton(
                      tooltip: 'Registrar parcela',
                      onPressed: debt.isActive
                          ? () {
                              widget.store.recordDebtInstallment(debt.id);
                              setState(() {});
                            }
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded)),
                  IconButton(
                      tooltip: 'Editar dívida',
                      onPressed: () => _openDebtDialog(debt),
                      icon: const Icon(Icons.edit_outlined)),
                  IconButton(
                      tooltip: 'Excluir dívida',
                      onPressed: () => _deleteDebt(debt),
                      icon: const Icon(Icons.delete_outline_rounded)),
                ]),
              ),
            if (widget.store.debtPayments.isNotEmpty) ...[
              const Divider(),
              const Text('Parcelas pagas'),
              for (final payment in widget.store.debtPayments)
                ListTile(
                  dense: true,
                  title: Text(
                      '${_money(payment.principalInCents + payment.interestInCents)} '
                      '· juros ${_money(payment.interestInCents)}'),
                  subtitle: Text(
                      '${payment.paidOn.day}/${payment.paidOn.month}/${payment.paidOn.year}'),
                  trailing: IconButton(
                      tooltip: 'Desfazer parcela',
                      onPressed: () {
                        widget.store.undoDebtInstallment(payment.id);
                        setState(() {});
                      },
                      icon: const Icon(Icons.undo_rounded)),
                ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        RecurringObligationsSection(
            store: widget.store, hideValues: widget.hideValues),
      ]);

  Future<void> _deleteDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Excluir dívida?'),
              content: const Text(
                  'Parcelas já pagas precisam ser estornadas antes.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Excluir')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    try {
      widget.store.deleteDebt(debt.id);
      setState(() {});
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openDebtDialog([Debt? debt]) async {
    if (widget.store.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Crie uma conta antes de cadastrar uma dívida.')));
      return;
    }
    final name = TextEditingController(text: debt?.name ?? '');
    final principal = TextEditingController(
        text: debt == null
            ? ''
            : FinancialRules.formatBrl(debt.originalPrincipalInCents)
                .replaceFirst('R\$ ', ''));
    final installment = TextEditingController(
        text: debt == null
            ? ''
            : FinancialRules.formatBrl(debt.installmentAmountInCents)
                .replaceFirst('R\$ ', ''));
    final interest = TextEditingController(
        text: debt == null
            ? '0'
            : (debt.monthlyInterestBasisPoints / 100).toStringAsFixed(2));
    final count =
        TextEditingController(text: '${debt?.installmentsRemaining ?? 12}');
    var accountId = debt?.accountId ?? widget.store.accounts.first.id;
    var due = debt?.firstDueOn ?? widget.store.clock.now();
    final saved = await showDialog<Debt>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: Text(debt == null ? 'Nova dívida' : 'Editar dívida'),
                  content: SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: name,
                            decoration:
                                const InputDecoration(labelText: 'Nome')),
                        if (debt == null)
                          TextField(
                              controller: principal,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Principal (R\$)')),
                        TextField(
                            controller: installment,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Parcela (R\$)')),
                        TextField(
                            controller: interest,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Juros mensais (%)')),
                        TextField(
                            controller: count,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Parcelas restantes')),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: accountId,
                          decoration: const InputDecoration(labelText: 'Conta'),
                          items: [
                            for (final account in widget.store.accounts)
                              DropdownMenuItem(
                                  value: account.id, child: Text(account.name))
                          ],
                          onChanged: (value) =>
                              update(() => accountId = value!),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final selected = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialDate: due);
                            if (selected != null) update(() => due = selected);
                          },
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                              'Primeiro vencimento: ${due.day}/${due.month}/${due.year}'),
                        ),
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () {
                          final original = debt?.originalPrincipalInCents ??
                              parseMoney(principal.text);
                          final installmentCents = parseMoney(installment.text);
                          final interestBps = ((double.tryParse(
                                          interest.text.replaceAll(',', '.')) ??
                                      -1) *
                                  100)
                              .round();
                          final remaining = int.tryParse(count.text);
                          if (name.text.trim().isEmpty ||
                              original == null ||
                              original <= 0 ||
                              installmentCents == null ||
                              installmentCents <= 0 ||
                              interestBps < 0 ||
                              interestBps > 10000 ||
                              remaining == null ||
                              remaining < 1 ||
                              remaining > 360) {
                            return;
                          }
                          Navigator.pop(
                              context,
                              Debt(
                                id: debt?.id ?? '',
                                name: name.text.trim(),
                                originalPrincipalInCents: original,
                                outstandingPrincipalInCents:
                                    debt?.outstandingPrincipalInCents ??
                                        original,
                                monthlyInterestBasisPoints: interestBps,
                                installmentAmountInCents: installmentCents,
                                firstDueOn: due,
                                installmentsRemaining: remaining,
                                accountId: accountId,
                                category: debt?.category ?? 'Empréstimos',
                                isActive: debt?.isActive ?? true,
                                createdAt:
                                    debt?.createdAt ?? widget.store.clock.now(),
                              ));
                        },
                        child: const Text('Salvar')),
                  ],
                )));
    name.dispose();
    principal.dispose();
    installment.dispose();
    interest.dispose();
    count.dispose();
    if (saved == null || !mounted) return;
    try {
      if (debt == null) {
        widget.store.addDebt(
            name: saved.name,
            principalInCents: saved.originalPrincipalInCents,
            monthlyInterestBasisPoints: saved.monthlyInterestBasisPoints,
            installmentAmountInCents: saved.installmentAmountInCents,
            firstDueOn: saved.firstDueOn,
            installments: saved.installmentsRemaining,
            accountId: saved.accountId,
            category: saved.category);
      } else {
        widget.store.editDebt(saved);
      }
      setState(() {});
    } on Object catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

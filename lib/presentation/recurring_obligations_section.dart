import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import '../domain/recurring_obligation_rules.dart';
import 'dialogs.dart' show parseMoney;
import 'shared_widgets.dart';

class RecurringObligationsSection extends StatefulWidget {
  const RecurringObligationsSection(
      {super.key, required this.store, required this.hideValues});
  final OrganizaStore store;
  final bool hideValues;
  @override
  State<RecurringObligationsSection> createState() =>
      _RecurringObligationsSectionState();
}

class _RecurringObligationsSectionState
    extends State<RecurringObligationsSection> {
  String _money(int cents) =>
      widget.hideValues ? '••••' : FinancialRules.formatBrl(cents);

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Contas recorrentes',
        subtitle: 'Estimativas entram na previsão; confirme pelo valor real',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nova conta recorrente'))),
          if (widget.store.recurringObligations.isEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Nenhuma conta recorrente cadastrada')),
          for (final item in widget.store.recurringObligations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('Próximo vencimento: '
                  '${item.nextDueOn.day}/${item.nextDueOn.month}/${item.nextDueOn.year}'
                  ' · estimado ${_money(item.estimatedAmountInCents)}'),
              trailing: Wrap(children: [
                IconButton(
                    tooltip: 'Confirmar conta',
                    onPressed: item.isActive ? () => _confirm(item) : null,
                    icon: const Icon(Icons.check_circle_outline_rounded)),
                IconButton(
                    tooltip: item.isActive ? 'Pausar conta' : 'Reativar conta',
                    onPressed: () {
                      widget.store.editRecurringObligation(
                          _copy(item, isActive: !item.isActive));
                      setState(() {});
                    },
                    icon: Icon(item.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded)),
                IconButton(
                    tooltip: 'Editar conta recorrente',
                    onPressed: () => _edit(item),
                    icon: const Icon(Icons.edit_outlined)),
                IconButton(
                    tooltip: 'Excluir conta recorrente',
                    onPressed: () => _delete(item),
                    icon: const Icon(Icons.delete_outline_rounded)),
              ]),
            ),
          if (widget.store.transactions.any(
              (transaction) => transaction.recurringObligationId != null)) ...[
            const Divider(),
            const Text('Pagamentos confirmados'),
            for (final transaction in widget.store.transactions
                .where((item) => item.recurringObligationId != null))
              ListTile(
                dense: true,
                title: Text(transaction.description),
                subtitle: Text(_money(transaction.amountInCents)),
                trailing: IconButton(
                  tooltip: 'Desfazer conta confirmada',
                  onPressed: widget.store.recurringObligations.any((item) =>
                          item.id == transaction.recurringObligationId)
                      ? () {
                          widget.store.undoRecurringObligationConfirmation(
                              transaction.id);
                          setState(() {});
                        }
                      : null,
                  icon: const Icon(Icons.undo_rounded),
                ),
              ),
          ],
        ]),
      );

  RecurringObligation _copy(RecurringObligation item,
          {String? name,
          String? category,
          String? accountId,
          int? estimatedAmountInCents,
          int? billingDay,
          DateTime? nextDueOn,
          bool? isActive}) =>
      RecurringObligation(
          id: item.id,
          name: name ?? item.name,
          category: category ?? item.category,
          accountId: accountId ?? item.accountId,
          estimatedAmountInCents:
              estimatedAmountInCents ?? item.estimatedAmountInCents,
          billingDay: billingDay ?? item.billingDay,
          nextDueOn: nextDueOn ?? item.nextDueOn,
          isActive: isActive ?? item.isActive,
          createdAt: item.createdAt);

  Future<void> _confirm(RecurringObligation item) async {
    final amount = TextEditingController(
        text: FinancialRules.formatBrl(item.estimatedAmountInCents)
            .replaceFirst('R\$ ', ''));
    final cents = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Confirmar pagamento'),
              content: TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Valor pago (R\$)')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () {
                      final value = parseMoney(amount.text);
                      if (value == null || value <= 0) return;
                      Navigator.pop(context, value);
                    },
                    child: const Text('Confirmar pagamento')),
              ],
            ));
    amount.dispose();
    if (cents == null || !mounted) return;
    widget.store.confirmRecurringObligation(item.id, amountInCents: cents);
    setState(() {});
  }

  Future<void> _delete(RecurringObligation item) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Excluir conta recorrente?'),
              content: const Text(
                  'Os pagamentos anteriores continuam no histórico.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Excluir')),
              ],
            ));
    if (confirmed == true && mounted) {
      widget.store.deleteRecurringObligation(item.id);
      setState(() {});
    }
  }

  Future<void> _edit([RecurringObligation? item]) async {
    if (widget.store.accounts.isEmpty) return;
    final name = TextEditingController(text: item?.name ?? '');
    final category = TextEditingController(text: item?.category ?? 'Moradia');
    final amount = TextEditingController(
        text: item == null
            ? ''
            : FinancialRules.formatBrl(item.estimatedAmountInCents)
                .replaceFirst('R\$ ', ''));
    final day = TextEditingController(text: '${item?.billingDay ?? 10}');
    var accountId = item?.accountId ?? widget.store.accounts.first.id;
    var due = item?.nextDueOn ?? widget.store.clock.now();
    final value = await showDialog<RecurringObligation>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: Text(item == null
                      ? 'Nova conta recorrente'
                      : 'Editar conta recorrente'),
                  content: SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: name,
                            decoration:
                                const InputDecoration(labelText: 'Nome')),
                        TextField(
                            controller: category,
                            decoration:
                                const InputDecoration(labelText: 'Categoria')),
                        TextField(
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Valor estimado (R\$)')),
                        TextField(
                            controller: day,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Dia de cobrança (1–31)')),
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
                                  initialDate: due,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100));
                              if (selected != null) {
                                update(() => due = selected);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                                'Mês do próximo vencimento: ${due.month}/${due.year}')),
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () {
                          final cents = parseMoney(amount.text);
                          final billingDay = int.tryParse(day.text);
                          if (name.text.trim().isEmpty ||
                              cents == null ||
                              cents <= 0 ||
                              billingDay == null ||
                              billingDay < 1 ||
                              billingDay > 31) {
                            return;
                          }
                          final next = RecurringObligationRules.monthlyDue(due,
                              billingDay: billingDay, monthOffset: 0);
                          Navigator.pop(
                              context,
                              RecurringObligation(
                                id: item?.id ?? '',
                                name: name.text.trim(),
                                category: category.text.trim().isEmpty
                                    ? 'Outros'
                                    : category.text.trim(),
                                accountId: accountId,
                                estimatedAmountInCents: cents,
                                billingDay: billingDay,
                                nextDueOn: next,
                                isActive: item?.isActive ?? true,
                                createdAt:
                                    item?.createdAt ?? widget.store.clock.now(),
                              ));
                        },
                        child: const Text('Salvar')),
                  ],
                )));
    name.dispose();
    category.dispose();
    amount.dispose();
    day.dispose();
    if (value == null || !mounted) return;
    if (item == null) {
      widget.store.addRecurringObligation(
          name: value.name,
          category: value.category,
          accountId: value.accountId,
          estimatedAmountInCents: value.estimatedAmountInCents,
          billingDay: value.billingDay,
          nextDueOn: value.nextDueOn);
    } else {
      widget.store.editRecurringObligation(value);
    }
    setState(() {});
  }
}

part of 'cards_page.dart';

class _PurchasesPanel extends StatelessWidget {
  const _PurchasesPanel({
    required this.card,
    required this.purchases,
    required this.hideValues,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final CreditCard card;
  final List<CardPurchase> purchases;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final current =
        CreditCardRules.currentCyclePurchases(card, purchases, DateTime.now())
            .toList();
    return Panel(
      title: 'Compras da fatura',
      subtitle:
          '${current.length} lançamento${current.length == 1 ? '' : 's'} no ciclo atual',
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Registrar compra'),
      ),
      child: current.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Nenhuma compra neste ciclo',
              description:
                  'Registre compras manualmente para acompanhar a fatura.',
              actionLabel: 'Nova compra',
              onAction: onAdd,
            )
          : Column(
              children: [
                const _TableHeader(),
                ...current.map((purchase) => _PurchaseRow(
                      card: card,
                      purchase: purchase,
                      hideValues: hideValues,
                      onEdit: () => onEdit(purchase.id),
                      onDelete: () => onDelete(purchase.id),
                    )),
              ],
            ),
    );
  }
}

class _InvoiceHistoryPanel extends StatelessWidget {
  const _InvoiceHistoryPanel(
      {required this.invoices,
      required this.hideValues,
      required this.onPay,
      required this.onReverse});
  final List<CardInvoice> invoices;
  final bool hideValues;
  final ValueChanged<String> onPay;
  final ValueChanged<String> onReverse;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Histórico de faturas',
        subtitle:
            '${invoices.length} ciclo${invoices.length == 1 ? '' : 's'} registrado${invoices.length == 1 ? '' : 's'}',
        child: invoices.isEmpty
            ? const Text(
                'As faturas aparecerão aqui conforme as compras forem registradas.')
            : Column(
                children: invoices
                    .map((invoice) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(invoice.status == CardInvoiceStatus.paid
                              ? Icons.check_circle_outline
                              : invoice.status == CardInvoiceStatus.closed
                                  ? Icons.receipt_long_outlined
                                  : Icons.hourglass_empty_rounded),
                          title: Text(
                              'Fechamento ${shortDate(invoice.closingDate)} • venc. ${shortDate(invoice.dueDate)}'),
                          subtitle: Text(switch (invoice.status) {
                            CardInvoiceStatus.open => 'Aberta',
                            CardInvoiceStatus.closed => 'Fechada',
                            CardInvoiceStatus.paid =>
                              'Paga${invoice.paidOn == null ? '' : ' em ${shortDate(invoice.paidOn!)}'}',
                          }),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(hideValues
                                ? '••••••'
                                : FinancialRules.formatBrl(
                                    invoice.totalInCents)),
                            if (invoice.status == CardInvoiceStatus.closed)
                              TextButton(
                                  onPressed: () => onPay(invoice.id),
                                  child: const Text('Pagar')),
                            if (invoice.status == CardInvoiceStatus.paid)
                              IconButton(
                                  tooltip: 'Estornar pagamento',
                                  onPressed: () => onReverse(invoice.id),
                                  icon: const Icon(Icons.undo_rounded)),
                          ]),
                        ))
                    .toList()),
      );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text('COMPRA', style: _style(context))),
            Expanded(flex: 2, child: Text('DATA', style: _style(context))),
            Expanded(flex: 2, child: Text('PARCELAS', style: _style(context))),
            Expanded(
                flex: 2,
                child: Text('VALOR',
                    textAlign: TextAlign.right, style: _style(context))),
          ],
        ),
      );

  TextStyle _style(BuildContext context) => TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .7,
      );
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow(
      {required this.card,
      required this.purchase,
      required this.hideValues,
      required this.onEdit,
      required this.onDelete});

  final CreditCard card;
  final CardPurchase purchase;
  final bool hideValues;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final index = CreditCardRules.installmentIndex(card, purchase,
        CreditCardRules.currentCycleClosingDate(card, DateTime.now()));
    final installment = CreditCardRules.installmentAmount(purchase, index);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const IconTile(icon: Icons.shopping_bag_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    purchase.description,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(shortDate(purchase.purchasedOn))),
          Expanded(
              flex: 2,
              child: Text(purchase.installments == 1
                  ? 'À vista'
                  : '$index/${purchase.installments}')),
          Expanded(
            flex: 2,
            child: Text(
              hideValues ? '••••••' : FinancialRules.formatBrl(installment),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

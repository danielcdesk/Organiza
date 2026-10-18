part of 'cards_page.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAddCard,
    required this.onAddPurchase,
    required this.onEditCard,
    required this.onDeleteCard,
    required this.onEditPurchase,
    required this.onDeletePurchase,
    required this.onPayInvoice,
    required this.onReverseInvoicePayment,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAddCard;
  final ValueChanged<String?> onAddPurchase;
  final ValueChanged<String> onEditCard;
  final ValueChanged<String> onDeleteCard;
  final ValueChanged<String> onEditPurchase;
  final ValueChanged<String> onDeletePurchase;
  final ValueChanged<String> onPayInvoice;
  final ValueChanged<String> onReverseInvoicePayment;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  String? _selectedCardId;

  CreditCard? get _selectedCard {
    if (widget.store.creditCards.isEmpty) return null;
    return widget.store.creditCards.firstWhere(
      (card) => card.id == _selectedCardId,
      orElse: () => widget.store.creditCards.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _selectedCard;
    return ListView(
      padding: pagePadding(context),
      children: [
        PageHeading(
          eyebrow: 'Limites e faturas',
          title: 'Seus cartões',
          description: 'Acompanhe o ciclo atual sem armazenar dados sensíveis.',
          actions: [
            OutlinedButton.icon(
              onPressed: widget.onAddCard,
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: const Text('Novo cartão'),
            ),
            FilledButton.icon(
              onPressed:
                  card == null ? null : () => widget.onAddPurchase(card.id),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Registrar compra'),
            ),
            if (card != null) ...[
              IconButton(
                tooltip: 'Editar cartão',
                onPressed: () => widget.onEditCard(card.id),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir cartão',
                onPressed: () => widget.onDeleteCard(card.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        if (card == null)
          Panel(
            title: 'Seus cartões',
            subtitle: 'Comece com os dados essenciais',
            child: EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'Cadastre o primeiro cartão',
              description:
                  'Informe somente nome, bandeira, quatro últimos dígitos, limite e datas. Nunca armazenamos número completo ou CVV.',
              actionLabel: 'Adicionar cartão',
              onAction: widget.onAddCard,
            ),
          )
        else ...[
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.store.creditCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = widget.store.creditCards[index];
                final selected = item.id == card.id;
                return InkWell(
                  onTap: () => setState(() => _selectedCardId = item.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(item.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '${item.name}  •••• ${item.lastFour}',
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final visual =
                  _CreditCardVisual(card: card, hideValues: widget.hideValues);
              final summary = _CardSummary(
                card: card,
                purchases: widget.store.cardPurchases,
                hideValues: widget.hideValues,
              );
              if (constraints.maxWidth < 940) {
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: AspectRatio(aspectRatio: 1.586, child: visual),
                      ),
                    ),
                    const SizedBox(height: 14),
                    summary,
                  ],
                );
              }
              return SizedBox(
                height: 310,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AspectRatio(aspectRatio: 1.586, child: visual),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: SizedBox(height: 310, child: summary),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _PurchasesPanel(
            card: card,
            purchases: widget.store.cardPurchases,
            hideValues: widget.hideValues,
            onAdd: () => widget.onAddPurchase(card.id),
            onEdit: widget.onEditPurchase,
            onDelete: widget.onDeletePurchase,
          ),
          const SizedBox(height: 14),
          _InvoiceHistoryPanel(
            invoices: widget.store.cardInvoices
                .where((item) => item.cardId == card.id)
                .toList(),
            hideValues: widget.hideValues,
            onPay: widget.onPayInvoice,
            onReverse: widget.onReverseInvoicePayment,
          ),
        ],
      ],
    );
  }
}

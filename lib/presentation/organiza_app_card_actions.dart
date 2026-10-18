part of 'organiza_app.dart';

extension _OrganizaShellPart3 on _OrganizaShellState {
  Future<void> _deleteInvestment(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir investimento?',
      message: 'A posição manual será removida da carteira consolidada.',
    );
    if (confirmed) widget.store.deleteInvestment(id);
  }

  Future<void> _openCardDialog([String? cardId]) async {
    final card =
        widget.store.creditCards.where((item) => item.id == cardId).firstOrNull;
    final value = await showDialog<CardInput>(
      context: context,
      builder: (_) => CardDialog(card: card),
    );
    if (value == null || !mounted) return;
    try {
      if (card == null) {
        widget.store.addCreditCard(
          name: value.name,
          brand: value.brand,
          lastFour: value.lastFour,
          limitInCents: value.limitInCents,
          closingDay: value.closingDay,
          dueDay: value.dueDay,
          colorValue: value.colorValue,
        );
      } else {
        widget.store.editCreditCard(CreditCard(
          id: card.id,
          name: value.name,
          brand: value.brand,
          lastFour: value.lastFour,
          limitInCents: value.limitInCents,
          closingDay: value.closingDay,
          dueDay: value.dueDay,
          colorValue: value.colorValue,
          createdAt: card.createdAt,
        ));
      }
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o cartão.');
    }
  }

  Future<void> _openCardPurchaseDialog(
      [String? initialCardId, CardPurchase? purchase]) async {
    if (widget.store.creditCards.isEmpty) {
      _showError('Cadastre um cartão antes de registrar uma compra.');
      return;
    }
    final value = await showDialog<CardPurchaseInput>(
      context: context,
      builder: (_) => CardPurchaseDialog(
        cards: widget.store.creditCards,
        initialCardId: initialCardId,
        purchase: purchase,
      ),
    );
    if (value == null || !mounted) return;
    try {
      if (purchase == null) {
        widget.store.addCardPurchase(
          cardId: value.cardId,
          description: value.description,
          amountInCents: value.amountInCents,
          installments: value.installments,
          purchasedOn: value.purchasedOn,
          category: value.category,
          subcategory: value.subcategory,
        );
      } else {
        widget.store.editCardPurchase(
          id: purchase.id,
          cardId: value.cardId,
          description: value.description,
          amountInCents: value.amountInCents,
          installments: value.installments,
          purchasedOn: value.purchasedOn,
          category: value.category,
          subcategory: value.subcategory,
        );
      }
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a compra.');
    }
  }

  Future<void> _editCard(String id) => _openCardDialog(id);

  Future<void> _deleteCard(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir cartão?',
      message: 'Cartões com compras ou faturas não podem ser excluídos.',
    );
    if (!confirmed) return;
    try {
      widget.store.deleteCreditCard(id);
    } on StateError catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _editCardPurchase(String id) async {
    final purchase =
        widget.store.cardPurchases.where((item) => item.id == id).firstOrNull;
    if (purchase != null) await _openCardPurchaseDialog(null, purchase);
  }

  Future<void> _deleteCardPurchase(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir compra?',
      message: 'Compras de faturas pagas só podem ser removidas após estorno.',
    );
    if (!confirmed) return;
    try {
      widget.store.deleteCardPurchase(id);
    } on StateError catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _payCardInvoice(String invoiceId) async {
    if (widget.store.accounts.isEmpty) {
      _showError('Cadastre uma conta antes de pagar a fatura.');
      return;
    }
    final accountId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pagar fatura'),
        content: SizedBox(
          width: 420,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.store.accounts
                  .map((account) => ListTile(
                        title: Text(account.name),
                        onTap: () => Navigator.pop(context, account.id),
                      ))
                  .toList()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'))
        ],
      ),
    );
    if (accountId == null) return;
    try {
      widget.store.payCardInvoice(invoiceId, accountId);
    } on Object catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _reverseCardInvoicePayment(String invoiceId) async {
    final confirmed = await _confirmDelete(
      title: 'Estornar pagamento?',
      message:
          'A saída da conta será removida e a fatura voltará a ficar fechada.',
    );
    if (!confirmed) return;
    try {
      widget.store.reverseCardInvoicePayment(invoiceId);
    } on Object catch (error) {
      _showError(error.toString());
    }
  }
}

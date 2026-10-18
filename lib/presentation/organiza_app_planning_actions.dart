part of 'organiza_app.dart';

extension _OrganizaShellPart4 on _OrganizaShellState {
  Future<void> _openInvestmentDialog() => _showInvestmentDialog();

  Future<void> _editInvestment(String id) async {
    final position =
        widget.store.investments.where((item) => item.id == id).firstOrNull;
    if (position != null) await _showInvestmentDialog(position);
  }

  Future<void> _showInvestmentDialog([InvestmentPosition? position]) async {
    final value = await showDialog<InvestmentInput>(
      context: context,
      builder: (_) => InvestmentDialog(position: position),
    );
    if (value == null || !mounted) return;
    try {
      if (position == null) {
        widget.store.addInvestment(
          name: value.name,
          type: value.type,
          investedAmountInCents: value.investedAmountInCents,
          currentValueInCents: value.currentValueInCents,
          fixedIncomeType: value.fixedIncomeType,
          institutionName: value.institutionName,
          maturityDate: value.maturityDate,
          quotedRateBasisPoints: value.quotedRateBasisPoints,
          quotedRatePeriod: value.quotedRatePeriod,
          yieldPaymentDay: value.yieldPaymentDay,
        );
      } else {
        widget.store.updateInvestment(
          id: position.id,
          name: value.name,
          type: value.type,
          investedAmountInCents: value.investedAmountInCents,
          currentValueInCents: value.currentValueInCents,
          fixedIncomeType: value.fixedIncomeType,
          institutionName: value.institutionName,
          maturityDate: value.maturityDate,
          quotedRateBasisPoints: value.quotedRateBasisPoints,
          quotedRatePeriod: value.quotedRatePeriod,
          yieldPaymentDay: value.yieldPaymentDay,
        );
      }
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o ativo.');
    }
  }

  Future<void> _openBudgetDialog() async {
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.name)
        .toList();
    final value = await showDialog<BudgetInput>(
      context: context,
      builder: (_) => BudgetDialog(
          categories: categories,
          onCreateCategory: widget.store.addFinanceCategory),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addBudget(
        category: value.category,
        limitInCents: value.limitInCents,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o orçamento.');
    }
  }

  Future<void> _openSubscriptionDialog() => _showSubscriptionDialog();

  Future<void> _editSubscription(String id) async {
    final item =
        widget.store.subscriptions.where((value) => value.id == id).firstOrNull;
    if (item != null) await _showSubscriptionDialog(item);
  }

  Future<void> _showSubscriptionDialog([Subscription? existing]) async {
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.name)
        .toList();
    final value = await showDialog<SubscriptionInput>(
      context: context,
      builder: (_) =>
          SubscriptionDialog(categories: categories, subscription: existing),
    );
    if (value == null || !mounted) return;
    try {
      if (existing == null) {
        widget.store.addSubscription(
            name: value.name,
            amountInCents: value.amountInCents,
            billingDay: value.billingDay,
            category: value.category);
      } else {
        widget.store.updateSubscription(
            id: existing.id,
            name: value.name,
            amountInCents: value.amountInCents,
            billingDay: value.billingDay,
            category: value.category);
      }
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a assinatura.');
    }
  }
}

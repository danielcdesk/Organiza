part of 'organiza_app.dart';

extension _OrganizaShellPart1 on _OrganizaShellState {
  Future<void> _toggleFullscreen() async {
    final next = !_isFullscreen;
    try {
      await windowManager.setFullScreen(next);
      if (mounted) _setShellState(() => _isFullscreen = next);
    } catch (_) {
      _showError('Tela cheia está disponível apenas no app para Windows.');
    }
  }

  Future<void> _openAccountDialog() async {
    final value = await showDialog<AccountInput>(
      context: context,
      builder: (_) => const AccountDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addAccount(
        value.name,
        value.openingCents,
        institution: value.institution,
        customInstitutionName: value.customInstitutionName,
        customIconKey: value.customIconKey,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a conta.');
    }
  }

  Future<void> _editAccountBalance(String id) async {
    final account =
        widget.store.accounts.where((item) => item.id == id).firstOrNull;
    if (account == null) return;
    final amount = await showDialog<int>(
        context: context,
        builder: (_) => AccountBalanceDialog(
            name: account.name,
            currentCents: FinancialRules.accountBalance(
                account, widget.store.transactions)));
    if (amount == null || !mounted) return;
    try {
      widget.store.setAccountCurrentBalance(id, amount);
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  Future<void> _editAccount(String id) async {
    final account =
        widget.store.accounts.where((item) => item.id == id).firstOrNull;
    if (account == null) return;
    final currentBalance =
        FinancialRules.accountBalance(account, widget.store.transactions);
    final value = await showDialog<AccountInput>(
      context: context,
      builder: (_) => AccountDialog(
        account: account,
        currentBalanceCents: currentBalance,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.updateAccount(
        id: account.id,
        name: value.name,
        currentBalanceInCents: value.openingCents,
        institution: value.institution,
        customInstitutionName: value.customInstitutionName,
        customIconKey: value.customIconKey,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível editar a conta.');
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    Account? account;
    for (final item in widget.store.accounts) {
      if (item.id == accountId) {
        account = item;
        break;
      }
    }
    if (account == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir ${account!.name}?'),
        content: const Text(
            'A conta só pode ser excluída quando não possui transações vinculadas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      widget.store.deleteAccount(accountId);
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível excluir a conta.');
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final transaction = widget.store.transactions
        .where((item) => item.id == transactionId)
        .firstOrNull;
    final recurringSalary = transaction?.category.toLowerCase() == 'salário' &&
        widget.store.salarySchedules
            .any((item) => item.id == transaction?.seriesId);
    final choice = await showDialog<_TransactionDeleteChoice>(
      context: context,
      builder: (_) => _TransactionDeleteDialog(
          isSeries: transaction?.seriesId != null, isSalary: recurringSalary),
    );
    if (choice == null || !mounted) return;
    if (choice.cancelSalary) {
      await _cancelSalarySchedule(transaction!.seriesId!);
      return;
    }
    final removed =
        widget.store.deleteTransaction(transactionId, scope: choice.scope);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(removed.length == 1
          ? 'Lançamento excluído.'
          : '${removed.length} lançamentos excluídos.'),
      action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => widget.store.restoreDeletedTransactions(removed)),
    ));
  }

  Future<void> _editTransaction(TransactionRecord item) async {
    final input = await showDialog<TransactionEditInput>(
        context: context,
        builder: (_) =>
            TransactionEditDialog(item: item, accounts: widget.store.accounts));
    if (input == null || !mounted) return;
    try {
      widget.store.updateTransactionSeries(
        id: item.id,
        amountInCents: input.amountInCents,
        description: input.description,
        category: input.category,
        subcategory: input.subcategory,
        accountId: input.accountId,
        destinationAccountId: input.destinationAccountId,
        occurredOn: input.occurredOn,
        scope: input.scope,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento atualizado.')));
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  Future<void> _deleteBudget(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir orçamento?',
      message: 'O limite mensal desta categoria será removido.',
    );
    if (confirmed) widget.store.deleteBudget(id);
  }

  Future<void> _cancelSalarySchedule(String id) async {
    final confirmed = await _confirmDelete(
        title: 'Cancelar salário recorrente?',
        message:
            'Novos meses não serão criados. Movimentações já registradas permanecem no histórico.');
    if (confirmed) widget.store.cancelSalarySchedule(id);
  }

  Future<void> _deleteSubscription(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir assinatura?',
      message: 'A cobrança recorrente deixará de aparecer no calendário.',
    );
    if (confirmed) widget.store.deleteSubscription(id);
  }

  Future<bool> _confirmDelete(
      {required String title, required String message}) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir')),
            ],
          ),
        ) ??
        false;
  }
}

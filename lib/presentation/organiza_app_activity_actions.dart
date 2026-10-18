part of 'organiza_app.dart';

extension _OrganizaShellPart2 on _OrganizaShellState {
  Future<void> _openTransactionDialog() async {
    if (widget.store.accounts.isEmpty) {
      _showError('Crie uma conta antes de registrar uma transação.');
      return;
    }
    final value = await showDialog<TransactionInput>(
      context: context,
      builder: (_) => TransactionDialog(
        accounts: widget.store.accounts,
        categories: widget.store.financeCategories,
        subcategories: widget.store.financeSubcategories,
        onCreateCategory: widget.store.addFinanceCategory,
        onCreateSubcategory: widget.store.addFinanceSubcategory,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addTransaction(
        accountId: value.accountId,
        destinationAccountId: value.destinationAccountId,
        type: value.type,
        amountInCents: value.amountInCents,
        description: value.description,
        category: value.category,
        subcategory: value.subcategory,
        occurredOn: value.occurredOn,
        scheduleType: value.scheduleType,
        repeatCount: value.repeatCount,
        incomeSource: value.incomeSource,
        essentialityOverride: value.essentialityOverride,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a transação.');
    }
  }

  Future<void> _openTaskDialog() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => const TaskDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addTask(value);
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a tarefa.');
    }
  }

  Future<void> _deleteTask(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir tarefa?',
      message: 'A tarefa será removida da sua lista local.',
    );
    if (confirmed) widget.store.deleteTask(id);
  }

  Future<void> _openShoppingDialog() async {
    final value = await showDialog<ShoppingInput>(
      context: context,
      builder: (_) => const ShoppingDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addShoppingItem(
        name: value.name,
        quantity: value.quantity,
        estimatedUnitPriceInCents: value.estimatedUnitPriceInCents,
        priority: value.priority,
        imagePath: value.imagePath,
        description: value.description,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o item.');
    }
  }

  Future<void> _deleteShoppingItem(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir item?',
      message: 'O item será removido da lista de desejos/compras.',
    );
    if (confirmed) widget.store.deleteShoppingItem(id);
  }

  Future<void> _openProfileDialog() async {
    final value = await showDialog<ProfileInput>(
      context: context,
      builder: (_) => ProfileDialog(
        initialName: widget.store.profileName,
        initialIncomeInCents: widget.store.profileIncomeInCents,
        initialPhotoPath: widget.store.profilePhotoPath,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.saveProfile(
        name: value.name,
        incomeInCents: value.incomeInCents,
        photoPath: value.photoPath,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o perfil.');
    }
  }

  Future<void> _openFinancialGoalDialog() async {
    final value = await showDialog<FinancialGoalInput>(
      context: context,
      builder: (_) => FinancialGoalDialog(
          categories: widget.store.goalCategories,
          onCreateCategory: widget.store.addGoalCategory),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addFinancialGoal(
        name: value.name,
        targetInCents: value.targetInCents,
        initialSavedInCents: value.initialSavedInCents,
        deadline: value.deadline,
        iconKey: value.iconKey,
        category: value.category,
      );
    } on ArgumentError catch (error) {
      _showError(error.message?.toString() ?? 'Não foi possível criar a meta.');
    }
  }

  Future<void> _openGoalContributionDialog(FinancialGoal goal) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => GoalContributionDialog(goalName: goal.name),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.contributeToFinancialGoal(goal.id, value);
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o aporte.');
    }
  }

  Future<void> _deleteFinancialGoal(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir meta?',
      message: 'O progresso registrado nesta meta será removido.',
    );
    if (confirmed) widget.store.deleteFinancialGoal(id);
  }
}

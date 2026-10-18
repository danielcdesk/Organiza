part of 'organiza_app.dart';

extension _OrganizaShellPart5 on _OrganizaShellState {
  Future<void> _exportEncryptedBackup() async {
    final password = await _backupPasswordDialog(
      title: 'Criar backup protegido',
      confirm: true,
    );
    if (password == null) return;
    try {
      final file = await widget.store.exportEncryptedBackup(password);
      if (mounted) _showError('Backup salvo em ${file.path}');
    } on Object catch (error) {
      if (mounted) _showError('Não foi possível criar o backup: $error');
    }
  }

  Future<void> _restoreEncryptedBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['backup'],
      withData: false,
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null) return;
    final password = await _backupPasswordDialog(
      title: 'Restaurar backup protegido',
    );
    if (password == null) return;
    try {
      final safetyCopy = await widget.store.restoreEncryptedBackup(
        File(selectedPath),
        password,
      );
      if (mounted) {
        _showError(
            'Backup restaurado. Uma cópia do estado anterior foi salva em ${safetyCopy.path}.');
      }
    } on Object catch (error) {
      if (mounted) _showError('Não foi possível restaurar o backup: $error');
    }
  }

  Future<String?> _backupPasswordDialog({
    required String title,
    bool confirm = false,
  }) async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  helperText: 'Use pelo menos 8 caracteres.',
                ),
              ),
              if (confirm)
                TextField(
                  controller: confirmationController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final password = passwordController.text;
                if (password.length < 8 ||
                    (confirm && password != confirmationController.text)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                          confirm && password != confirmationController.text
                              ? 'As senhas não conferem.'
                              : 'A senha deve ter pelo menos 8 caracteres.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, password);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    } finally {
      passwordController.dispose();
      confirmationController.dispose();
    }
  }

  Future<void> _exportReport(DateTime month, bool includePending) async {
    try {
      final transactions = widget.store.transactions.where((item) =>
          item.occurredOn.year == month.year &&
          item.occurredOn.month == month.month &&
          (includePending || item.isSettled));
      final file = await const ReportExportService().exportTransactions(
        transactions,
        period: month,
      );
      if (!mounted) return;
      _showError('Relatório salvo em ${file.path}');
    } on FileSystemException {
      if (mounted) _showError('Não foi possível exportar o relatório.');
    }
  }

  Future<void> _openSearch() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SearchDialog(
        store: widget.store,
        onNavigate: (route) {
          Navigator.pop(context);
          _setShellState(() => _page = route);
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

part of 'basic_pages.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onDelete,
    required this.onEditBalance,
    required this.onEdit,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEditBalance;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) => _Page(
        heading: PageHeading(
          eyebrow: 'Bancos e carteiras',
          title: 'Contas',
          description: 'Saldos locais consolidados por conta.',
          actions: [_primaryAction('Nova conta', onAdd)],
        ),
        content: Panel(
          title: 'Contas cadastradas',
          subtitle:
              '${store.accounts.length} conta${store.accounts.length == 1 ? '' : 's'}',
          child: store.accounts.isEmpty
              ? EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Nenhuma conta',
                  description:
                      'Crie uma conta para registrar seu saldo inicial.',
                  actionLabel: 'Nova conta',
                  onAction: onAdd,
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth > 950
                      ? 3
                      : constraints.maxWidth > 620
                          ? 2
                          : 1;
                  return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: store.accounts.map((account) {
                        final transactions = store.transactions
                            .where((t) =>
                                t.accountId == account.id ||
                                t.destinationAccountId == account.id)
                            .toList();
                        final pending =
                            transactions.where((t) => !t.isSettled).length;
                        final currentBalance = FinancialRules.accountBalance(
                            account, store.transactions);
                        return SizedBox(
                            width: (constraints.maxWidth - 16 * (columns - 1)) /
                                columns,
                            child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        InstitutionMark(
                                            institution: account.institution,
                                            customIconKey:
                                                account.customIconKey,
                                            size: 44),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                            tooltip: 'Ações da conta',
                                            onSelected: (action) {
                                              if (action == 'edit') {
                                                onEdit(account.id);
                                              } else if (action == 'balance') {
                                                onEditBalance(account.id);
                                              } else {
                                                onDelete(account.id);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                      value: 'edit',
                                                      child:
                                                          Text('Editar conta')),
                                                  PopupMenuItem(
                                                      value: 'balance',
                                                      child:
                                                          Text('Editar saldo')),
                                                  PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                          'Excluir conta')),
                                                ]),
                                      ]),
                                      const SizedBox(height: 20),
                                      Text(account.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(
                                          institutionName(account.institution,
                                              account.customInstitutionName),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                      const SizedBox(height: 18),
                                      Text(
                                          hideValues
                                              ? '••••••'
                                              : FinancialRules.formatBrl(
                                                  currentBalance),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: currentBalance < 0
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .error
                                                      : null)),
                                      const SizedBox(height: 16),
                                      Text(
                                          '${transactions.length} lançamentos · $pending pendentes',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                          onPressed: () =>
                                              onEditBalance(account.id),
                                          icon: const Icon(Icons.tune_rounded,
                                              size: 17),
                                          label: const Text('Ajustar saldo')),
                                    ])));
                      }).toList());
                }),
        ),
      );
}

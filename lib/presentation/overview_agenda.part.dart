part of 'overview_widgets.dart';

class _PendingAgenda extends StatelessWidget {
  const _PendingAgenda(
      {required this.store,
      required this.summary,
      required this.hideValues,
      required this.onOpenTransactions});
  final OrganizaStore store;
  final CashFlowSummary summary;
  final bool hideValues;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Sua próxima ação',
        subtitle: summary.overdueCount > 0
            ? '${summary.overdueCount} pendência(s) em atraso'
            : 'Pagamentos e recebimentos por vencimento',
        trailing: TextButton(
            onPressed: onOpenTransactions, child: const Text('Ver todas')),
        child: summary.pending.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 27),
                child: Row(children: [
                  IconTile(
                      icon: Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Tudo em dia por aqui',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Você não tem lançamentos pendentes.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ])),
                ]))
            : Column(
                children: summary.pending.take(3).map((item) {
                final now = DateTime.now();
                final overdue = item.occurredOn
                    .isBefore(DateTime(now.year, now.month, now.day));
                final account = store.accounts
                    .where((a) => a.id == item.accountId)
                    .firstOrNull;
                final income = item.type == TransactionType.income;
                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      InstitutionMark(
                          institution: account?.institution ??
                              AccountInstitution.generic,
                          customIconKey: account?.customIconKey,
                          size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                item.description.isEmpty
                                    ? item.category
                                    : item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '${shortDate(item.occurredOn)}${overdue ? ' · Atrasado' : ''}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: overdue
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          ])),
                      const SizedBox(width: 8),
                      Text(
                          hideValues
                              ? '••••'
                              : FinancialRules.formatBrl(item.amountInCents),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: income
                                  ? Theme.of(context).colorScheme.secondary
                                  : null)),
                      Semantics(
                        button: true,
                        label: income
                            ? 'Confirmar recebimento'
                            : 'Confirmar pagamento',
                        child: IconButton(
                          tooltip: income
                              ? 'Confirmar recebimento'
                              : 'Confirmar pagamento',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: Text(income
                                          ? 'Confirmar recebimento?'
                                          : 'Confirmar pagamento?'),
                                      content: Text(
                                          'O lançamento será confirmado e o saldo de ${account?.name ?? 'sua conta'} será atualizado.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar')),
                                        FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Confirmar'))
                                      ],
                                    ));
                            if (confirmed != true || !context.mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            store.setTransactionSettled(item.id, true);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(SnackBar(
                                content: const Text('Lançamento confirmado.'),
                                action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () {
                                      if (store.transactions.any(
                                          (current) => current.id == item.id)) {
                                        store.setTransactionSettled(
                                            item.id, false);
                                      }
                                    })));
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 21),
                        ),
                      ),
                    ]));
              }).toList()),
      );
}

/// Each monthly column is a focusable button with a full textual equivalent.
/// No continuous animation is used; reduced motion is respected.

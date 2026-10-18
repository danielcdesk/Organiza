part of 'organiza_app.dart';

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.store, required this.onNavigate});

  final OrganizaStore store;
  final ValueChanged<AppRoute> onNavigate;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      title: TextField(
        autofocus: true,
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Transações, contas, cartões, ativos ou tarefas',
          suffixIcon:
              Padding(padding: EdgeInsets.all(11), child: _KeyHint('Esc')),
        ),
      ),
      content: SizedBox(
        width: 560,
        height: 340,
        child: _query.isEmpty
            ? const EmptyState(
                icon: Icons.manage_search_rounded,
                title: 'Busca local',
                description:
                    'Digite para encontrar seus dados sem sair do computador.',
              )
            : results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nada encontrado',
                    description: 'Tente outro termo de busca.',
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        leading: IconTile(icon: result.icon),
                        title: Text(result.title),
                        subtitle: Text(result.subtitle),
                        trailing:
                            const Icon(Icons.arrow_forward_rounded, size: 17),
                        onTap: () => widget.onNavigate(result.page),
                      );
                    },
                  ),
      ),
    );
  }

  List<_SearchResult> _results() {
    if (_query.isEmpty) return [];
    final results = <_SearchResult>[];
    for (final account in widget.store.accounts) {
      if (account.name.toLowerCase().contains(_query)) {
        results.add(_SearchResult(
            Icons.account_balance_outlined,
            account.name,
            'Conta · ${institutionName(account.institution, account.customInstitutionName)}',
            AppRoute.accounts));
      }
    }
    for (final transaction in widget.store.transactions) {
      if (transaction.description.toLowerCase().contains(_query)) {
        results.add(
          _SearchResult(Icons.receipt_long_outlined, transaction.description,
              'Movimentação', AppRoute.finances),
        );
      }
    }
    for (final card in widget.store.creditCards) {
      if (card.name.toLowerCase().contains(_query) ||
          card.lastFour.contains(_query)) {
        results.add(
          _SearchResult(Icons.credit_card_outlined, card.name,
              'Cartão •••• ${card.lastFour}', AppRoute.cards),
        );
      }
    }
    for (final task in widget.store.tasks) {
      if (task.title.toLowerCase().contains(_query)) {
        results.add(_SearchResult(Icons.task_alt_outlined, task.title, 'Tarefa',
            AppRoute.organization));
      }
    }
    for (final investment in widget.store.investments) {
      if (investment.name.toLowerCase().contains(_query)) {
        results.add(_SearchResult(
            investmentTypeIcon(investment.type),
            investment.name,
            investmentTypeName(investment.type),
            AppRoute.investments));
      }
    }
    for (final budget in widget.store.budgets) {
      if (budget.category.toLowerCase().contains(_query)) {
        results.add(_SearchResult(Icons.track_changes_rounded, budget.category,
            'Orçamento mensal', AppRoute.budgets));
      }
    }
    for (final goal in widget.store.financialGoals) {
      if (goal.name.toLowerCase().contains(_query)) {
        results.add(_SearchResult(
            Icons.flag_outlined, goal.name, 'Meta financeira', AppRoute.goals));
      }
    }
    return results.take(20).toList();
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: .45),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _SearchResult {
  const _SearchResult(this.icon, this.title, this.subtitle, this.page);
  final IconData icon;
  final String title;
  final String subtitle;
  final AppRoute page;
}

class _PageDefinition {
  const _PageDefinition(this.route, this.icon);
  final AppRoute route;
  String get label => route.label;
  final OrganizaIconName icon;
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _TransactionIntent extends Intent {
  const _TransactionIntent();
}

class _TaskIntent extends Intent {
  const _TaskIntent();
}

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}

class _FullscreenIntent extends Intent {
  const _FullscreenIntent();
}

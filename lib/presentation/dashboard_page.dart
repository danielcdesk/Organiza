import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/credit_card_rules.dart';
import '../domain/financial_rules.dart';
import 'organiza_theme.dart';
import 'shared_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onNewTransaction,
    required this.onNewTask,
    required this.onOpenCards,
    required this.onOpenBudgets,
    required this.onOpenSubscriptions,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onNewTransaction;
  final VoidCallback onNewTask;
  final VoidCallback onOpenCards;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenSubscriptions;

  String _money(int value) =>
      hideValues ? '••••••' : FinancialRules.formatBrl(value);

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 42),
        children: [
          PageHeading(
            eyebrow:
                '${sentenceCase(monthName(DateTime.now().month))} de ${DateTime.now().year}',
            title: 'Resumo financeiro',
            description: 'O que entrou, saiu e está disponível agora.',
            actions: [
              OutlinedButton.icon(
                onPressed: onNewTask,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Nova tarefa'),
              ),
              FilledButton.icon(
                onPressed: onNewTransaction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nova transação'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final balance = _BalanceOverview(
                balance: _money(store.balance),
                available: _money(store.availableToSpend),
              );
              final month = _MonthlySummary(
                incomes: _money(store.incomes),
                expenses: _money(store.expenses),
                result: _money(store.incomes - store.expenses),
                incomeValue: store.incomes,
                expenseValue: store.expenses,
              );
              if (constraints.maxWidth < 820) {
                return Column(
                  children: [balance, const SizedBox(height: 14), month],
                );
              }
              return SizedBox(
                height: 172,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: balance),
                    const SizedBox(width: 14),
                    Expanded(flex: 7, child: month),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _CommitmentsStrip(
            store: store,
            hideValues: hideValues,
            onOpenBudgets: onOpenBudgets,
            onOpenSubscriptions: onOpenSubscriptions,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final transactions = _TransactionsPanel(
                store: store,
                hideValues: hideValues,
                onAdd: onNewTransaction,
              );
              final accounts =
                  _AccountsPanel(store: store, hideValues: hideValues);
              if (constraints.maxWidth < 1000) {
                return Column(children: [
                  transactions,
                  const SizedBox(height: 14),
                  accounts,
                ]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: transactions),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: accounts),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = _CardSnapshot(
                store: store,
                hideValues: hideValues,
                onOpenCards: onOpenCards,
              );
              final tasks = _TasksPanel(store: store, onAdd: onNewTask);
              if (constraints.maxWidth < 1000) {
                return Column(
                    children: [cards, const SizedBox(height: 14), tasks]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards),
                  const SizedBox(width: 14),
                  Expanded(child: tasks),
                ],
              );
            },
          ),
        ],
      );
}

class _CommitmentsStrip extends StatelessWidget {
  const _CommitmentsStrip(
      {required this.store,
      required this.hideValues,
      required this.onOpenBudgets,
      required this.onOpenSubscriptions});
  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenSubscriptions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budgets = store.budgets
        .where((item) => item.year == now.year && item.month == now.month)
        .toList();
    final budgetLimit = budgets.fold(0, (sum, item) => sum + item.limitInCents);
    final budgetSpent = budgets.fold(
        0,
        (sum, item) =>
            sum + FinancialRules.budgetSpent(item, store.transactions));
    final subscriptions =
        store.subscriptions.where((item) => item.isActive).toList();
    final recurring =
        subscriptions.fold(0, (sum, item) => sum + item.amountInCents);
    final nextDay = subscriptions.isEmpty
        ? null
        : subscriptions
            .map((item) => item.billingDay)
            .reduce((a, b) => a < b ? a : b);
    String money(int value) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(value);
    return LayoutBuilder(builder: (context, constraints) {
      final cards = [
        _InsightCard(
            icon: Icons.track_changes_rounded,
            label: 'Orçamento usado',
            value: budgetLimit == 0
                ? 'Começar'
                : '${((budgetSpent / budgetLimit) * 100).round()}%',
            detail: budgetLimit == 0
                ? 'Defina seus limites do mês'
                : '${money(budgetSpent)} de ${money(budgetLimit)}',
            color: Theme.of(context).colorScheme.primary,
            onTap: onOpenBudgets),
        _InsightCard(
            icon: Icons.autorenew_rounded,
            label: 'Assinaturas',
            value: money(recurring),
            detail: nextDay == null
                ? 'Nenhuma recorrência ativa'
                : 'Próxima cobrança no dia $nextDay',
            color: const Color(0xFF7357C7),
            onTap: onOpenSubscriptions),
        _InsightCard(
            icon: Icons.savings_outlined,
            label: 'Taxa de economia',
            value: store.incomes == 0
                ? '—'
                : '${(((store.incomes - store.expenses) / store.incomes) * 100).round()}%',
            detail: 'Resultado sobre as entradas do mês',
            color: const Color(0xFF258A5A)),
      ];
      if (constraints.maxWidth < 820) {
        return Column(
            children: cards
                .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10), child: card))
                .toList());
      }
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
        const SizedBox(width: 10),
        Expanded(child: cards[2])
      ]);
    });
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.detail,
      required this.color,
      this.onTap});
  final IconData icon;
  final String label, value, detail;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(children: [
              IconTile(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 3),
                    Text(value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant))
                  ])),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, size: 18)
            ]),
          ),
        ),
      );
}

class _BalanceOverview extends StatelessWidget {
  const _BalanceOverview({required this.balance, required this.available});

  final String balance;
  final String available;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 84,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo consolidado',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balance,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$available disponível para gastar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({
    required this.incomes,
    required this.expenses,
    required this.result,
    required this.incomeValue,
    required this.expenseValue,
  });

  final String incomes;
  final String expenses;
  final String result;
  final int incomeValue;
  final int expenseValue;

  @override
  Widget build(BuildContext context) {
    final total = incomeValue + expenseValue;
    final incomeShare = total == 0 ? .5 : incomeValue / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movimento no mês',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _SummaryValue(
                    label: 'Entradas',
                    value: incomes,
                    color: OrganizaTheme.green,
                  ),
                ),
                Expanded(
                  child: _SummaryValue(
                    label: 'Saídas',
                    value: expenses,
                    color: OrganizaTheme.red,
                  ),
                ),
                Expanded(
                  child: _SummaryValue(label: 'Resultado', value: result),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: [
                  Expanded(
                    flex: (incomeShare * 100).round().clamp(1, 99),
                    child: Container(height: 4, color: OrganizaTheme.green),
                  ),
                  Expanded(
                    flex: ((1 - incomeShare) * 100).round().clamp(1, 99),
                    child: Container(height: 4, color: OrganizaTheme.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _AccountsPanel extends StatelessWidget {
  const _AccountsPanel({required this.store, required this.hideValues});

  final OrganizaStore store;
  final bool hideValues;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Suas contas',
        subtitle:
            '${store.accounts.length} cadastrada${store.accounts.length == 1 ? '' : 's'}',
        child: store.accounts.isEmpty
            ? const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Nenhuma conta',
                description: 'Cadastre uma conta para acompanhar seus saldos.',
              )
            : Column(
                children: store.accounts.take(4).map((account) {
                  return DataListRow(
                    icon: Icons.account_balance_outlined,
                    leading: InstitutionMark(institution: account.institution),
                    title: account.name,
                    subtitle: institutionName(account.institution),
                    value: hideValues
                        ? '••••••'
                        : FinancialRules.formatBrl(
                            FinancialRules.accountBalance(
                                account, store.transactions),
                          ),
                  );
                }).toList(),
              ),
      );
}

class _TransactionsPanel extends StatelessWidget {
  const _TransactionsPanel({
    required this.store,
    required this.hideValues,
    required this.onAdd,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Panel(
        title: 'Movimentações recentes',
        subtitle: 'Últimos lançamentos registrados',
        trailing: TextButton(onPressed: onAdd, child: const Text('Adicionar')),
        child: store.transactions.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Sem movimentações',
                description: 'Registre sua primeira receita ou despesa.',
                actionLabel: 'Nova transação',
                onAction: onAdd,
              )
            : Column(
                children: store.transactions.take(6).map((item) {
                  return TransactionListRow(item: item, hideValues: hideValues);
                }).toList(),
              ),
      );
}

class _CardSnapshot extends StatelessWidget {
  const _CardSnapshot({
    required this.store,
    required this.hideValues,
    required this.onOpenCards,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onOpenCards;

  @override
  Widget build(BuildContext context) {
    final card = store.creditCards.firstOrNull;
    final invoice = card == null
        ? 0
        : CreditCardRules.currentInvoiceTotal(
            card, store.cardPurchases, DateTime.now());
    return Panel(
      title: 'Cartões',
      subtitle: card == null
          ? 'Controle de limite e fatura'
          : '${card.name} •••• ${card.lastFour}',
      trailing: TextButton(
          onPressed: onOpenCards,
          child: Text(card == null ? 'Começar' : 'Ver cartões')),
      child: card == null
          ? const EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'Nenhum cartão',
              description: 'Cadastre cartões sem armazenar dados sensíveis.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fatura em aberto',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(
                  hideValues ? '••••••' : FinancialRules.formatBrl(invoice),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: CreditCardRules.usageRatio(
                      card, store.cardPurchases, DateTime.now()),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text('Limite usado',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const Spacer(),
                    Text('Fecha dia ${card.closingDay}'),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TasksPanel extends StatelessWidget {
  const _TasksPanel({required this.store, required this.onAdd});

  final OrganizaStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final pending = store.tasks.where((task) => !task.isDone).toList();
    return Panel(
      title: 'Tarefas',
      subtitle: '${pending.length} pendente${pending.length == 1 ? '' : 's'}',
      trailing: IconButton(
          onPressed: onAdd,
          tooltip: 'Nova tarefa',
          icon: const Icon(Icons.add_rounded)),
      child: pending.isEmpty
          ? const EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Tudo em dia',
              description: 'Nenhuma tarefa pendente.',
            )
          : Column(
              children: pending.take(3).map((task) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: task.isDone,
                  onChanged: (value) {
                    if (value != null) store.toggleTask(task, value);
                  },
                  title: Text(task.title),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
    );
  }
}

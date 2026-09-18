import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../application/organiza_store.dart';
import '../domain/cash_flow_summary.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'organiza_theme.dart';
import 'shared_widgets.dart';

class CashFlowWorkspace extends StatelessWidget {
  const CashFlowWorkspace(
      {super.key,
      required this.store,
      required this.hideValues,
      required this.onOpenTransactions});
  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    final summary = CashFlowSummary(store.transactions, DateTime.now());
    final evolution =
        CashFlowChart(transactions: store.transactions, hideValues: hideValues);
    final agenda = _PendingAgenda(
        store: store,
        summary: summary,
        hideValues: hideValues,
        onOpenTransactions: onOpenTransactions);
    return Column(children: [
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 880) {
          return Column(
              children: [evolution, const SizedBox(height: 16), agenda]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: evolution),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: agenda),
        ]);
      }),
      const SizedBox(height: 16),
      _Forecast(store: store, summary: summary, hideValues: hideValues),
    ]);
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast(
      {required this.store, required this.summary, required this.hideValues});
  final OrganizaStore store;
  final CashFlowSummary summary;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    String money(int cents) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(cents);
    final projected = summary.projectedBalance(store.balance);
    final tiles = [
      (
        'A receber',
        money(summary.receivable),
        Icons.south_west_rounded,
        OrganizaTheme.green
      ),
      (
        'A pagar',
        money(summary.payable),
        Icons.north_east_rounded,
        OrganizaTheme.red
      ),
      (
        'Saldo previsto',
        money(projected),
        Icons.account_balance_wallet_outlined,
        projected < 0
            ? OrganizaTheme.red
            : Theme.of(context).colorScheme.onSurface
      ),
    ];
    return Panel(
        title: 'Até o fim do mês',
        subtitle:
            'Saldo atual + receitas pendentes − despesas pendentes, incluindo atrasos.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(
              builder: (context, constraints) => Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: tiles
                        .map((tile) => SizedBox(
                              width: constraints.maxWidth < 520
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 32) / 3,
                              child: Row(children: [
                                IconTile(icon: tile.$3, color: tile.$4),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(tile.$1,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(tile.$2,
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: tile.$4)),
                                    ]))
                              ]),
                            ))
                        .toList(),
                  )),
          const SizedBox(height: 16),
          Text(
              'Só considera lançamentos registrados. Assinaturas, faturas e salários ainda não lançados não entram nesta previsão.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]));
  }
}

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
                  const IconTile(
                      icon: Icons.check_circle_outline_rounded,
                      color: OrganizaTheme.green),
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
                                        ? OrganizaTheme.red
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
                              color: income ? OrganizaTheme.green : null)),
                      IconButton(
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
                              size: 21)),
                    ]));
              }).toList()),
      );
}

/// Each monthly column is a focusable button with a full textual equivalent.
/// No continuous animation is used; reduced motion is respected.
class CashFlowChart extends StatefulWidget {
  const CashFlowChart(
      {super.key, required this.transactions, required this.hideValues});
  final List<TransactionRecord> transactions;
  final bool hideValues;
  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart> {
  int _selected = 5;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final incomes = months
        .map((m) => FinancialRules.monthTotal(
            widget.transactions, m, TransactionType.income))
        .toList();
    final expenses = months
        .map((m) => FinancialRules.monthTotal(
            widget.transactions, m, TransactionType.expense))
        .toList();
    final maximum = [...incomes, ...expenses].fold<int>(1, math.max);
    String money(int value) =>
        widget.hideValues ? '••••••' : FinancialRules.formatBrl(value);
    final selected = months[_selected];
    return Panel(
        title: 'Seu dinheiro no tempo',
        subtitle: 'Últimos 6 meses · valores confirmados',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 18, runSpacing: 6, children: [
            Text('Entradas  ${money(incomes[_selected])}',
                style: const TextStyle(
                    color: OrganizaTheme.green, fontWeight: FontWeight.w600)),
            Text('Saídas  ${money(expenses[_selected])}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
              height: 146,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (i) {
                    final active = i == _selected;
                    return Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Tooltip(
                          message:
                              '${monthName(months[i].month)} ${months[i].year}: entradas ${money(incomes[i])}, saídas ${money(expenses[i])}',
                          child: Semantics(
                            button: true,
                            selected: active,
                            child: Material(
                                color: active
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _selected = i),
                                  child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          7, 12, 7, 8),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                                child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                  _bar(
                                                      context,
                                                      incomes[i] / maximum,
                                                      OrganizaTheme.green),
                                                  const SizedBox(width: 4),
                                                  _bar(
                                                      context,
                                                      expenses[i] / maximum,
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                                ])),
                                            const SizedBox(height: 10),
                                            Text(
                                                monthName(months[i].month)
                                                    .substring(0, 3),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: active
                                                        ? FontWeight.w800
                                                        : FontWeight.w500)),
                                          ])),
                                )),
                          )),
                    ));
                  }))),
          const SizedBox(height: 14),
          Text(
              '${sentenceCase(monthName(selected.month))} ${selected.year} · Resultado ${money(incomes[_selected] - expenses[_selected])}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]));
  }

  Widget _bar(BuildContext context, double ratio, Color color) => Expanded(
          child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                height: widget.hideValues ? 5 : math.max(3, 88 * value),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: ratio == 0 ? .15 : .85),
                    borderRadius: BorderRadius.circular(5)))),
      ));
}

class FirstStepsCard extends StatelessWidget {
  const FirstStepsCard({super.key, required this.onNewAccount});
  final VoidCallback onNewAccount;
  @override
  Widget build(BuildContext context) => Panel(
      title: 'Seu ponto de partida',
      subtitle: 'Organize o presente. Planeje o próximo passo.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            '1. Cadastre uma conta e seu saldo atual.\n2. Registre receitas e despesas.\n3. Defina um limite mensal e uma meta.',
            style: TextStyle(height: 1.9)),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: onNewAccount,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar primeira conta')),
      ]));
}

class BudgetWatch extends StatelessWidget {
  const BudgetWatch(
      {super.key,
      required this.store,
      required this.hideValues,
      required this.onOpen});
  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budgets = store.budgets
        .where((b) =>
            b.year == now.year && b.month == now.month && b.limitInCents > 0)
        .toList()
      ..sort((a, b) =>
          (FinancialRules.budgetSpent(b, store.transactions) / b.limitInCents)
              .compareTo(FinancialRules.budgetSpent(a, store.transactions) /
                  a.limitInCents));
    if (budgets.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Panel(
          title: 'De olho nos limites',
          subtitle: 'Categorias mais próximas do orçamento mensal',
          trailing:
              TextButton(onPressed: onOpen, child: const Text('Planejar')),
          child: Column(
              children: budgets.take(3).map((budget) {
            final spent =
                FinancialRules.budgetSpent(budget, store.transactions);
            final ratio = spent / budget.limitInCents;
            final color = ratio >= 1
                ? OrganizaTheme.red
                : ratio >= .8
                    ? Theme.of(context).colorScheme.primary
                    : OrganizaTheme.green;
            return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Text(budget.category,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    Text(
                        hideValues
                            ? '••••'
                            : '${(ratio * 100).round()}%${ratio > 1 ? ' · Acima do limite' : ''}',
                        style: TextStyle(fontSize: 12, color: color))
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: hideValues ? 0 : ratio.clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                      color: color),
                  const SizedBox(height: 6),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          hideValues
                              ? 'Valores ocultos'
                              : '${FinancialRules.formatBrl(spent)} de ${FinancialRules.formatBrl(budget.limitInCents)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))),
                ]));
          }).toList()),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/organiza_store.dart';
import '../domain/financial_planning.dart';
import '../domain/financial_health.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';
import 'dialogs.dart' show parseMoney;
import 'input_formatters.dart';

class MonthlyPlanningPage extends StatefulWidget {
  const MonthlyPlanningPage({
    super.key,
    required this.store,
    required this.hideValues,
  });

  final OrganizaStore store;
  final bool hideValues;

  @override
  State<MonthlyPlanningPage> createState() => _MonthlyPlanningPageState();
}

class _MonthlyPlanningPageState extends State<MonthlyPlanningPage> {
  late DateTime _month = DateTime.utc(
      widget.store.clock.now().year, widget.store.clock.now().month);

  static const _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  String _money(int cents) =>
      widget.hideValues ? '••••' : FinancialRules.formatBrl(cents);

  @override
  Widget build(BuildContext context) {
    final summary = summarize(
      transactions: widget.store.reportTransactions,
      categories: widget.store.financeCategories,
      month: _month,
      excludedEssentialCategoryIds: const {},
    );
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .toList();
    final completeMonths = previousCompleteMonths(widget.store.clock.now());
    final reserve = calculateEmergencyReserve(
      completeMonths: [
        for (final month in completeMonths)
          summarize(
            transactions: widget.store.reportTransactions,
            categories: widget.store.financeCategories,
            month: month,
            excludedEssentialCategoryIds:
                widget.store.emergencyReserveExcludedCategoryIds,
          ),
      ],
      targetMonths: widget.store.emergencyReserveTargetMonths,
    );
    final health = calculateHealth(
      plan: summary,
      investmentsInCents: widget.store.investments
          .fold<int>(0, (sum, item) => sum + item.currentValueInCents),
      reserveBalanceInCents: widget.store.emergencyReserveBalanceInCents,
      reserveTargetInCents: reserve.targetInCents,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: 'Planejamento mensal',
          subtitle: 'Entradas e saídas pela competência do mês',
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                tooltip: 'Mês anterior',
                onPressed: () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Flexible(
                  child: Text('${_months[_month.month - 1]} ${_month.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                tooltip: 'Próximo mês',
                onPressed: () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
            _line('Renda prevista', widget.store.planningIncomeInCents),
            _line('Receitas registradas', summary.incomeInCents),
            _line('Despesas essenciais', summary.essentialExpensesInCents),
            _line(
                'Despesas não essenciais', summary.nonEssentialExpensesInCents),
            _line('Não classificadas', summary.unclassifiedExpensesInCents),
            const Divider(),
            _line('Sobra do mês', summary.surplusInCents),
            _line('Taxa de poupança', summary.savingsRateBasisPoints,
                percentage: true),
          ]),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Meta de reserva',
          subtitle:
              'Média dos últimos 3 meses completos × ${widget.store.emergencyReserveTargetMonths} meses',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _line('Custo essencial médio',
                reserve.averageMonthlyEssentialsInCents),
            _line('Alvo', reserve.targetInCents),
            _line('Reserva informada',
                widget.store.emergencyReserveBalanceInCents),
            LinearProgressIndicator(
                value: (health.reserveProgressBasisPoints / 10000).clamp(0, 1)),
            const SizedBox(height: 8),
            Text(widget.hideValues
                ? 'Comprometimento essencial: ••••'
                : 'Comprometimento essencial: ${(health.essentialIncomeRatioBasisPoints / 100).toStringAsFixed(2)}%'),
            Text(
                'Investimentos cadastrados: ${_money(health.investmentsInCents)}'),
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _openReserveSettings,
                  child: const Text('Ajustar reserva'),
                )),
          ]),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Categorias essenciais',
          subtitle:
              'Classifique uma vez; lançamentos antigos continuam no total',
          child: categories.isEmpty
              ? const Text('Nenhuma categoria de despesa')
              : Column(children: [
                  for (final category in categories)
                    Row(children: [
                      Expanded(child: Text(category.name)),
                      SizedBox(
                        width: 156,
                        child: DropdownButtonFormField<ExpenseEssentiality>(
                          isExpanded: true,
                          key: ValueKey(
                              'essentiality-${category.id}-${category.essentiality.name}'),
                          initialValue: category.essentiality,
                          decoration:
                              const InputDecoration(labelText: 'Classificação'),
                          items: const [
                            DropdownMenuItem(
                                value: ExpenseEssentiality.unclassified,
                                child: Text('Não classificada')),
                            DropdownMenuItem(
                                value: ExpenseEssentiality.essential,
                                child: Text('Essencial')),
                            DropdownMenuItem(
                                value: ExpenseEssentiality.nonEssential,
                                child: Text('Não essencial')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            widget.store.setFinanceCategoryEssentiality(
                                category.id, value);
                            setState(() {});
                          },
                        ),
                      ),
                    ]),
                ]),
        ),
      ],
    );
  }

  Widget _line(String label, int value, {bool percentage = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(widget.hideValues
              ? '••••'
              : percentage
                  ? '${(value / 100).toStringAsFixed(2)}%'
                  : _money(value)),
        ]),
      );

  Future<void> _openReserveSettings() async {
    final months = TextEditingController(
        text: '${widget.store.emergencyReserveTargetMonths}');
    final balance = TextEditingController(
        text: FinancialRules.formatBrl(
                widget.store.emergencyReserveBalanceInCents)
            .replaceFirst('R\$ ', ''));
    final excluded = {...widget.store.emergencyReserveExcludedCategoryIds};
    final expenseCategories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .toList();
    final result = await showDialog<(int, int, Set<String>)>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
                title: const Text('Ajustar reserva'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: months,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Meses de proteção')),
                  TextField(
                      controller: balance,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [BrlCentsInputFormatter()],
                      decoration: const InputDecoration(
                          labelText: 'Reserva atual (R\$)')),
                  const SizedBox(height: 12),
                  const Text('Excluir categorias do cálculo'),
                  SizedBox(
                    height: 180,
                    width: 330,
                    child: ListView(children: [
                      for (final category in expenseCategories)
                        CheckboxListTile(
                          dense: true,
                          title: Text(category.name),
                          value: excluded.contains(category.id),
                          onChanged: (value) => updateDialog(() {
                            if (value == true) {
                              excluded.add(category.id);
                            } else {
                              excluded.remove(category.id);
                            }
                          }),
                        ),
                    ]),
                  ),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        final target = int.tryParse(months.text);
                        final cents = parseMoney(balance.text);
                        if (target == null ||
                            target < 1 ||
                            target > 120 ||
                            cents == null ||
                            cents < 0) {
                          return;
                        }
                        Navigator.pop(context, (target, cents, excluded));
                      },
                      child: const Text('Salvar')),
                ],
              )),
    );
    months.dispose();
    balance.dispose();
    if (result == null || !mounted) return;
    widget.store.updateEmergencyReserveSettings(
      targetMonths: result.$1,
      reserveBalanceInCents: result.$2,
      excludedCategoryIds: result.$3,
    );
    setState(() {});
  }
}

part of 'reports_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onExport,
  });

  final OrganizaStore store;
  final bool hideValues;
  final Future<void> Function(DateTime month, bool includePending) onExport;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  var _months = 6;
  var _includePending = false;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.store.clock.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    );
    final data = _monthlyDataUntil(
      widget.store.reportTransactions,
      _selectedMonth,
      _months,
      includePending: _includePending,
    );
    final monthTransactions = _transactionsForMonth(
      widget.store.reportTransactions,
      _selectedMonth,
    );
    final previousTransactions = _transactionsForMonth(
      widget.store.reportTransactions,
      previousMonth,
    );
    final visibleMonthTransactions = _visibleTransactions(
      monthTransactions,
      includePending: _includePending,
    );
    final visiblePreviousTransactions = _visibleTransactions(
      previousTransactions,
      includePending: _includePending,
    );
    final incomes = _typeTotal(
      visibleMonthTransactions,
      TransactionType.income,
    );
    final expenses = _typeTotal(
      visibleMonthTransactions,
      TransactionType.expense,
    );
    final previousIncomes = _typeTotal(
      visiblePreviousTransactions,
      TransactionType.income,
    );
    final previousExpenses = _typeTotal(
      visiblePreviousTransactions,
      TransactionType.expense,
    );
    final balance = incomes - expenses;
    final previousBalance = previousIncomes - previousExpenses;
    final hide = widget.hideValues;
    String money(int value) =>
        hide ? '••••••' : FinancialRules.formatBrl(value);

    return ListView(
      padding: pagePadding(context),
      children: [
        PageHeading(
          eyebrow: 'Análise financeira',
          title: 'Relatórios',
          description:
              'Resumo realizado de ${_longMonth(_selectedMonth)} e contexto histórico.',
          actions: [
            _MonthNavigator(
              month: _selectedMonth,
              canGoNext: _canGoNext,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onSelect: _selectMonth,
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onExport(
                _selectedMonth,
                _includePending,
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Exportar mês'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ReportModeBar(
          includePending: _includePending,
          onChanged: (value) => setState(() => _includePending = value),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ReportMetric(
                width: constraints.maxWidth,
                label: 'Entradas do mês',
                value: money(incomes),
                icon: Icons.south_west_rounded,
                color: const Color(0xFF258A5A),
                detail: hide
                    ? 'Comparação oculta'
                    : _comparisonLabel(incomes, previousIncomes),
                detailColor: _comparisonColor(incomes, previousIncomes),
              ),
              _ReportMetric(
                width: constraints.maxWidth,
                label: 'Saídas do mês',
                value: money(expenses),
                icon: Icons.north_east_rounded,
                color: const Color(0xFFC94D4D),
                detail: hide
                    ? 'Comparação oculta'
                    : _comparisonLabel(expenses, previousExpenses),
                detailColor: _comparisonColor(
                  expenses,
                  previousExpenses,
                  lowerIsBetter: true,
                ),
              ),
              _ReportMetric(
                width: constraints.maxWidth,
                label: 'Resultado',
                value: money(balance),
                icon: Icons.account_balance_outlined,
                color: balance >= 0
                    ? const Color(0xFF258A5A)
                    : const Color(0xFFC94D4D),
                detail: hide
                    ? 'Comparação oculta'
                    : _comparisonLabel(balance, previousBalance),
                detailColor: _comparisonColor(balance, previousBalance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Distribuição planejada',
          subtitle: 'Vigente em ${_longMonth(_selectedMonth)}',
          child: Builder(builder: (context) {
            final allocation = widget.store.allocationForMonth(_selectedMonth);
            if (allocation == null) {
              return const Text(
                  'Histórico de distribuição indisponível para este mês.');
            }
            if (hide) return const Text('Percentuais ocultos');
            return Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text('Essenciais ${allocation.essentialsPercent}%'),
                Text('Metas ${allocation.goalsPercent}%'),
                Text('Livre ${allocation.freePercent}%'),
              ],
            );
          }),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Evolução mensal',
          subtitle:
              'Resultado acumulado até ${monthName(_selectedMonth.month).toLowerCase()}',
          trailing: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 3, label: Text('3 meses')),
              ButtonSegment(value: 6, label: Text('6 meses')),
              ButtonSegment(value: 12, label: Text('12 meses')),
            ],
            selected: {_months},
            onSelectionChanged: (value) =>
                setState(() => _months = value.first),
          ),
          child: SizedBox(
            height: 246,
            child: _TrendChart(data: data, hideValues: hide),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final comparison =
                _IncomeExpensePanel(data: data, hideValues: hide);
            final ranking = _ExpenseRanking(
              transactions: visibleMonthTransactions,
              hideValues: hide,
            );
            if (constraints.maxWidth < 920) {
              return Column(
                children: [comparison, const SizedBox(height: 14), ranking],
              );
            }
            return SizedBox(
              height: 294,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: comparison),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: ranking),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final expensesByCategory =
                _byCategory(visibleMonthTransactions, TransactionType.expense);
            final incomesByCategory =
                _byCategory(visibleMonthTransactions, TransactionType.income);
            final expensePanel = _ExpensePieChart(
                title: 'Gastos por categoria',
                subtitle: 'Distribuição em ${_longMonth(_selectedMonth)}',
                data: expensesByCategory,
                hideValues: hide);
            final incomePanel = _CategoryChart(
                title: 'Receitas por categoria',
                subtitle: 'Distribuição em ${_longMonth(_selectedMonth)}',
                data: incomesByCategory,
                color: const Color(0xFF258A5A),
                hideValues: hide);
            if (constraints.maxWidth < 900) {
              return Column(children: [
                expensePanel,
                const SizedBox(height: 14),
                incomePanel
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: expensePanel),
              const SizedBox(width: 14),
              Expanded(child: incomePanel)
            ]);
          },
        ),
        const SizedBox(height: 14),
        _SpendingRoadmap(
            transactions: widget.store.reportTransactions,
            subscriptions: widget.store.subscriptions,
            hideValues: hide,
            year: _selectedMonth.year,
            includePending: _includePending),
      ],
    );
  }

  bool get _canGoNext {
    return _selectedMonth.isBefore(DateTime(2100, 12));
  }

  void _changeMonth(int offset) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    if (next.year < 2000 || next.year > 2100) return;
    setState(() => _selectedMonth = next);
  }

  Future<void> _selectMonth() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initialMonth: _selectedMonth),
    );
    if (selected != null && mounted) {
      setState(() => _selectedMonth = selected);
    }
  }
}

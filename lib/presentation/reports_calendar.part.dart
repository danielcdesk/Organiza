part of 'reports_page.dart';

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Mês anterior',
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
            ),
            MediaQuery.sizeOf(context).width < 600
                ? TextButton(
                    onPressed: onSelect,
                    child: Text(_longMonth(month),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )
                : TextButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(Icons.calendar_month_outlined, size: 17),
                    label: Text(_longMonth(month)),
                  ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              tooltip: 'Próximo mês',
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ],
        ),
      );
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher período'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed:
                      _year > 2000 ? () => setState(() => _year--) : null,
                  tooltip: 'Ano anterior',
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed:
                      _year < 2100 ? () => setState(() => _year++) : null,
                  tooltip: 'Próximo ano',
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = DateTime(_year, index + 1);
                final isSelected = month.year == widget.initialMonth.year &&
                    month.month == widget.initialMonth.month;
                return FilledButton.tonal(
                  onPressed: () => Navigator.pop(context, month),
                  style: FilledButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  child: Text(monthName(month.month).substring(0, 3)),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

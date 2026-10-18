part of 'shopping_page.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onDelete,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final Future<void> Function(String id) onDelete;

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  var _filter = 0;
  late String _viewMode;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.store.shoppingViewPreference;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.store.shoppingItems;
    final pending = items.where((item) => !item.isPurchased).toList()
      ..sort((a, b) {
        final priority = b.priority.index.compareTo(a.priority.index);
        return priority != 0 ? priority : b.createdAt.compareTo(a.createdAt);
      });
    final purchased = items.where((item) => item.isPurchased).toList();
    final visible = switch (_filter) {
      1 => pending,
      2 => purchased,
      _ => [...pending, ...purchased],
    };
    final plannedTotal = pending.fold<int>(
      0,
      (total, item) => total + item.estimatedTotalInCents,
    );

    return ListView(
      padding: pagePadding(context),
      children: [
        PageHeading(
          eyebrow: 'Organização de compras',
          title: 'Lista de desejos',
          description:
              'Planeje o que comprar sem confundir intenção com despesa realizada.',
          actions: [
            FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar item'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ShoppingMetric(
                width: constraints.maxWidth,
                label: 'Itens na lista',
                value: '${pending.length}',
                icon: Icons.list_alt_outlined,
              ),
              _ShoppingMetric(
                width: constraints.maxWidth,
                label: 'Valor estimado',
                value: widget.hideValues
                    ? '••••••'
                    : FinancialRules.formatBrl(plannedTotal),
                icon: Icons.sell_outlined,
              ),
              _ShoppingMetric(
                width: constraints.maxWidth,
                label: 'Comprados',
                value: '${purchased.length}',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Seus itens',
          subtitle: 'Marcar como comprado não registra uma transação.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: 'list',
                      icon: Icon(Icons.view_list_rounded),
                      label: Text('Lista')),
                  ButtonSegment(
                      value: 'cards',
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Cards')),
                ],
                selected: {_viewMode},
                onSelectionChanged: (value) {
                  final next = value.first;
                  setState(() => _viewMode = next);
                  widget.store.saveShoppingViewPreference(next);
                },
              ),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('Todos')),
                  ButtonSegment(value: 1, label: Text('Na lista')),
                  ButtonSegment(value: 2, label: Text('Comprados')),
                ],
                selected: {_filter},
                onSelectionChanged: (value) =>
                    setState(() => _filter = value.first),
              ),
            ],
          ),
          child: visible.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: _filter == 0
                      ? 'Sua lista está vazia'
                      : 'Nenhum item nesta seleção',
                  description: _filter == 0
                      ? 'Adicione um desejo ou uma compra planejada para começar.'
                      : 'Alterne o filtro para ver os outros itens.',
                  actionLabel: _filter == 0 ? 'Adicionar item' : null,
                  onAction: _filter == 0 ? widget.onAdd : null,
                )
              : _viewMode == 'cards'
                  ? _ShoppingGrid(
                      items: visible,
                      hideValues: widget.hideValues,
                      onChanged: (item, value) =>
                          widget.store.setShoppingItemPurchased(item.id, value),
                      onDelete: (item) => widget.onDelete(item.id),
                      onChangeImage: (item) async {
                        final imagePath =
                            await LocalImageService.pickAndStore();
                        if (imagePath != null) {
                          widget.store.setShoppingItemImage(item.id, imagePath);
                        }
                      },
                    )
                  : Column(
                      children: [
                        for (final item in visible)
                          _ShoppingRow(
                            item: item,
                            hideValues: widget.hideValues,
                            onChanged: (value) => widget.store
                                .setShoppingItemPurchased(item.id, value),
                            onDelete: () => widget.onDelete(item.id),
                            onChangeImage: () async {
                              final imagePath =
                                  await LocalImageService.pickAndStore();
                              if (imagePath != null) {
                                widget.store
                                    .setShoppingItemImage(item.id, imagePath);
                              }
                            },
                          ),
                      ],
                    ),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Do planejamento ao fluxo',
          child: Text(
            'O valor estimado é apenas uma referência. Depois da compra, registre a despesa em Finanças usando a conta, categoria e valor efetivamente pagos.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShoppingMetric extends StatelessWidget {
  const _ShoppingMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final itemWidth = width > 900
        ? (width - 28) / 3
        : width > 620
            ? (width - 14) / 2
            : width;
    return SizedBox(
      width: itemWidth,
      height: 112,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 19, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

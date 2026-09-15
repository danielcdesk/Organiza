import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'dialogs.dart' show parseMoney;
import 'shared_widgets.dart';

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
          trailing: SegmentedButton<int>(
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
              : Column(
                  children: [
                    for (final item in visible)
                      _ShoppingRow(
                        item: item,
                        hideValues: widget.hideValues,
                        onChanged: (value) => widget.store
                            .setShoppingItemPurchased(item.id, value),
                        onDelete: () => widget.onDelete(item.id),
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

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.hideValues,
    required this.onChanged,
    required this.onDelete,
  });

  final ShoppingItem item;
  final bool hideValues;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: item.isPurchased,
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: item.isPurchased
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.quantity} un. · ${_priorityName(item.priority)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.estimatedUnitPriceInCents != null)
                Text(
                  hideValues
                      ? '••••••'
                      : FinancialRules.formatBrl(item.estimatedTotalInCents),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Excluir item',
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ],
          ),
          const Divider(height: 12),
        ],
      );
}

String _priorityName(ShoppingPriority priority) => switch (priority) {
      ShoppingPriority.low => 'Pode esperar',
      ShoppingPriority.normal => 'Normal',
      ShoppingPriority.high => 'Prioridade alta',
    };

class ShoppingInput {
  const ShoppingInput({
    required this.name,
    required this.quantity,
    required this.estimatedUnitPriceInCents,
    required this.priority,
  });

  final String name;
  final int quantity;
  final int? estimatedUnitPriceInCents;
  final ShoppingPriority priority;
}

class ShoppingDialog extends StatefulWidget {
  const ShoppingDialog({super.key});

  @override
  State<ShoppingDialog> createState() => _ShoppingDialogState();
}

class _ShoppingDialogState extends State<ShoppingDialog> {
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _price = TextEditingController();
  var _priority = ShoppingPriority.normal;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Adicionar à lista'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Item',
                  hintText: 'Ex.: fones de ouvido',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration:
                          const InputDecoration(labelText: 'Quantidade'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Preço por unidade (R\$)',
                          helperText: 'Opcional'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShoppingPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: ShoppingPriority.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_priorityName(value)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Adicionar')),
        ],
      );

  void _submit() {
    final quantity = int.tryParse(_quantity.text);
    final price = _price.text.trim().isEmpty ? null : parseMoney(_price.text);
    if (_name.text.trim().isEmpty ||
        quantity == null ||
        quantity < 1 ||
        quantity > 9999 ||
        (_price.text.trim().isNotEmpty && (price == null || price < 0))) {
      setState(() => _error = 'Revise item, quantidade e valor estimado.');
      return;
    }
    Navigator.pop(
      context,
      ShoppingInput(
        name: _name.text.trim(),
        quantity: quantity,
        estimatedUnitPriceInCents: price,
        priority: _priority,
      ),
    );
  }
}

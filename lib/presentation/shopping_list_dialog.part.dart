part of 'shopping_page.dart';

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.hideValues,
    required this.onChanged,
    required this.onDelete,
    required this.onChangeImage,
  });

  final ShoppingItem item;
  final bool hideValues;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;
  final Future<void> Function() onChangeImage;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              if (LocalImageService.exists(item.imagePath))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(
                      File(item.imagePath!),
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.photo_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
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
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                onPressed: onChangeImage,
                tooltip: 'Adicionar ou trocar foto',
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
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
    this.imagePath,
    this.description = '',
  });

  final String name;
  final int quantity;
  final int? estimatedUnitPriceInCents;
  final ShoppingPriority priority;
  final String? imagePath;
  final String description;
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
  final _description = TextEditingController();
  var _priority = ShoppingPriority.normal;
  String? _error;
  String? _imagePath;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _description.dispose();
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
                      inputFormatters: [BrlCentsInputFormatter()],
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
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                maxLength: 240,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Detalhes, tamanho, cor ou motivo do desejo',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(_imagePath == null
                    ? Icons.add_photo_alternate_outlined
                    : Icons.check_circle_outline),
                label: Text(_imagePath == null
                    ? 'Adicionar foto (opcional)'
                    : 'Foto adicionada'),
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
        imagePath: _imagePath,
        description: _description.text.trim(),
      ),
    );
  }

  Future<void> _pickImage() async {
    final imagePath = await LocalImageService.pickAndStore();
    if (imagePath != null && mounted) setState(() => _imagePath = imagePath);
  }
}

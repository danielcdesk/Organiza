part of 'shopping_page.dart';

class _ShoppingGrid extends StatelessWidget {
  const _ShoppingGrid({
    required this.items,
    required this.hideValues,
    required this.onChanged,
    required this.onDelete,
    required this.onChangeImage,
  });

  final List<ShoppingItem> items;
  final bool hideValues;
  final void Function(ShoppingItem item, bool value) onChanged;
  final void Function(ShoppingItem item) onDelete;
  final Future<void> Function(ShoppingItem item) onChangeImage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 920
              ? 3
              : constraints.maxWidth > 580
                  ? 2
                  : 1;
          final gap = 12.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _WishlistCard(
                    item: item,
                    hideValues: hideValues,
                    onChanged: (value) => onChanged(item, value),
                    onDelete: () => onDelete(item),
                    onChangeImage: () => onChangeImage(item),
                  ),
                ),
            ],
          );
        },
      );
}

class _WishlistCard extends StatefulWidget {
  const _WishlistCard({
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
  State<_WishlistCard> createState() => _WishlistCardState();
}

class _WishlistCardState extends State<_WishlistCard> {
  var _hovered = false;
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasImage = LocalImageService.exists(item.imagePath);
    final reveal = _hovered || _revealed;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: SizedBox(
                height: 184,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.file(File(item.imagePath!), fit: BoxFit.cover)
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .3),
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(Icons.photo_outlined,
                            size: 42,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    AnimatedOpacity(
                      opacity: reveal ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: .12),
                              Colors.black.withValues(alpha: .86),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              item.description.trim().isEmpty
                                  ? 'Sem descrição. Toque para voltar ao item.'
                                  : item.description,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Material(
                        color: Colors.black.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(10),
                        child: IconButton(
                          onPressed: widget.onChangeImage,
                          tooltip: 'Trocar foto',
                          color: Colors.white,
                          icon:
                              const Icon(Icons.photo_camera_outlined, size: 18),
                        ),
                      ),
                    ),
                    if (item.isPurchased)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D9B67),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Comprado',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration:
                          item.isPurchased ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity} un. · ${_priorityName(item.priority)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (item.estimatedUnitPriceInCents != null)
                        Text(
                          widget.hideValues
                              ? '••••••'
                              : FinancialRules.formatBrl(
                                  item.estimatedTotalInCents),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: item.isPurchased,
                        onChanged: (value) {
                          if (value != null) widget.onChanged(value);
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('Já comprei', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onDelete,
                        tooltip: 'Excluir item',
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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

import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/credit_card_rules.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAddCard,
    required this.onAddPurchase,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAddCard;
  final ValueChanged<String?> onAddPurchase;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  String? _selectedCardId;

  CreditCard? get _selectedCard {
    if (widget.store.creditCards.isEmpty) return null;
    return widget.store.creditCards.firstWhere(
      (card) => card.id == _selectedCardId,
      orElse: () => widget.store.creditCards.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _selectedCard;
    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 42),
      children: [
        PageHeading(
          eyebrow: 'Limites e faturas',
          title: 'Seus cartões',
          description: 'Acompanhe o ciclo atual sem armazenar dados sensíveis.',
          actions: [
            OutlinedButton.icon(
              onPressed: widget.onAddCard,
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: const Text('Novo cartão'),
            ),
            FilledButton.icon(
              onPressed:
                  card == null ? null : () => widget.onAddPurchase(card.id),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Registrar compra'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (card == null)
          Panel(
            title: 'Seus cartões',
            subtitle: 'Comece com os dados essenciais',
            child: EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'Cadastre o primeiro cartão',
              description:
                  'Informe somente nome, bandeira, quatro últimos dígitos, limite e datas. Nunca armazenamos número completo ou CVV.',
              actionLabel: 'Adicionar cartão',
              onAction: widget.onAddCard,
            ),
          )
        else ...[
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.store.creditCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = widget.store.creditCards[index];
                final selected = item.id == card.id;
                return InkWell(
                  onTap: () => setState(() => _selectedCardId = item.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(item.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '${item.name}  •••• ${item.lastFour}',
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final visual =
                  _CreditCardVisual(card: card, hideValues: widget.hideValues);
              final summary = _CardSummary(
                card: card,
                purchases: widget.store.cardPurchases,
                hideValues: widget.hideValues,
              );
              if (constraints.maxWidth < 940) {
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: AspectRatio(aspectRatio: 1.586, child: visual),
                      ),
                    ),
                    const SizedBox(height: 14),
                    summary,
                  ],
                );
              }
              return SizedBox(
                height: 310,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AspectRatio(aspectRatio: 1.586, child: visual),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: SizedBox(height: 310, child: summary),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _PurchasesPanel(
            card: card,
            purchases: widget.store.cardPurchases,
            hideValues: widget.hideValues,
            onAdd: () => widget.onAddPurchase(card.id),
          ),
        ],
      ],
    );
  }
}

class _CreditCardVisual extends StatelessWidget {
  const _CreditCardVisual({required this.card, required this.hideValues});

  final CreditCard card;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final base = Color(card.colorValue);
    final dark = Color.lerp(base, Colors.black, .4)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: .28),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(base, Colors.white, .08)!, dark],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -54,
              top: -70,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: .085), width: 34),
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: -88,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .045),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('ORGANIZA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .92),
                          fontSize: 12,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800,
                        )),
                    const Spacer(),
                    Text('CRÉDITO',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .58),
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        )),
                  ]),
                  const SizedBox(height: 27),
                  const Row(children: [
                    _ChipVisual(),
                    SizedBox(width: 12),
                    Icon(Icons.contactless_rounded,
                        color: Color(0xD9FFFFFF), size: 25),
                  ]),
                  const Spacer(),
                  Text(
                    hideValues
                        ? '••••  ••••  ••••  ••••'
                        : '••••  ••••  ••••  ${card.lastFour}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 19),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARTÃO',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .5),
                                fontSize: 9,
                                letterSpacing: 1.2,
                              )),
                          const SizedBox(height: 4),
                          Text(card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                    _CardBrandMark(brand: card.brand),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipVisual extends StatelessWidget {
  const _ChipVisual();

  @override
  Widget build(BuildContext context) => Container(
        width: 45,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE2C982),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB69E5B)),
        ),
        child: CustomPaint(painter: _ChipPainter()),
      );
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9E8647)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * .48, 0),
        Offset(size.width * .48, size.height), paint);
    canvas.drawLine(Offset(0, size.height * .5),
        Offset(size.width, size.height * .5), paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * .18, size.height * .19, size.width * .62,
                size.height * .62),
            const Radius.circular(4)),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardBrandMark extends StatelessWidget {
  const _CardBrandMark({required this.brand});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    if (brand == CardBrand.mastercard) {
      return SizedBox(
        width: 43,
        height: 26,
        child: Stack(children: [
          Positioned(
              left: 0,
              child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white.withValues(alpha: .88))),
          Positioned(
              right: 0,
              child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white.withValues(alpha: .5))),
        ]),
      );
    }
    return Text(
      brandName(brand),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _CardSummary extends StatelessWidget {
  const _CardSummary(
      {required this.card, required this.purchases, required this.hideValues});

  final CreditCard card;
  final List<CardPurchase> purchases;
  final bool hideValues;

  String _money(int cents) =>
      hideValues ? '••••••' : FinancialRules.formatBrl(cents);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final invoice = CreditCardRules.currentInvoiceTotal(card, purchases, now);
    final available = CreditCardRules.availableLimit(card, purchases, now);
    final ratio = CreditCardRules.usageRatio(card, purchases, now);
    final closing = CreditCardRules.currentCycleClosingDate(card, now);
    return Panel(
      title: 'Ciclo atual',
      subtitle: 'Fecha em ${shortDate(closing)} · vence dia ${card.dueDay}',
      trailing: StatusPill(label: '${(ratio * 100).round()}% usado'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _InlineMetric(
                      label: 'Fatura em aberto', value: _money(invoice))),
              SizedBox(
                height: 42,
                child: VerticalDivider(color: Theme.of(context).dividerColor),
              ),
              Expanded(
                  child: _InlineMetric(
                      label: 'Disponível', value: _money(available))),
              SizedBox(
                height: 42,
                child: VerticalDivider(color: Theme.of(context).dividerColor),
              ),
              Expanded(
                  child: _InlineMetric(
                      label: 'Limite total', value: _money(card.limitInCents))),
            ],
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Uso do limite',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text('${(ratio * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lançamentos manuais · pagamento de fatura em breve',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
      );
}

class _PurchasesPanel extends StatelessWidget {
  const _PurchasesPanel({
    required this.card,
    required this.purchases,
    required this.hideValues,
    required this.onAdd,
  });

  final CreditCard card;
  final List<CardPurchase> purchases;
  final bool hideValues;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final current =
        CreditCardRules.currentCyclePurchases(card, purchases, DateTime.now())
            .toList();
    return Panel(
      title: 'Compras da fatura',
      subtitle:
          '${current.length} lançamento${current.length == 1 ? '' : 's'} no ciclo atual',
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Registrar compra'),
      ),
      child: current.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Nenhuma compra neste ciclo',
              description:
                  'Registre compras manualmente para acompanhar a fatura.',
              actionLabel: 'Nova compra',
              onAction: onAdd,
            )
          : Column(
              children: [
                const _TableHeader(),
                ...current.map((purchase) => _PurchaseRow(
                      card: card,
                      purchase: purchase,
                      hideValues: hideValues,
                    )),
              ],
            ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text('COMPRA', style: _style(context))),
            Expanded(flex: 2, child: Text('DATA', style: _style(context))),
            Expanded(flex: 2, child: Text('PARCELAS', style: _style(context))),
            Expanded(
                flex: 2,
                child: Text('VALOR',
                    textAlign: TextAlign.right, style: _style(context))),
          ],
        ),
      );

  TextStyle _style(BuildContext context) => TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .7,
      );
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow(
      {required this.card, required this.purchase, required this.hideValues});

  final CreditCard card;
  final CardPurchase purchase;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final index = CreditCardRules.installmentIndex(card, purchase,
        CreditCardRules.currentCycleClosingDate(card, DateTime.now()));
    final installment = CreditCardRules.installmentAmount(purchase, index);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const IconTile(icon: Icons.shopping_bag_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    purchase.description,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(shortDate(purchase.purchasedOn))),
          Expanded(
              flex: 2,
              child: Text(purchase.installments == 1
                  ? 'À vista'
                  : '$index/${purchase.installments}')),
          Expanded(
            flex: 2,
            child: Text(
              hideValues ? '••••••' : FinancialRules.formatBrl(installment),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

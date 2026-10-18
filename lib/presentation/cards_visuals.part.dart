part of 'cards_page.dart';

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

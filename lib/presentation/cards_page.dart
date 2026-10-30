import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/credit_card_rules.dart';
import '../domain/card_invoice_rules.dart';
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
    required this.onManageInstallments,
    this.onPayInvoice,
    this.onReverseInvoicePayment,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAddCard;
  final ValueChanged<String?> onAddPurchase;
  final ValueChanged<CardPurchase> onManageInstallments;
  final void Function(CreditCard card, int year, int month)? onPayInvoice;
  final ValueChanged<String>? onReverseInvoicePayment;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  String? _selectedCardId;
  bool _showAllPurchases = false;

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
    final referenceDate = widget.store.clock.now();
    return ListView(
      padding: pagePadding(context),
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
              final visual = _CreditCardVisual(
                card: card,
                hideValues: widget.hideValues,
              );
              final summary = _CardSummary(
                card: card,
                referenceDate: referenceDate,
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
          _InvoicesPanel(
            card: card,
            store: widget.store,
            hideValues: widget.hideValues,
            onPay: widget.onPayInvoice,
            onReverse: widget.onReverseInvoicePayment,
          ),
          const SizedBox(height: 14),
          _PurchasesPanel(
            card: card,
            referenceDate: referenceDate,
            purchases: widget.store.cardPurchases,
            hideValues: widget.hideValues,
            onAdd: () => widget.onAddPurchase(card.id),
            onManageInstallments: widget.onManageInstallments,
            showAll: _showAllPurchases,
            onShowAllChanged: (value) =>
                setState(() => _showAllPurchases = value),
          ),
        ],
      ],
    );
  }
}

class _InvoicesPanel extends StatelessWidget {
  const _InvoicesPanel({
    required this.card,
    required this.store,
    required this.hideValues,
    required this.onPay,
    required this.onReverse,
  });

  final CreditCard card;
  final OrganizaStore store;
  final bool hideValues;
  final void Function(CreditCard card, int year, int month)? onPay;
  final ValueChanged<String>? onReverse;

  @override
  Widget build(BuildContext context) {
    final periods = <DateTime>{};
    for (final purchase
        in store.cardPurchases.where((item) => item.cardId == card.id)) {
      final first =
          CreditCardRules.currentCycleClosingDate(card, purchase.purchasedOn);
      for (var index = 0; index < purchase.installments; index++) {
        periods.add(DateTime(first.year, first.month + index));
      }
    }
    final ordered = periods.toList()..sort((a, b) => b.compareTo(a));
    String money(int cents) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(cents);
    return Panel(
      title: 'Faturas',
      subtitle: 'Parcelas por vencimento; pagamentos reduzem o saldo da conta.',
      child: ordered.isEmpty
          ? const Text('Nenhuma fatura com compras registradas.')
          : Column(children: [
              for (final period in ordered)
                _invoiceTile(context, period, money),
            ]),
    );
  }

  Widget _invoiceTile(
      BuildContext context, DateTime period, String Function(int) money) {
    final cycle = CardInvoiceRules.cycle(card, period.year, period.month);
    final total = CardInvoiceRules.totalInCents(
        card, store.cardPurchases, period.year, period.month);
    final invoice = store.cardInvoices
        .where((item) =>
            item.cardId == card.id &&
            item.referenceYear == period.year &&
            item.referenceMonth == period.month)
        .firstOrNull;
    final payments = invoice == null
        ? <CardInvoicePayment>[]
        : store.cardInvoicePayments
            .where((item) => item.invoiceId == invoice.id)
            .toList();
    final paid = payments.fold<int>(0, (sum, item) => sum + item.amountInCents);
    final remaining = CardInvoiceRules.remainingInCents(total, paid);
    final status = CardInvoiceRules.status(
        total, paid, store.clock.now(), cycle.closingOn);
    final label = switch (status) {
      CardInvoiceStatus.open => 'Aberta',
      CardInvoiceStatus.closed => 'Fechada',
      CardInvoiceStatus.partiallyPaid => 'Parcialmente paga',
      CardInvoiceStatus.paid => 'Paga',
    };
    final periodLabel =
        '${period.month.toString().padLeft(2, '0')}/${period.year}';
    return ExpansionTile(
      key: ValueKey('invoice-${card.id}-$periodLabel'),
      title: Text('Fatura $periodLabel'),
      subtitle: Text('$label · vence ${shortDate(cycle.dueOn)}'),
      trailing: Text(money(remaining)),
      children: [
        ListTile(
          title: Text('Total: ${money(total)}'),
          subtitle: Text(
              'Pago: ${money(paid)} · fecha ${shortDate(cycle.closingOn)}'),
        ),
        if (remaining > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onPay == null
                  ? null
                  : () => onPay!(card, period.year, period.month),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pagar fatura'),
            ),
          ),
        for (final payment in payments)
          ListTile(
            title: Text('Pago em ${shortDate(payment.paidOn)}'),
            subtitle: Text(money(payment.amountInCents)),
            trailing: TextButton(
              onPressed:
                  onReverse == null ? null : () => onReverse!(payment.id),
              child: const Text('Estornar'),
            ),
          ),
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
                    color: Colors.white.withValues(alpha: .085),
                    width: 34,
                  ),
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
                  Row(
                    children: [
                      Text(
                        'ORGANIZA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .92),
                          fontSize: 12,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'CRÉDITO',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .58),
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  const Row(
                    children: [
                      _ChipVisual(),
                      SizedBox(width: 12),
                      Icon(
                        Icons.contactless_rounded,
                        color: Color(0xD9FFFFFF),
                        size: 25,
                      ),
                    ],
                  ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARTÃO',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .5),
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CardBrandMark(brand: card.brand),
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
    canvas.drawLine(
      Offset(size.width * .48, 0),
      Offset(size.width * .48, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * .5),
      Offset(size.width, size.height * .5),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .18,
          size.height * .19,
          size.width * .62,
          size.height * .62,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
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
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white.withValues(alpha: .88),
              ),
            ),
            Positioned(
              right: 0,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white.withValues(alpha: .5),
              ),
            ),
          ],
        ),
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
  const _CardSummary({
    required this.card,
    required this.referenceDate,
    required this.purchases,
    required this.hideValues,
  });

  final CreditCard card;
  final DateTime referenceDate;
  final List<CardPurchase> purchases;
  final bool hideValues;

  String _money(int cents) =>
      hideValues ? '••••••' : FinancialRules.formatBrl(cents);

  @override
  Widget build(BuildContext context) {
    final now = referenceDate;
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
                  label: 'Fatura em aberto',
                  value: _money(invoice),
                ),
              ),
              SizedBox(
                height: 42,
                child: VerticalDivider(color: Theme.of(context).dividerColor),
              ),
              Expanded(
                child: _InlineMetric(
                  label: 'Disponível',
                  value: _money(available),
                ),
              ),
              SizedBox(
                height: 42,
                child: VerticalDivider(color: Theme.of(context).dividerColor),
              ),
              Expanded(
                child: _InlineMetric(
                  label: 'Limite total',
                  value: _money(card.limitInCents),
                ),
              ),
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Uso do limite',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
                  'Pague suas faturas na seção acima.',
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
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
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
    required this.referenceDate,
    required this.purchases,
    required this.hideValues,
    required this.onAdd,
    required this.onManageInstallments,
    required this.showAll,
    required this.onShowAllChanged,
  });

  final CreditCard card;
  final DateTime referenceDate;
  final List<CardPurchase> purchases;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<CardPurchase> onManageInstallments;
  final bool showAll;
  final ValueChanged<bool> onShowAllChanged;

  @override
  Widget build(BuildContext context) {
    final current = CreditCardRules.currentCyclePurchases(
      card,
      purchases,
      referenceDate,
    ).toList();
    final all = purchases
        .where((purchase) => purchase.cardId == card.id)
        .toList()
      ..sort((a, b) => b.purchasedOn.compareTo(a.purchasedOn));
    final visible = showAll ? all : current;
    return Panel(
      title: 'Compras do cartão',
      subtitle:
          '${current.length} na fatura atual · ${all.length} no histórico',
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Registrar compra'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Fatura atual'),
                selected: !showAll,
                onSelected: (_) => onShowAllChanged(false),
              ),
              ChoiceChip(
                label: const Text('Todas as compras'),
                selected: showAll,
                onSelected: (_) => onShowAllChanged(true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: showAll
                  ? 'Nenhuma compra neste cartão'
                  : 'Nenhuma compra nesta fatura',
              description: all.isEmpty
                  ? 'Registre uma compra para acompanhar as parcelas e a fatura.'
                  : 'Suas compras anteriores continuam disponíveis no histórico.',
              actionLabel: all.isEmpty ? 'Registrar compra' : 'Ver histórico',
              onAction: all.isEmpty ? onAdd : () => onShowAllChanged(true),
            )
          else ...[
            _TableHeader(showTotal: showAll),
            ...visible.map(
              (purchase) => _PurchaseRow(
                card: card,
                referenceDate: referenceDate,
                purchase: purchase,
                hideValues: hideValues,
                onManageInstallments: onManageInstallments,
                showTotal: showAll,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.showTotal});

  final bool showTotal;

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
              child: Text(
                showTotal ? 'TOTAL' : 'PARCELA',
                textAlign: TextAlign.right,
                style: _style(context),
              ),
            ),
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

class CardInstallmentPaymentsDialog extends StatefulWidget {
  const CardInstallmentPaymentsDialog({
    super.key,
    required this.purchase,
    required this.hideValues,
  });

  final CardPurchase purchase;
  final bool hideValues;

  @override
  State<CardInstallmentPaymentsDialog> createState() =>
      _CardInstallmentPaymentsDialogState();
}

class _CardInstallmentPaymentsDialogState
    extends State<CardInstallmentPaymentsDialog> {
  late final Set<int> _paid = {...widget.purchase.paidInstallments};

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Parcelas pagas'),
        content: SizedBox(
          width: 380,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.purchase.description),
              const SizedBox(height: 4),
              Text(
                'Marque as parcelas que já foram pagas. Isso atualiza apenas o progresso do cartão.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.purchase.installments,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final amount = CreditCardRules.installmentAmount(
                      widget.purchase,
                      number,
                    );
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _paid.contains(number),
                      title: Text(
                          'Parcela $number/${widget.purchase.installments}'),
                      subtitle: Text(widget.hideValues
                          ? '••••••'
                          : FinancialRules.formatBrl(amount)),
                      onChanged: (paid) => setState(() {
                        if (paid == true) {
                          _paid.add(number);
                        } else {
                          _paid.remove(number);
                        }
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _paid),
            child: const Text('Salvar'),
          ),
        ],
      );
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({
    required this.card,
    required this.referenceDate,
    required this.purchase,
    required this.hideValues,
    required this.onManageInstallments,
    required this.showTotal,
  });

  final CreditCard card;
  final DateTime referenceDate;
  final CardPurchase purchase;
  final bool hideValues;
  final ValueChanged<CardPurchase> onManageInstallments;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final index = CreditCardRules.installmentIndex(
      card,
      purchase,
      CreditCardRules.currentCycleClosingDate(card, referenceDate),
    );
    final installment = showTotal
        ? purchase.amountInCents
        : CreditCardRules.installmentAmount(purchase, index);
    final progress = CreditCardRules.installmentProgress(purchase);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  purchase.installments == 1
                      ? 'À vista'
                      : showTotal
                          ? '${purchase.installments} parcelas'
                          : '$index/${purchase.installments}',
                ),
              ),
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
          ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.ratio,
                minHeight: 7,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '${progress.paid} pagas · ${progress.remaining} restantes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onManageInstallments(purchase),
                  icon: const Icon(Icons.checklist_rounded, size: 17),
                  label: const Text('Gerenciar parcelas'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

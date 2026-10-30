import 'credit_card_rules.dart';
import 'models.dart';

class CardInvoiceCycle {
  const CardInvoiceCycle({required this.closingOn, required this.dueOn});

  final DateTime closingOn;
  final DateTime dueOn;
}

class CardInvoiceRules {
  const CardInvoiceRules._();

  static CardInvoiceCycle cycle(CreditCard card, int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Mês de referência inválido.');
    }
    final closing = _safeDate(year, month, card.closingDay);
    final dueMonth = card.dueDay <= card.closingDay ? month + 1 : month;
    return CardInvoiceCycle(
      closingOn: closing,
      dueOn: _safeDate(year, dueMonth, card.dueDay),
    );
  }

  static int totalInCents(
      CreditCard card, Iterable<CardPurchase> purchases, int year, int month) {
    final closing = cycle(card, year, month).closingOn;
    var total = 0;
    for (final purchase in purchases) {
      if (purchase.cardId != card.id) continue;
      final index = CreditCardRules.installmentIndex(card, purchase, closing);
      total += CreditCardRules.installmentAmount(purchase, index);
    }
    return total;
  }

  static int legacyPaidInCents(
      CreditCard card, Iterable<CardPurchase> purchases, int year, int month) {
    final closing = cycle(card, year, month).closingOn;
    var total = 0;
    for (final purchase in purchases) {
      if (purchase.cardId != card.id) continue;
      final index = CreditCardRules.installmentIndex(card, purchase, closing);
      if (purchase.paidInstallments.contains(index)) {
        total += CreditCardRules.installmentAmount(purchase, index);
      }
    }
    return total;
  }

  static int remainingForPeriod(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    int year,
    int month, {
    int actualPaymentsInCents = 0,
  }) {
    final total = totalInCents(card, purchases, year, month);
    final legacyPaid = legacyPaidInCents(card, purchases, year, month);
    if (actualPaymentsInCents < 0 || legacyPaid > total) {
      throw ArgumentError('Pagamento fora do valor da fatura.');
    }
    // A legacy marker can overlap a real payment. It must never create a
    // negative obligation or cause the view to fail while the user reviews it.
    final remaining = total - legacyPaid - actualPaymentsInCents;
    return remaining < 0 ? 0 : remaining;
  }

  static CardInvoiceStatus statusForPeriod(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    int year,
    int month, {
    required int actualPaymentsInCents,
    required DateTime today,
  }) {
    final total = totalInCents(card, purchases, year, month);
    final legacyPaid = legacyPaidInCents(card, purchases, year, month);
    if (total > 0 && actualPaymentsInCents + legacyPaid >= total) {
      return actualPaymentsInCents > 0
          ? CardInvoiceStatus.paid
          : CardInvoiceStatus.closed;
    }
    return status(
      total,
      actualPaymentsInCents + legacyPaid,
      today,
      cycle(card, year, month).closingOn,
    );
  }

  static int actualPaymentsForPeriodInCents(
    CreditCard card,
    int year,
    int month, {
    required Iterable<CardInvoice> invoices,
    required Iterable<CardInvoicePayment> payments,
    DateTime? through,
  }) {
    final invoiceIds = invoices
        .where((item) =>
            item.cardId == card.id &&
            item.referenceYear == year &&
            item.referenceMonth == month)
        .map((item) => item.id)
        .toSet();
    final date = through == null
        ? null
        : DateTime(through.year, through.month, through.day);
    return payments
        .where((item) =>
            invoiceIds.contains(item.invoiceId) &&
            (date == null ||
                !DateTime(item.paidOn.year, item.paidOn.month, item.paidOn.day)
                    .isAfter(date)))
        .fold(0, (total, item) => total + item.amountInCents);
  }

  static int outstandingBalanceInCents(
    CreditCard card,
    Iterable<CardPurchase> purchases, {
    required Iterable<CardInvoice> invoices,
    required Iterable<CardInvoicePayment> payments,
    required DateTime reference,
  }) {
    final periods = <(int, int)>{};
    final referenceDate =
        DateTime(reference.year, reference.month, reference.day);
    for (final purchase in purchases.where((item) =>
        item.cardId == card.id &&
        !DateTime(item.purchasedOn.year, item.purchasedOn.month,
                item.purchasedOn.day)
            .isAfter(referenceDate))) {
      final first =
          CreditCardRules.currentCycleClosingDate(card, purchase.purchasedOn);
      for (var index = 0; index < purchase.installments; index++) {
        final month = DateTime(first.year, first.month + index);
        periods.add((month.year, month.month));
      }
    }
    var total = 0;
    for (final period in periods) {
      final actual = actualPaymentsForPeriodInCents(
        card,
        period.$1,
        period.$2,
        invoices: invoices,
        payments: payments,
        through: reference,
      );
      total += remainingForPeriod(
        card,
        purchases,
        period.$1,
        period.$2,
        actualPaymentsInCents: actual,
      );
    }
    return total;
  }

  static int remainingInCents(int total, int paid) {
    if (total < 0 || paid < 0 || paid > total) {
      throw ArgumentError('Pagamento fora do valor da fatura.');
    }
    return total - paid;
  }

  static CardInvoiceStatus status(
      int total, int paid, DateTime today, DateTime closingOn) {
    remainingInCents(total, paid);
    if (total > 0 && paid == total) return CardInvoiceStatus.paid;
    if (paid > 0) return CardInvoiceStatus.partiallyPaid;
    final todayDate = DateTime(today.year, today.month, today.day);
    final closingDate =
        DateTime(closingOn.year, closingOn.month, closingOn.day);
    return todayDate.isAfter(closingDate)
        ? CardInvoiceStatus.closed
        : CardInvoiceStatus.open;
  }

  static DateTime _safeDate(int year, int month, int day) {
    final normalized = DateTime(year, month);
    final last = DateTime(normalized.year, normalized.month + 1, 0).day;
    return DateTime(normalized.year, normalized.month, day.clamp(1, last));
  }
}

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

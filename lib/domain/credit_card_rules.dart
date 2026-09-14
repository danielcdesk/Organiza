import 'models.dart';

class CreditCardRules {
  const CreditCardRules._();

  static DateTime currentCycleClosingDate(CreditCard card, DateTime reference) {
    final monthOffset = reference.day <= card.closingDay ? 0 : 1;
    return _safeDate(
        reference.year, reference.month + monthOffset, card.closingDay);
  }

  static Iterable<CardPurchase> currentCyclePurchases(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    DateTime reference,
  ) {
    final closing = currentCycleClosingDate(card, reference);
    return purchases.where((purchase) {
      final index = installmentIndex(card, purchase, closing);
      return purchase.cardId == card.id &&
          index >= 1 &&
          index <= purchase.installments;
    });
  }

  static int currentInvoiceTotal(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    DateTime reference,
  ) =>
      currentCyclePurchases(card, purchases, reference).fold(0,
          (total, purchase) {
        final index = installmentIndex(
            card, purchase, currentCycleClosingDate(card, reference));
        return total + installmentAmount(purchase, index);
      });

  static int installmentIndex(
      CreditCard card, CardPurchase purchase, DateTime cycleClosing) {
    final firstClosing = _firstClosingDate(card, purchase.purchasedOn);
    return _monthDifference(firstClosing, cycleClosing) + 1;
  }

  static int installmentAmount(CardPurchase purchase, int oneBasedIndex) {
    if (oneBasedIndex < 1 || oneBasedIndex > purchase.installments) return 0;
    final base = purchase.amountInCents ~/ purchase.installments;
    final remainder = purchase.amountInCents % purchase.installments;
    return base + (oneBasedIndex <= remainder ? 1 : 0);
  }

  static int outstandingBalance(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    DateTime reference,
  ) {
    final closing = currentCycleClosingDate(card, reference);
    var total = 0;
    for (final purchase in purchases.where((item) => item.cardId == card.id)) {
      final purchaseDate = DateTime(purchase.purchasedOn.year,
          purchase.purchasedOn.month, purchase.purchasedOn.day);
      final referenceDate =
          DateTime(reference.year, reference.month, reference.day);
      if (purchaseDate.isAfter(referenceDate)) continue;
      final currentIndex = installmentIndex(card, purchase, closing);
      final firstOutstanding = currentIndex < 1 ? 1 : currentIndex;
      for (var index = firstOutstanding;
          index <= purchase.installments;
          index++) {
        total += installmentAmount(purchase, index);
      }
    }
    return total;
  }

  static int availableLimit(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    DateTime reference,
  ) =>
      card.limitInCents - outstandingBalance(card, purchases, reference);

  static double usageRatio(
    CreditCard card,
    Iterable<CardPurchase> purchases,
    DateTime reference,
  ) {
    if (card.limitInCents <= 0) return 0;
    return (outstandingBalance(card, purchases, reference) / card.limitInCents)
        .clamp(0, 1);
  }

  static DateTime _firstClosingDate(CreditCard card, DateTime purchaseDate) {
    final monthOffset = purchaseDate.day <= card.closingDay ? 0 : 1;
    return _safeDate(
        purchaseDate.year, purchaseDate.month + monthOffset, card.closingDay);
  }

  static int _monthDifference(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + to.month - from.month;

  static DateTime _safeDate(int year, int month, int day) {
    final normalized = DateTime(year, month);
    final lastDay = DateTime(normalized.year, normalized.month + 1, 0).day;
    return DateTime(normalized.year, normalized.month, day.clamp(1, lastDay));
  }
}

import 'models.dart';

class InvestmentRules {
  const InvestmentRules._();

  static int totalInvested(Iterable<InvestmentPosition> positions) => positions
      .fold(0, (total, position) => total + position.investedAmountInCents);

  static int currentBalance(Iterable<InvestmentPosition> positions) => positions
      .fold(0, (total, position) => total + position.currentValueInCents);

  static int profit(Iterable<InvestmentPosition> positions) =>
      currentBalance(positions) - totalInvested(positions);

  static double returnRate(Iterable<InvestmentPosition> positions) {
    final invested = totalInvested(positions);
    if (invested == 0) return 0;
    return profit(positions) / invested;
  }

  static double positionShare(
    InvestmentPosition position,
    Iterable<InvestmentPosition> positions,
  ) {
    final total = currentBalance(positions);
    if (total == 0) return 0;
    return (position.currentValueInCents / total).clamp(0, 1);
  }
}

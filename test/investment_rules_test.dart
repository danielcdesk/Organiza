import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/investment_rules.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final now = DateTime(2026, 9, 11);
  final positions = [
    InvestmentPosition(
      id: '1',
      name: 'Tesouro Selic',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 100000,
      currentValueInCents: 105000,
      createdAt: now,
    ),
    InvestmentPosition(
      id: '2',
      name: 'IVVB11',
      type: InvestmentType.etf,
      investedAmountInCents: 50000,
      currentValueInCents: 47500,
      createdAt: now,
    ),
  ];

  test('consolida valor aplicado, saldo atual e rentabilidade', () {
    expect(InvestmentRules.totalInvested(positions), 150000);
    expect(InvestmentRules.currentBalance(positions), 152500);
    expect(InvestmentRules.profit(positions), 2500);
    expect(InvestmentRules.returnRate(positions), closeTo(1 / 60, .0001));
  });

  test('calcula participação usando o saldo atual', () {
    expect(InvestmentRules.positionShare(positions.first, positions),
        closeTo(105 / 152.5, .0001));
  });
}

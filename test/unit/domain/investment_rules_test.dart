import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/investment_rules.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dialogs.dart';

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

  test('taxa informada não altera a variação acumulada', () {
    final position = InvestmentPosition(
      id: 'savings',
      name: 'Poupança',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 100000,
      currentValueInCents: 103000,
      quotedRateBasisPoints: 50,
      quotedRatePeriod: InvestmentRatePeriod.monthly,
      createdAt: now,
    );
    expect(InvestmentRules.positionReturnRate(position), closeTo(.03, .00001));
    expect(InvestmentRules.profit([position]), 3000);
    expect(InvestmentRules.returnRate([position]), closeTo(.03, .00001));
  });

  test('interpreta percentual decimal informado com vírgula', () {
    expect(parseInvestmentRateBasisPoints('0,5'), 50);
    expect(parseInvestmentRateBasisPoints('1,25%'), 125);
    expect(parseInvestmentRateBasisPoints('-2,5'), -250);
    expect(parseInvestmentRateBasisPoints('1001'), isNull);
    expect(parseInvestmentRateBasisPoints('abc'), isNull);
  });
}

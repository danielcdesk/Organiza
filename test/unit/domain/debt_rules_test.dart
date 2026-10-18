import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/debt_rules.dart';

void main() {
  test('parcela separa principal de juros sem exceder saldo devedor', () {
    final part = DebtRules.splitInstallment(
      outstandingPrincipalInCents: 100000,
      installmentAmountInCents: 10000,
      monthlyInterestBasisPoints: 100,
    );
    expect(part.principalInCents, 9000);
    expect(part.interestInCents, 1000);
    expect(part.paymentInCents, 10000);
    final last = DebtRules.splitInstallment(
      outstandingPrincipalInCents: 1500,
      installmentAmountInCents: 10000,
      monthlyInterestBasisPoints: 100,
    );
    expect(last.principalInCents, 1500);
    expect(last.interestInCents, 15);
    expect(last.paymentInCents, 1515);
  });

  test('vencimento no dia 31 ajusta fevereiro bissexto', () {
    expect(DebtRules.nextDueDate(DateTime.utc(2028, 1, 31), 1),
        DateTime.utc(2028, 2, 29));
  });

  test('parcela insuficiente para juros é recusada', () {
    expect(
        () => DebtRules.splitInstallment(
              outstandingPrincipalInCents: 100000,
              installmentAmountInCents: 100,
              monthlyInterestBasisPoints: 100,
            ),
        throwsArgumentError);
  });
}

import 'business_date.dart';

class DebtInstallmentBreakdown {
  const DebtInstallmentBreakdown(this.principalInCents, this.interestInCents);
  final int principalInCents;
  final int interestInCents;
  int get paymentInCents => principalInCents + interestInCents;
}

abstract final class DebtRules {
  static DebtInstallmentBreakdown splitInstallment({
    required int outstandingPrincipalInCents,
    required int installmentAmountInCents,
    required int monthlyInterestBasisPoints,
  }) {
    if (outstandingPrincipalInCents <= 0 ||
        installmentAmountInCents <= 0 ||
        monthlyInterestBasisPoints < 0 ||
        monthlyInterestBasisPoints > 10000) {
      throw ArgumentError('Dados da dívida inválidos.');
    }
    final interest =
        (outstandingPrincipalInCents * monthlyInterestBasisPoints + 5000) ~/
            10000;
    if (installmentAmountInCents <= interest) {
      throw ArgumentError('A parcela não cobre os juros do mês.');
    }
    final principal = (installmentAmountInCents - interest)
        .clamp(0, outstandingPrincipalInCents);
    return DebtInstallmentBreakdown(principal, interest);
  }

  static DateTime nextDueDate(DateTime firstDueOn, int monthOffset) =>
      BusinessDate.addMonths(firstDueOn, monthOffset);
}

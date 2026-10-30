import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/services/report_export_service.dart';

void main() {
  test('CSV separa compra categorizada do pagamento da fatura', () {
    final date = DateTime(2026, 1, 5);
    final rows = const ReportExportService().buildCsvRows([
      TransactionRecord(
        id: 'payment',
        accountId: 'account',
        type: TransactionType.expense,
        amountInCents: 10000,
        description: 'Pagamento',
        category: 'Livros',
        occurredOn: DateTime(2026, 1, 17),
        createdAt: date,
        systemType: TransactionSystemType.cardPayment,
      ),
    ], purchases: [
      CardPurchase(
        id: 'purchase',
        cardId: 'card',
        description: 'Coleção',
        amountInCents: 30000,
        purchasedOn: date,
        installments: 3,
        createdAt: date,
        category: 'Livros',
      )
    ]);
    expect(rows.where((row) => row.contains('card_purchase')), hasLength(1));
    expect(rows.where((row) => row.contains('card_payment')), hasLength(1));
    expect(rows.singleWhere((row) => row.contains('card_payment')),
        isNot(contains('"Livros"')));
    expect(rows.singleWhere((row) => row.contains('card_purchase')),
        contains('"Livros"'));
  });
}

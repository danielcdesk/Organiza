import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('schema 17 chega ao 19 com compras vinculadas e saldo intacto',
      () async {
    final folder = await Directory.systemTemp.createTemp('organiza-card-v18-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File(path.join(folder.path, 'organiza.db'));
    final source = AppDatabase.openInMemoryAtVersionForTest(17);
    source.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 100000,
      createdAt: DateTime(2026, 1, 1),
    ));
    source.insertCreditCard(CreditCard(
      id: 'card',
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 200000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff000000,
      createdAt: DateTime(2026, 1, 1),
    ));
    source.insertCardPurchase(CardPurchase(
      id: 'purchase',
      cardId: 'card',
      description: 'Livro',
      amountInCents: 12345,
      purchasedOn: DateTime(2026, 1, 5),
      installments: 3,
      createdAt: DateTime(2026, 1, 5),
    ));
    source.setCardPurchaseInstallmentsPaid(
        'purchase', {1}, DateTime(2026, 2, 17));
    final before = FinancialRules.currentBalance(
        source.loadAccounts(), source.loadTransactions());
    await source.createConsistentCopy(file);
    source.close();

    final migrated = AppDatabase.openFile(file);
    expect(migrated.schemaVersion, 20);
    expect(migrated.loadCardPurchases().single.paidInstallments, {1});
    expect(
        FinancialRules.currentBalance(
            migrated.loadAccounts(), migrated.loadTransactions()),
        before);
    expect(migrated.tableCounts['card_invoices'], 0);
    expect(migrated.tableCounts['card_invoice_payments'], 0);
    migrated.validateIntegrity();
    migrated.close();

    final raw = sqlite3.open(file.path);
    final purchase = raw.select(
        'SELECT category_id, subcategory_id '
        'FROM card_purchases WHERE id = ?',
        ['purchase']).single;
    expect(purchase['category_id'], isNotNull);
    expect(purchase['subcategory_id'], isNotNull);
    expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
    raw.close();
    expect(File('${file.path}.pre-v20.bak').existsSync(), isTrue);
    final reopened = AppDatabase.openFile(file);
    expect(reopened.tableCounts['card_purchases'], 1);
    reopened.validateIntegrity();
    reopened.close();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('compra nova guarda categoria de despesa por ID', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    database.insertCreditCard(CreditCard(
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
    database.insertCardPurchase(CardPurchase(
      id: 'purchase',
      cardId: 'card',
      description: 'Livro',
      amountInCents: 12000,
      purchasedOn: DateTime(2026, 1, 5),
      installments: 1,
      createdAt: DateTime(2026, 1, 5),
      category: 'Educação',
      subcategory: 'Livros',
    ));
    final loaded = database.loadCardPurchases().single;
    expect(loaded.category, 'Educação');
    expect(loaded.subcategory, 'Livros');
    expect(loaded.categoryId, isNotNull);
    expect(loaded.subcategoryId, isNotNull);
    database.renameFinanceCategory(loaded.categoryId!, 'Estudos');
    expect(database.loadCardPurchases().single.category, 'Estudos');
    database.validateIntegrity();
  });
}

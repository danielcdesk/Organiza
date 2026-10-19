import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/finance_icons.dart';

void main() {
  test('categoria e subcategoria compartilham mapeamento estável', () {
    expect(financeCategoryIcon('Alimentação'), Icons.restaurant_outlined);
    expect(financeCategoryIcon('Alimentação', 'Mercado'),
        Icons.shopping_basket_outlined);
    expect(financeCategoryIcon('Transporte', 'Combustível'),
        Icons.local_gas_station_outlined);
    expect(financeCategoryIcon('Personalizada'), Icons.category_outlined);
  });
}

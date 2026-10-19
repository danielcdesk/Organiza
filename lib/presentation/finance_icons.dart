import 'package:flutter/material.dart';

IconData financeCategoryIcon(String category, [String? subcategory]) {
  final sub = subcategory?.toLowerCase().trim();
  if (sub != null) {
    final specific = switch (sub) {
      'mercado' || 'supermercado' || 'feira' => Icons.shopping_basket_outlined,
      'restaurantes' || 'restaurante' => Icons.restaurant_outlined,
      'delivery' => Icons.delivery_dining_outlined,
      'padaria' => Icons.bakery_dining_outlined,
      'açougue' => Icons.set_meal_outlined,
      'combustível' => Icons.local_gas_station_outlined,
      'transporte público' => Icons.directions_bus_outlined,
      'farmácia' => Icons.medication_outlined,
      'livros' => Icons.menu_book_outlined,
      'internet' => Icons.wifi_outlined,
      'energia' => Icons.bolt_outlined,
      'aluguel' => Icons.home_outlined,
      'salário' => Icons.work_outline_rounded,
      _ => null,
    };
    if (specific != null) return specific;
  }
  return switch (category.toLowerCase().trim()) {
    'alimentação' => Icons.restaurant_outlined,
    'contas e serviços' ||
    'serviços' ||
    'contas' =>
      Icons.receipt_long_outlined,
    'doação' || 'doações' => Icons.volunteer_activism_outlined,
    'lazer' => Icons.local_activity_outlined,
    'transporte' => Icons.directions_car_outlined,
    'saúde' => Icons.favorite_border_rounded,
    'educação' => Icons.school_outlined,
    'moradia' => Icons.home_outlined,
    'compras' || 'vestuário' => Icons.shopping_bag_outlined,
    'investimentos' => Icons.trending_up_rounded,
    'salário' || 'trabalho' => Icons.work_outline_rounded,
    'pets' => Icons.pets_outlined,
    _ => Icons.category_outlined,
  };
}

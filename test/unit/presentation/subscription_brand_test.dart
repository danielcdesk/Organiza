import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/subscription_brand.dart';

void main() {
  test('reconhece marcas por nome e escolha explícita', () {
    expect(subscriptionBrandFor('Spotify Premium', null)?.key, 'spotify');
    expect(subscriptionBrandFor('Netflix', null)?.key, 'netflix');
    expect(subscriptionBrandFor('HBO Max', null)?.key, 'hbomax');
    expect(subscriptionBrandFor('Outro serviço', 'spotify')?.key, 'spotify');
    expect(subscriptionBrandFor('Netflix', 'generic'), isNull);
    expect(subscriptionBrandFor('Serviço desconhecido', null), isNull);
  });
}

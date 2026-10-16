import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/admin/core/admin_delivery_zone_presentation.dart';

void main() {
  final zones = [
    {
      'name': 'Carapicuíba Centro',
      'city': 'Carapicuíba',
      'neighborhood': 'Centro',
      'is_active': true,
    },
    {
      'name': 'Osasco Norte',
      'city': 'Osasco',
      'neighborhood': 'Quitaúna',
      'is_active': false,
    },
  ];

  test('formata taxa e pedido mínimo em moeda brasileira', () {
    expect(formatDeliveryMoney('5.00'), 'R\$ 5,00');
    expect(formatDeliveryMoney('8.50'), 'R\$ 8,50');
  });

  test('busca por nome, cidade ou bairro e filtra status', () {
    expect(
      filterDeliveryZones(
        zones: zones,
        query: 'quitaúna',
        activeFilter: null,
      ),
      hasLength(1),
    );
    expect(
      filterDeliveryZones(
        zones: zones,
        query: '',
        activeFilter: true,
      ),
      hasLength(1),
    );
  });
}

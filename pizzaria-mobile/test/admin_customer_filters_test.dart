import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/admin/core/admin_customer_filters.dart';

void main() {
  final customers = [
    {'name': 'Ana Silva', 'email': 'ANA@example.com', 'is_active': true},
    {'name': 'Bruno Costa', 'email': 'bruno@example.com', 'is_active': false},
  ];

  test('busca cliente por nome ou e-mail sem diferenciar maiúsculas', () {
    expect(
      AdminCustomerFilters.visible(
        customers: customers,
        query: 'ana',
        activeFilter: null,
      ),
      hasLength(1),
    );
    expect(
      AdminCustomerFilters.visible(
        customers: customers,
        query: 'BRUNO@EXAMPLE',
        activeFilter: null,
      ),
      hasLength(1),
    );
  });

  test('filtra clientes ativos e inativos', () {
    expect(
      AdminCustomerFilters.visible(
        customers: customers,
        query: '',
        activeFilter: true,
      ),
      hasLength(1),
    );
    expect(
      AdminCustomerFilters.visible(
        customers: customers,
        query: '',
        activeFilter: false,
      ),
      hasLength(1),
    );
  });
}

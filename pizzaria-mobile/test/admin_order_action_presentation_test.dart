import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/admin/core/admin_order_action_presentation.dart';

void main() {
  test('apresenta ações operacionais para cada status ativo', () {
    expect(
      AdminOrderActions.forOrder(
        status: 'PENDING',
        fulfillmentType: 'DELIVERY',
      )?.label,
      'Aceitar pedido',
    );
    expect(
      AdminOrderActions.forOrder(
        status: 'CONFIRMED',
        fulfillmentType: 'DELIVERY',
      )?.label,
      'Iniciar preparo',
    );
    expect(
      AdminOrderActions.forOrder(
        status: 'PREPARING',
        fulfillmentType: 'DELIVERY',
      )?.label,
      'Marcar como pronto',
    );
    expect(
      AdminOrderActions.forOrder(
        status: 'READY',
        fulfillmentType: 'DELIVERY',
      )?.label,
      'Enviar para entrega',
    );
    expect(
      AdminOrderActions.forOrder(
        status: 'OUT_FOR_DELIVERY',
        fulfillmentType: 'DELIVERY',
      )?.label,
      'Concluir entrega',
    );
  });

  test('diferencia retirada e estados sem avanço', () {
    expect(
      AdminOrderActions.forOrder(
        status: 'READY',
        fulfillmentType: 'PICKUP',
      )?.label,
      'Concluir retirada',
    );
    expect(
      AdminOrderActions.forOrder(
        status: 'DELIVERED',
        fulfillmentType: 'DELIVERY',
      ),
      isNull,
    );
    expect(
      AdminOrderActions.forOrder(
        status: 'CANCELLED',
        fulfillmentType: 'PICKUP',
      ),
      isNull,
    );
  });
}

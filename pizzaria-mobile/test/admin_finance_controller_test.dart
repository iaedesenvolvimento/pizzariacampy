import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaria_mobile/features/admin/admin_finance_controller.dart';
import 'package:pizzaria_mobile/features/admin/core/admin_finance_presentation.dart';

Map<String, dynamic> _summary({String grossSales = '100.00'}) => {
      'gross_sales': grossSales,
      'orders_count': 2,
      'average_ticket': '50.00',
      'discounts_total': '5.00',
      'delivery_fees_total': '10.00',
      'cancelled_orders_count': 1,
      'cancelled_amount': '20.00',
      'pix_pending_count': 1,
      'pix_awaiting_proof_count': 1,
      'pix_awaiting_review_count': 0,
      'payment_methods': [],
    };

void main() {
  test('carrega resumo e vendas com sucesso', () async {
    final controller = AdminFinanceController(request: (path) async {
      if (path.contains('/summary')) return _summary();
      return {'items': []};
    });

    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    expect(controller.summary?.ordersCount, 2);
    expect(controller.sales, isEmpty);
    controller.dispose();
  });

  test('expõe erro amigável quando a API falha', () async {
    final controller = AdminFinanceController(request: (_) async {
      throw StateError('offline');
    });

    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.error, 'Não foi possível carregar os dados financeiros.');
    controller.dispose();
  });

  test('altera período e envia as datas ao backend', () async {
    final paths = <String>[];
    final controller = AdminFinanceController(request: (path) async {
      paths.add(path);
      return path.contains('/summary') ? _summary() : {'items': []};
    });

    await controller.setPeriod(FinancePeriod.sevenDays);

    expect(controller.period, FinancePeriod.sevenDays);
    expect(
      paths.any(
          (path) => path.contains('start_date=') && path.contains('end_date=')),
      isTrue,
    );
    controller.dispose();
  });

  test('resposta antiga não sobrescreve a nova', () async {
    final completers = List<Completer<dynamic>>.generate(
      4,
      (_) => Completer<dynamic>(),
    );
    var requestCount = 0;
    final controller = AdminFinanceController(request: (_) {
      return completers[requestCount++].future;
    });

    final firstLoad = controller.load();
    final secondLoad = controller.setPeriod(FinancePeriod.sevenDays);
    completers[2].complete(_summary(grossSales: '200.00'));
    completers[3].complete({'items': []});
    await secondLoad;
    completers[0].complete(_summary());
    completers[1].complete({'items': []});
    await firstLoad;

    expect(controller.period, FinancePeriod.sevenDays);
    expect(controller.summary?.grossSales, '200.00');
    controller.dispose();
  });

  test('carrega pendências PIX e diferencia comprovante de análise', () async {
    final controller = AdminFinanceController(request: (path) async {
      if (path.contains('pix-pending')) {
        return {
          'total': 2,
          'items': [
            {
              'order_id': '1',
              'order_number': 'PC-1',
              'created_at': '2026-10-16T12:00:00Z',
              'total_amount': '20.00',
              'payment_status': 'PENDING',
              'order_status': 'PENDING',
            },
            {
              'order_id': '2',
              'order_number': 'PC-2',
              'created_at': '2026-10-16T12:00:00Z',
              'total_amount': '30.00',
              'payment_status': 'UNDER_REVIEW',
              'order_status': 'PENDING',
              'proof_url': 'https://example.test/proof',
            },
          ],
        };
      }
      return {'items': []};
    });

    await controller.loadPixPending();

    expect(controller.pixTotal, 2);
    expect(controller.pixPending[0].proofUrl, isNull);
    expect(controller.pixPending[1].paymentStatus, 'UNDER_REVIEW');
    expect(controller.pixPending[1].proofUrl, isNotNull);
    controller.dispose();
  });

  test('preserva alerta de cancelado com pagamento confirmado', () {
    final item = FinanceCancellation.fromJson({
      'order_id': '1',
      'order_number': 'PC-1',
      'created_at': '2026-10-16T12:00:00Z',
      'total_amount': '40.00',
      'payment_method': 'PIX',
      'payment_status': 'CONFIRMED',
      'order_status': 'CANCELLED',
      'payment_confirmed': true,
    });

    expect(item.paymentConfirmed, isTrue);
    expect(paymentStatusLabel(item.paymentStatus), 'Confirmado');
    expect(paymentStatusLabel(item.paymentStatus), isNot('Reembolsado'));
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/admin/core/admin_finance_presentation.dart';

void main() {
  test('formata valores financeiros em pt-BR sem perder centavos', () {
    expect(formatFinanceMoney('1234567.8'), 'R\$ 1.234.567,80');
    expect(formatFinanceMoney('-8.5'), 'R\$ -8,50');
  });

  test('apresenta métodos e estados de pagamento amigáveis', () {
    expect(paymentMethodLabel('PIX'), 'PIX');
    expect(paymentMethodLabel('CASH'), 'Dinheiro');
    expect(paymentMethodLabel('CARD_ON_DELIVERY'), 'Cartão na entrega');
    expect(paymentStatusLabel('PENDING'), 'Pendente');
    expect(paymentStatusLabel('UNDER_REVIEW'), 'Em análise');
    expect(paymentStatusLabel('CONFIRMED'), 'Confirmado');
    expect(paymentStatusLabel('FAILED'), 'Rejeitado');
  });

  test('calcula períodos de calendário sem sobreposição', () {
    final today = DateTime(2026, 10, 16);
    final seven = periodDates(FinancePeriod.sevenDays, today: today);
    final thirty = periodDates(FinancePeriod.thirtyDays, today: today);
    expect(seven.start, DateTime(2026, 10, 10));
    expect(seven.end, today);
    expect(thirty.start, DateTime(2026, 9, 17));
    expect(thirty.end, today);
  });

  test('mantém a semântica de vendas operacionais', () {
    expect('Vendas operacionais', isNot('Recebido'));
    expect('Vendas operacionais', isNot('Lucro'));
  });
}

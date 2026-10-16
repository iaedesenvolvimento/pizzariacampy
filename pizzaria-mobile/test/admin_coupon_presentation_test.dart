import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/admin/core/admin_coupon_presentation.dart';

void main() {
  test('apresenta percentual e valor fixo corretamente', () {
    expect(couponTypeLabel('PERCENTAGE'), 'Percentual');
    expect(formatCouponValue('PERCENTAGE', '10.00'), '10,00%');
    expect(couponTypeLabel('FIXED'), 'Valor fixo');
    expect(formatCouponValue('FIXED', '10.50'), 'R\$ 10,50');
  });

  test('apresenta utilização com e sem limite', () {
    expect(
      couponUsageLabel({'usage_count': 3}),
      '3 utilizações',
    );
    expect(
      couponUsageLabel({'usage_count': 3, 'usage_limit': 20}),
      '3 / 20 utilizações',
    );
  });
}

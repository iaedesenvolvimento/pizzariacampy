String couponTypeLabel(String? type) =>
    type == 'FIXED' ? 'Valor fixo' : 'Percentual';

String formatCouponValue(String? type, dynamic value) {
  final text = value?.toString().replaceAll('.', ',') ?? '0,00';
  return type == 'PERCENTAGE' ? '$text%' : 'R\$ $text';
}

String couponUsageLabel(Map<String, dynamic> coupon) {
  final usage = coupon['usage_count'] ?? 0;
  final limit = coupon['usage_limit'];
  return limit == null ? '$usage utilizações' : '$usage / $limit utilizações';
}

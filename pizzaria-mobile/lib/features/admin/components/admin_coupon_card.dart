import 'package:flutter/material.dart';

import '../core/admin_coupon_presentation.dart';
import '../core/admin_spacing.dart';

class AdminCouponCard extends StatelessWidget {
  const AdminCouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onToggle,
    super.key,
  });

  final Map<String, dynamic> coupon;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isActive = coupon['is_active'] == true;
    final type = coupon['discount_type']?.toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon['code']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar cupom',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            if ((coupon['description']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                child: Text(coupon['description'].toString()),
              ),
            Wrap(
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.sm,
              children: [
                Text(
                  '${couponTypeLabel(type)}: ${formatCouponValue(type, coupon['value'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                    'Pedido mínimo: R\$ ${_money(coupon['minimum_order_amount'])}'),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.sm,
              children: [
                Text(couponUsageLabel(coupon)),
                if (coupon['per_customer_limit'] != null)
                  Text('Limite por cliente: ${coupon['per_customer_limit']}'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                    ),
                    const SizedBox(width: AdminSpacing.xs),
                    Text(isActive ? 'Ativo' : 'Pausado'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _money(dynamic value) =>
      value?.toString().replaceAll('.', ',') ?? '0,00';
}

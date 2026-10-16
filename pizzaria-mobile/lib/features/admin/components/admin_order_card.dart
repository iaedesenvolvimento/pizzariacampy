import 'package:flutter/material.dart';

import '../admin_dashboard_controller.dart';
import '../core/admin_order_action_presentation.dart';
import '../core/admin_spacing.dart';
import '../core/admin_status.dart';
import 'admin_action_menu.dart';

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({
    required this.order,
    this.onAction,
    this.onCancel,
    this.onReviewPayment,
    this.onDetails,
    super.key,
  });

  final AdminOrderSummary order;
  final VoidCallback? onAction;
  final VoidCallback? onCancel;
  final VoidCallback? onReviewPayment;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final action = AdminOrderActions.forOrder(
      status: order.status,
      fulfillmentType: order.fulfillmentType,
    );
    final canCancel =
        {'PENDING', 'CONFIRMED', 'PREPARING'}.contains(order.status);
    final paymentUnderReview = order.paymentStatus == 'UNDER_REVIEW';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.number,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canCancel && onCancel != null)
                  AdminActionMenu(
                    items: const [
                      AdminActionMenuItem(
                        value: 'cancel',
                        label: 'Cancelar pedido',
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                    onSelected: (_) => onCancel!(),
                  ),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdminStatusBadge(status: order.status),
                Chip(
                  avatar: Icon(
                    order.fulfillmentType == 'DELIVERY'
                        ? Icons.delivery_dining_outlined
                        : Icons.storefront_outlined,
                    size: 18,
                  ),
                  label: Text(order.fulfillmentType == 'DELIVERY'
                      ? 'Entrega'
                      : 'Retirada'),
                ),
                Text(
                  'R\$ ${order.total.replaceAll('.', ',')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.xs,
              children: [
                if (order.createdAt != null) Text(_elapsed(order.createdAt!)),
                if (order.paymentStatus != null)
                  Text(_paymentLabel(order.paymentStatus!)),
              ],
            ),
            if (paymentUnderReview && onReviewPayment != null) ...[
              const SizedBox(height: AdminSpacing.sm),
              OutlinedButton.icon(
                onPressed: onReviewPayment,
                icon: const Icon(Icons.pix_outlined),
                label: const Text('Revisar PIX'),
              ),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: AdminSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(action.icon),
                  label: Text(action.label),
                ),
              ),
            ],
            if (onDetails != null) ...[
              const SizedBox(height: AdminSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver detalhes disponíveis'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String value) => switch (value) {
        'UNDER_REVIEW' => 'PIX aguardando revisão',
        'CONFIRMED' => 'Pagamento confirmado',
        'FAILED' => 'Pagamento recusado',
        _ => value,
      };

  String _elapsed(DateTime createdAt) {
    final elapsed = DateTime.now().difference(createdAt.toLocal());
    if (elapsed.inMinutes < 1) return 'Agora';
    if (elapsed.inMinutes < 60) return 'Há ${elapsed.inMinutes} min';
    if (elapsed.inHours < 24) return 'Há ${elapsed.inHours} h';
    return 'Há ${elapsed.inDays} d';
  }
}

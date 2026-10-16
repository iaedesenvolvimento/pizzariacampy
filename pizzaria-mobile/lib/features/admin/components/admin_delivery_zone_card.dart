import 'package:flutter/material.dart';

import '../core/admin_delivery_zone_presentation.dart';
import '../core/admin_spacing.dart';

class AdminDeliveryZoneCard extends StatelessWidget {
  const AdminDeliveryZoneCard({
    required this.zone,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final Map<String, dynamic> zone;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = zone['is_active'] == true;
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
                    zone['name']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Ações da zona',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onToggle();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Editar zona')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(isActive ? 'Pausar zona' : 'Ativar zona'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir zona'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              '${zone['neighborhood'] ?? ''} · ${zone['city'] ?? ''}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AdminSpacing.md),
            Wrap(
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.sm,
              children: [
                Text('Taxa: ${formatDeliveryMoney(zone['delivery_fee'])}'),
                Text(
                    'Pedido mínimo: ${formatDeliveryMoney(zone['minimum_order_amount'])}'),
                Text('Estimativa: ${zone['estimated_minutes'] ?? 45} min'),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            Row(
              children: [
                Icon(
                  isActive
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  size: 18,
                ),
                const SizedBox(width: AdminSpacing.xs),
                Text(isActive ? 'Ativa' : 'Pausada'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

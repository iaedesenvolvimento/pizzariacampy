import 'package:flutter/material.dart';

import 'admin_colors.dart';
import 'admin_spacing.dart';

class AdminStatusVisual {
  const AdminStatusVisual({
    required this.label,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData icon;
}

abstract final class AdminStatuses {
  static AdminStatusVisual forValue(String value) {
    return switch (value.toUpperCase()) {
      'PENDING' => const AdminStatusVisual(
          label: 'Pedido recebido',
          foreground: AdminColors.warning,
          background: AdminColors.warningSurface,
          icon: Icons.notifications_active_outlined),
      'CONFIRMED' => const AdminStatusVisual(
          label: 'Confirmado',
          foreground: AdminColors.info,
          background: AdminColors.infoSurface,
          icon: Icons.thumb_up_alt_outlined),
      'PREPARING' => const AdminStatusVisual(
          label: 'Preparando',
          foreground: AdminColors.warning,
          background: AdminColors.warningSurface,
          icon: Icons.local_fire_department_outlined),
      'READY' => const AdminStatusVisual(
          label: 'Pronto',
          foreground: AdminColors.success,
          background: AdminColors.successSurface,
          icon: Icons.check_circle_outline),
      'OUT_FOR_DELIVERY' => const AdminStatusVisual(
          label: 'Saiu para entrega',
          foreground: AdminColors.info,
          background: AdminColors.infoSurface,
          icon: Icons.delivery_dining_outlined),
      'DELIVERED' => const AdminStatusVisual(
          label: 'Entregue',
          foreground: AdminColors.success,
          background: AdminColors.successSurface,
          icon: Icons.done_all_outlined),
      'CANCELLED' => const AdminStatusVisual(
          label: 'Cancelado',
          foreground: AdminColors.danger,
          background: AdminColors.dangerSurface,
          icon: Icons.cancel_outlined),
      _ => const AdminStatusVisual(
          label: 'Status não informado',
          foreground: AdminColors.neutral,
          background: AdminColors.neutralSurface,
          icon: Icons.help_outline),
    };
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final visual = AdminStatuses.forValue(status);
    return Semantics(
      label: 'Status: ${visual.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.md, vertical: AdminSpacing.sm),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, size: 18, color: visual.foreground),
            const SizedBox(width: AdminSpacing.sm),
            Text(
              visual.label,
              style: TextStyle(
                color: visual.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

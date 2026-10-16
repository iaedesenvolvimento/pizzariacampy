import 'package:flutter/material.dart';

class AdminOrderActionPresentation {
  const AdminOrderActionPresentation({
    required this.targetStatus,
    required this.label,
    required this.icon,
  });

  final String targetStatus;
  final String label;
  final IconData icon;
}

abstract final class AdminOrderActions {
  static AdminOrderActionPresentation? forOrder({
    required String status,
    required String fulfillmentType,
  }) {
    return switch (status) {
      'PENDING' => const AdminOrderActionPresentation(
          targetStatus: 'CONFIRMED',
          label: 'Aceitar pedido',
          icon: Icons.thumb_up_alt_outlined),
      'CONFIRMED' => const AdminOrderActionPresentation(
          targetStatus: 'PREPARING',
          label: 'Iniciar preparo',
          icon: Icons.local_fire_department_outlined),
      'PREPARING' => const AdminOrderActionPresentation(
          targetStatus: 'READY',
          label: 'Marcar como pronto',
          icon: Icons.check_circle_outline),
      'READY' when fulfillmentType == 'DELIVERY' =>
        const AdminOrderActionPresentation(
            targetStatus: 'OUT_FOR_DELIVERY',
            label: 'Enviar para entrega',
            icon: Icons.delivery_dining_outlined),
      'READY' => const AdminOrderActionPresentation(
          targetStatus: 'DELIVERED',
          label: 'Concluir retirada',
          icon: Icons.done_all_outlined),
      'OUT_FOR_DELIVERY' => const AdminOrderActionPresentation(
          targetStatus: 'DELIVERED',
          label: 'Concluir entrega',
          icon: Icons.done_all_outlined),
      _ => null,
    };
  }
}

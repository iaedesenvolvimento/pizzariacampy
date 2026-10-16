import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/notifications/realtime_notification_service.dart';
import '../../core/storage/app_storage.dart';
import 'admin_dashboard_controller.dart';
import 'admin_design_system.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminDashboardController? _controller;
  StreamSubscription<RealtimeNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription =
        realtimeNotificationService.events.listen((event) {
      if (event.type == 'order.created' && mounted) {
        _controller?.load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    final controller = AdminDashboardController(
      ApiClient(config: AppConfig.fromEnvironment()),
      storage,
    );
    if (!mounted) return;
    setState(() => _controller = controller);
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const AdminScaffold(
        title: 'Painel administrativo',
        activeDestination: AdminDestinationId.dashboard,
        body: AdminLoadingState(label: 'Carregando painel administrativo'),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final content = switch (controller.status) {
          AdminDashboardStatus.idle ||
          AdminDashboardStatus.loading =>
            const AdminLoadingState(label: 'Carregando painel administrativo'),
          AdminDashboardStatus.error => AdminErrorState(
              message: controller.errorMessage ??
                  'Não foi possível carregar o painel.',
              onRetry: controller.load,
            ),
          AdminDashboardStatus.loaded when controller.data != null =>
            _DashboardContent(data: controller.data!, controller: controller),
          _ => AdminErrorState(
              message: 'Não foi possível carregar o painel.',
              onRetry: controller.load,
            ),
        };

        return AdminScaffold(
          title: 'Painel administrativo',
          activeDestination: AdminDestinationId.dashboard,
          body: content,
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.controller});

  final AdminDashboardData data;
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < AdminBreakpoints.compactMax
            ? 2
            : constraints.maxWidth <= AdminBreakpoints.mediumMax
                ? 2
                : 4;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            children: [
              AdminPageHeader(
                title: 'Painel',
                subtitle: 'Acompanhe a operação da Pizzaria Campy',
                actions: [
                  IconButton(
                    tooltip: 'Atualizar painel',
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              _MetricsGrid(data: data, columns: columns),
              const SizedBox(height: AdminSpacing.xxl),
              _AttentionSection(data: data),
              const SizedBox(height: AdminSpacing.xxl),
              _RecentOrders(
                orders: data.recentOrders,
                controller: controller,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.data, required this.columns});

  final AdminDashboardData data;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Novos pedidos',
        data.metrics['pending_orders'] ?? 0,
        Icons.notifications_active_outlined,
        AdminColors.warning,
      ),
      (
        'Preparando',
        data.metrics['preparing_orders'] ?? 0,
        Icons.local_fire_department_outlined,
        AdminColors.warning,
      ),
      (
        'Prontos',
        data.metrics['ready_orders'] ?? 0,
        Icons.check_circle_outline,
        AdminColors.success,
      ),
      (
        'Clientes',
        data.metrics['customers'] ?? 0,
        Icons.people_outline,
        AdminColors.info,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AdminSpacing.md,
        mainAxisSpacing: AdminSpacing.md,
        childAspectRatio: columns == 2 ? 1.55 : 1.8,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return AdminMetricCard(
          label: metric.$1,
          value: '${metric.$2}',
          icon: metric.$3,
          color: metric.$4,
        );
      },
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final underReview = data.recentOrders
        .where((order) => order.paymentStatus == 'UNDER_REVIEW')
        .length;
    final ready = data.metrics['ready_orders'] ?? 0;
    if (underReview == 0 && ready == 0) return const SizedBox.shrink();

    return AdminSectionCard(
      title: 'Atenção operacional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (underReview > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pix_outlined),
              title: Text('$underReview PIX aguardando revisão'),
              subtitle:
                  const Text('Revise os pagamentos nos pedidos recentes.'),
            ),
          if (ready > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text('$ready pedido(s) pronto(s)'),
              subtitle: const Text('Há pedidos aguardando a próxima ação.'),
            ),
        ],
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.orders, required this.controller});

  final List<AdminOrderSummary> orders;
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Pedidos recentes',
      child: orders.isEmpty
          ? const SizedBox(
              height: 180,
              child: AdminEmptyState(
                message:
                    'Nenhum pedido recente.\nOs novos pedidos aparecerão aqui.',
                icon: Icons.receipt_long_outlined,
              ),
            )
          : Column(
              children: [
                for (final order in orders)
                  _OrderTile(order: order, controller: controller),
              ],
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.controller});

  final AdminOrderSummary order;
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(order);
    final paymentUnderReview =
        order.paymentStatus == 'UNDER_REVIEW' && order.paymentId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.md),
      child: Card(
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
                  if (_canCancel(order))
                    AdminActionMenu(
                      items: const [
                        AdminActionMenuItem(
                          value: 'cancel',
                          label: 'Cancelar pedido',
                          icon: Icons.cancel_outlined,
                        ),
                      ],
                      onSelected: (_) => _cancel(context),
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
              if (paymentUnderReview) ...[
                const SizedBox(height: AdminSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _reviewPayment(context),
                  icon: const Icon(Icons.pix_outlined),
                  label: const Text('Revisar PIX'),
                ),
              ],
              if (next != null) ...[
                const SizedBox(height: AdminSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _confirmStatus(context, order),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_actionLabel(order)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStatus(
      BuildContext context, AdminOrderSummary order) async {
    final next = _nextStatus(order);
    if (next == null) return;
    final accepted = await AdminConfirmationDialog.show(
      context: context,
      title: '${_actionLabel(order)}?',
      message:
          '${order.number} será movido para ${AdminStatuses.forValue(next).label}.',
    );
    if (accepted) await controller.changeStatus(order.id, next);
  }

  Future<void> _cancel(BuildContext context) async {
    final accepted = await AdminConfirmationDialog.show(
      context: context,
      title: 'Cancelar pedido?',
      message: '${order.number} será cancelado.',
      confirmLabel: 'Cancelar pedido',
      cancelLabel: 'Voltar',
      destructive: true,
    );
    if (accepted) await controller.changeStatus(order.id, 'CANCELLED');
  }

  Future<void> _reviewPayment(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Revisar PIX ${order.number}'),
        content: Text(order.proofUrl == null
            ? 'Nenhum link de comprovante informado.'
            : order.proofUrl!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'FAILED'),
            child: const Text('Recusar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'CONFIRMED'),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (result != null && order.paymentId != null) {
      await controller.reviewPayment(order.paymentId!, result);
    }
  }

  bool _canCancel(AdminOrderSummary value) =>
      {'PENDING', 'CONFIRMED', 'PREPARING'}.contains(value.status);

  String? _nextStatus(AdminOrderSummary value) => AdminOrderActions.forOrder(
        status: value.status,
        fulfillmentType: value.fulfillmentType,
      )?.targetStatus;

  String _actionLabel(AdminOrderSummary order) {
    final action = AdminOrderActions.forOrder(
      status: order.status,
      fulfillmentType: order.fulfillmentType,
    );
    return action?.label ?? 'Atualizar pedido';
  }
}

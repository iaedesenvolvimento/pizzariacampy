import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_dashboard_controller.dart';
import 'admin_hours_page.dart';
import 'admin_catalog_page.dart';
import 'admin_options_page.dart';
import 'admin_delivery_zones_page.dart';
import 'admin_coupons_page.dart';
import 'admin_orders_page.dart';
import 'admin_customers_page.dart';
import 'admin_settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminDashboardController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    final controller = AdminDashboardController(
        ApiClient(config: AppConfig.fromEnvironment()), storage);
    if (!mounted) return;
    setState(() => _controller = controller);
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.status == AdminDashboardStatus.loading ||
            controller.status == AdminDashboardStatus.idle) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (controller.data == null) {
          return Scaffold(
              appBar: AppBar(title: const Text('Painel administrativo')),
              body:
                  Center(child: Text(controller.errorMessage ?? 'Sem dados.')));
        }
        final data = controller.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Painel administrativo')),
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('Operação rápida',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _metric('Novos pedidos', data.metrics['pending_orders'] ?? 0,
                      Icons.notifications_active_outlined),
                  _metric('Preparando', data.metrics['preparing_orders'] ?? 0,
                      Icons.local_fire_department_outlined),
                  _metric('Prontos', data.metrics['ready_orders'] ?? 0,
                      Icons.check_circle_outline),
                  _metric('Clientes', data.metrics['customers'] ?? 0,
                      Icons.people_outline),
                ],
              ),
              const SizedBox(height: 24),
              Text('Módulos', style: Theme.of(context).textTheme.titleLarge),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Pedidos',
                    'Produtos',
                    'Categorias',
                    'Sabores',
                    'Tamanhos',
                    'Bordas',
                    'Adicionais',
                    'Clientes',
                    'Cupons',
                    'Entregas',
                    'Horários',
                    'Configurações'
                  ].map((label) {
                    if (label == 'Horários') {
                      return ActionChip(
                          avatar: const Icon(Icons.schedule, size: 18),
                          label: Text(label),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const AdminHoursPage())));
                    }
                    if (label == 'Produtos') {
                      return ActionChip(
                          avatar: const Icon(Icons.fastfood, size: 18),
                          label: Text(label),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const AdminCatalogPage(
                                      mode: AdminCatalogMode.products))));
                    }
                    if (label == 'Categorias') {
                      return ActionChip(
                          avatar: const Icon(Icons.category_outlined, size: 18),
                          label: Text(label),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const AdminCatalogPage(
                                      mode: AdminCatalogMode.categories))));
                    }
                    if (label == 'Tamanhos') {
                      return ActionChip(
                        avatar: const Icon(Icons.straighten_outlined, size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminCatalogPage(
                                mode: AdminCatalogMode.products),
                          ),
                        ),
                      );
                    }
                    if (label == 'Clientes') {
                      return ActionChip(
                        avatar: const Icon(Icons.people_outline, size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const AdminCustomersPage()),
                        ),
                      );
                    }
                    if (label == 'Configurações') {
                      return ActionChip(
                        avatar: const Icon(Icons.settings_outlined, size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const AdminSettingsPage()),
                        ),
                      );
                    }
                    if (label == 'Sabores' ||
                        label == 'Bordas' ||
                        label == 'Adicionais') {
                      final mode = label == 'Sabores'
                          ? AdminOptionMode.flavors
                          : label == 'Bordas'
                              ? AdminOptionMode.edges
                              : AdminOptionMode.extras;
                      return ActionChip(
                        avatar: const Icon(Icons.tune, size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => AdminOptionsPage(mode: mode))),
                      );
                    }
                    if (label == 'Entregas') {
                      return ActionChip(
                        avatar: const Icon(Icons.delivery_dining_outlined,
                            size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AdminDeliveryZonesPage())),
                      );
                    }
                    if (label == 'Cupons') {
                      return ActionChip(
                        avatar: const Icon(Icons.confirmation_number_outlined,
                            size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const AdminCouponsPage())),
                      );
                    }
                    if (label == 'Pedidos') {
                      return ActionChip(
                        avatar:
                            const Icon(Icons.receipt_long_outlined, size: 18),
                        label: Text(label),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const AdminOrdersPage())),
                      );
                    }
                    return Chip(
                        avatar: const Icon(Icons.chevron_right, size: 18),
                        label: Text(label));
                  }).toList()),
              const SizedBox(height: 24),
              Text('Pedidos recentes',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...data.recentOrders.map((order) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(order.number),
                    subtitle: Text(_status(order.status)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('R\$ ${order.total.replaceAll('.', ',')}'),
                        if (order.paymentStatus == 'UNDER_REVIEW' &&
                            order.paymentId != null)
                          TextButton(
                            onPressed: () =>
                                _reviewPayment(context, controller, order),
                            child: const Text('Revisar PIX'),
                          ),
                      ],
                    ),
                    onTap: _nextStatus(order) == null
                        ? null
                        : () => _confirmStatus(context, controller, order),
                    onLongPress: {'PENDING', 'CONFIRMED', 'PREPARING'}
                            .contains(order.status)
                        ? () => _cancelOrder(context, controller, order)
                        : null,
                  )),
            ]),
          ),
        );
      },
    );
  }

  Widget _metric(String label, int value, IconData icon) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon),
            const Spacer(),
            Text('$value',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
          ])));

  Future<void> _confirmStatus(BuildContext context,
      AdminDashboardController controller, AdminOrderSummary order) async {
    final next = _nextStatus(order);
    if (next == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_actionLabel(next)} pedido?'),
        content: Text('${order.number} será movido para ${_status(next)}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (accepted == true) await controller.changeStatus(order.id, next);
  }

  Future<void> _cancelOrder(BuildContext context,
      AdminDashboardController controller, AdminOrderSummary order) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: Text('${order.number} será cancelado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancelar pedido')),
        ],
      ),
    );
    if (accepted == true) await controller.changeStatus(order.id, 'CANCELLED');
  }

  Future<void> _reviewPayment(BuildContext context,
      AdminDashboardController controller, AdminOrderSummary order) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revisar PIX ${order.number}'),
        content: Text(order.proofUrl == null
            ? 'Nenhum link de comprovante informado.'
            : order.proofUrl!),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'FAILED'),
              child: const Text('Recusar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, 'CONFIRMED'),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (result != null && order.paymentId != null) {
      await controller.reviewPayment(order.paymentId!, result);
    }
  }

  String? _nextStatus(AdminOrderSummary order) => switch (order.status) {
        'PENDING' => 'CONFIRMED',
        'CONFIRMED' => 'PREPARING',
        'PREPARING' => 'READY',
        'READY' => order.fulfillmentType == 'DELIVERY'
            ? 'OUT_FOR_DELIVERY'
            : 'DELIVERED',
        'OUT_FOR_DELIVERY' => 'DELIVERED',
        _ => null,
      };

  String _actionLabel(String status) => switch (status) {
        'CONFIRMED' => 'Aceitar',
        'PREPARING' => 'Iniciar preparo',
        'READY' => 'Marcar pronto',
        'OUT_FOR_DELIVERY' => 'Enviar para entrega',
        'DELIVERED' => 'Concluir',
        _ => 'Atualizar',
      };

  String _status(String value) => switch (value) {
        'PENDING' => 'Pedido recebido',
        'CONFIRMED' => 'Confirmado',
        'PREPARING' => 'Preparando',
        'READY' => 'Pronto',
        'OUT_FOR_DELIVERY' => 'Saiu para entrega',
        'DELIVERED' => 'Entregue',
        'CANCELLED' => 'Cancelado',
        _ => value,
      };
}

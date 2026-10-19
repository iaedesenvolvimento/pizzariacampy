import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/notifications/realtime_notification_service.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_dashboard_controller.dart';
import 'admin_design_system.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  final _searchController = TextEditingController();
  AdminApiClient? _adminApi;
  StreamSubscription<RealtimeNotification>? _notificationSubscription;
  List<AdminOrderSummary> _orders = const [];
  String? _selectedStatus;
  bool _loading = true;
  String? _error;

  static const _filters = <String?, String>{
    null: 'Todos',
    'PENDING': 'Novos',
    'CONFIRMED': 'Confirmados',
    'PREPARING': 'Em preparo',
    'READY': 'Prontos',
    'OUT_FOR_DELIVERY': 'Em entrega',
    'DELIVERED': 'Concluídos',
    'CANCELLED': 'Cancelados',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _notificationSubscription =
        realtimeNotificationService.events.listen((event) {
      if (event.type == 'order.created' ||
          event.type == 'order.status_changed') {
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final storage = await AppStorage.create();
      _adminApi = AdminApiClient(_api, storage);
      final response = await _adminApi!.get('/admin/orders?limit=100');
      if (response is! List<dynamic>) throw const FormatException();
      final orders = response
          .whereType<Map<String, dynamic>>()
          .map(AdminOrderSummary.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os pedidos.';
        _loading = false;
      });
    }
  }

  List<AdminOrderSummary> get _visibleOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesStatus =
          _selectedStatus == null || order.status == _selectedStatus;
      final matchesSearch =
          query.isEmpty || order.number.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  int _count(String? status) => status == null
      ? _orders.length
      : _orders.where((order) => order.status == status).length;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Pedidos',
      activeDestination: AdminDestinationId.orders,
      body: _loading && _orders.isEmpty
          ? const AdminLoadingState(label: 'Carregando pedidos')
          : _error != null && _orders.isEmpty
              ? AdminErrorState(message: _error!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final orders = _visibleOrders;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        children: [
          AdminPageHeader(
            title: 'Pedidos',
            subtitle: 'Acompanhe e gerencie os pedidos da pizzaria.',
            actions: [
              IconButton(
                tooltip: 'Atualizar pedidos',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          AdminSearchField(
            controller: _searchController,
            hintText: 'Buscar por número do pedido',
          ),
          const SizedBox(height: AdminSpacing.md),
          AdminFilterBar(
            children: [
              for (final entry in _filters.entries)
                ChoiceChip(
                  label: Text('${entry.value} ${_count(entry.key)}'),
                  selected: _selectedStatus == entry.key,
                  onSelected: (_) =>
                      setState(() => _selectedStatus = entry.key),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AdminSpacing.md),
            Text(_error!, style: TextStyle(color: AdminColors.danger)),
          ],
          const SizedBox(height: AdminSpacing.xl),
          if (orders.isEmpty)
            SizedBox(
              height: 220,
              child: AdminEmptyState(
                message: _selectedStatus == null &&
                        _searchController.text.trim().isNotEmpty
                    ? 'Nenhum pedido encontrado.'
                    : _selectedStatus == null
                        ? 'Nenhum pedido encontrado.'
                        : 'Não há pedidos ${_filters[_selectedStatus]!.toLowerCase()} no momento.',
                icon: Icons.receipt_long_outlined,
              ),
            )
          else
            for (final order in orders)
              Padding(
                padding: const EdgeInsets.only(bottom: AdminSpacing.md),
                child: AdminOrderCard(
                  order: order,
                  onAction: AdminOrderActions.forOrder(
                              status: order.status,
                              fulfillmentType: order.fulfillmentType) ==
                          null
                      ? null
                      : () => _changeStatus(order),
                  onCancel: _canCancel(order) ? () => _cancel(order) : null,
                  onReviewPayment: order.paymentStatus == 'UNDER_REVIEW'
                      ? () => _reviewPayment(order)
                      : null,
                  onDetails: () => _showDetails(order),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(AdminOrderSummary order) async {
    final action = AdminOrderActions.forOrder(
      status: order.status,
      fulfillmentType: order.fulfillmentType,
    );
    if (action == null || _adminApi == null) return;
    final accepted = await AdminConfirmationDialog.show(
      context: context,
      title: '${action.label}?',
      message:
          '${order.number} será atualizado para ${AdminStatuses.forValue(action.targetStatus).label}.',
    );
    if (!accepted) return;
    try {
      await _adminApi!.patch(
        '/admin/orders/${order.id}/status',
        body: {'status': action.targetStatus},
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar o pedido.')),
        );
      }
    }
  }

  Future<void> _cancel(AdminOrderSummary order) async {
    if (_adminApi == null) return;
    final accepted = await AdminConfirmationDialog.show(
      context: context,
      title: 'Cancelar pedido?',
      message: '${order.number} será cancelado.',
      confirmLabel: 'Cancelar pedido',
      cancelLabel: 'Voltar',
      destructive: true,
    );
    if (!accepted) return;
    try {
      await _adminApi!.patch(
        '/admin/orders/${order.id}/status',
        body: const {'status': 'CANCELLED'},
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível cancelar o pedido.')),
        );
      }
    }
  }

  Future<void> _reviewPayment(AdminOrderSummary order) async {
    if (order.paymentId == null || _adminApi == null) return;
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
    if (result == null) return;
    try {
      await _adminApi!.patch(
        '/admin/payments/${order.paymentId}/review',
        body: {'status': result},
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível revisar o PIX.')),
        );
      }
    }
  }

  Future<void> _showDetails(AdminOrderSummary order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo do pedido',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AdminSpacing.md),
              Text(order.number,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AdminSpacing.sm),
              AdminStatusBadge(status: order.status),
              const SizedBox(height: AdminSpacing.lg),
              _detailRow('Atendimento',
                  order.fulfillmentType == 'DELIVERY' ? 'Entrega' : 'Retirada'),
              if (order.createdAt != null)
                _detailRow('Criado em', _formatDate(order.createdAt!)),
              if (order.paymentStatus != null)
                _detailRow('Pagamento', _paymentLabel(order.paymentStatus!)),
              _detailRow('Total', 'R\$ ${order.total.replaceAll('.', ',')}'),
              if (order.customerName?.isNotEmpty == true) ...[
                const Divider(height: AdminSpacing.xl),
                Text('Cliente', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AdminSpacing.sm),
                _detailRow('Nome', order.customerName!),
                if (order.customerPhone?.isNotEmpty == true)
                  _detailRow('Telefone', order.customerPhone!),
                if (order.customerEmail?.isNotEmpty == true)
                  _detailRow('E-mail', order.customerEmail!),
              ],
              if (order.deliveryAddressSnapshot != null) ...[
                const SizedBox(height: AdminSpacing.sm),
                _detailRow(
                    'Endereço', _formatAddress(order.deliveryAddressSnapshot!)),
              ],
              const SizedBox(height: AdminSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );

  String _formatDate(DateTime value) =>
      '${value.toLocal().day.toString().padLeft(2, '0')}/${value.toLocal().month.toString().padLeft(2, '0')} ${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';

  String _paymentLabel(String value) => switch (value) {
        'UNDER_REVIEW' => 'PIX aguardando revisão',
        'CONFIRMED' => 'Pagamento confirmado',
        'FAILED' => 'Pagamento recusado',
        _ => value,
      };

  String _formatAddress(Map<String, dynamic> address) {
    final street = address['address']?.toString().trim() ?? '';
    final number = address['number']?.toString().trim() ?? '';
    final complement = address['complement']?.toString().trim() ?? '';
    final neighborhood = address['neighborhood']?.toString().trim() ?? '';
    final city = address['city']?.toString().trim() ?? '';
    final line = [
      if (street.isNotEmpty) street,
      if (number.isNotEmpty) number,
      if (complement.isNotEmpty) complement,
    ].join(', ');
    return [
      if (line.isNotEmpty) line,
      if (neighborhood.isNotEmpty) neighborhood,
      if (city.isNotEmpty) city,
    ].join(' · ');
  }

  bool _canCancel(AdminOrderSummary order) =>
      {'PENDING', 'CONFIRMED', 'PREPARING'}.contains(order.status);
}

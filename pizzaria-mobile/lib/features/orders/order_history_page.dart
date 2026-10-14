import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../tracking/order_tracking_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({required this.accessToken, super.key});

  final String? accessToken;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _apiClient = ApiClient(config: AppConfig.fromEnvironment());
  List<_OrderHistoryItem> _orders = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final token = widget.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      final response = await _apiClient.get(
        '/orders?limit=50',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response is! List<dynamic>) throw const FormatException('Pedidos inválidos.');
      _orders = response.whereType<Map<String, dynamic>>().map(_OrderHistoryItem.fromJson).toList();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar seus pedidos.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pedidos')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return ListView(children: [
        const SizedBox(height: 180),
        _Message(icon: Icons.cloud_off_outlined, text: _errorMessage!, action: _load),
      ]);
    }
    if (_orders.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 180),
        _Message(icon: Icons.receipt_long_outlined, text: 'Você ainda não fez nenhum pedido.'),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${order.itemsCount} item(ns) • ${_fulfillmentLabel(order.fulfillmentType)}\n${_statusLabel(order.status)}'),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_currency(order.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => OrderTrackingPage(orderId: order.id)),
            ),
          ),
        );
      },
    );
  }

  String _currency(String value) {
    final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _statusLabel(String status) => switch (status) {
        'PENDING' => 'Aguardando confirmação',
        'CONFIRMED' => 'Confirmado',
        'PREPARING' => 'Em preparo',
        'READY' => 'Pronto',
        'OUT_FOR_DELIVERY' => 'Saiu para entrega',
        'COMPLETED' => 'Concluído',
        'CANCELLED' => 'Cancelado',
        _ => status,
      };

  String _fulfillmentLabel(String type) => type == 'DELIVERY' ? 'Entrega' : 'Retirada';
}

class _OrderHistoryItem {
  const _OrderHistoryItem({required this.id, required this.orderNumber, required this.status, required this.fulfillmentType, required this.total, required this.itemsCount});

  factory _OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return _OrderHistoryItem(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'Pedido',
      status: json['status']?.toString() ?? '',
      fulfillmentType: json['fulfillment_type']?.toString() ?? 'PICKUP',
      total: json['total_amount']?.toString() ?? '0.00',
      itemsCount: items is List<dynamic> ? items.length : 0,
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final String fulfillmentType;
  final String total;
  final int itemsCount;
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: action, child: const Text('Tentar novamente')),
              ],
            ],
          ),
        ),
      );
}

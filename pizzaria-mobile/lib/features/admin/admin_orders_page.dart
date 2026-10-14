import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    _adminApi = AdminApiClient(_api, storage);
    try {
      final response = await _adminApi!.get('/admin/orders?limit=100');
      if (!mounted) return;
      setState(() {
        _orders = (response as List<dynamic>).whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _advance(Map<String, dynamic> order) async {
    final next = switch (order['status']) {
      'PENDING' => 'CONFIRMED',
      'CONFIRMED' => 'PREPARING',
      'PREPARING' => 'READY',
      'READY' => order['fulfillment_type'] == 'DELIVERY' ? 'OUT_FOR_DELIVERY' : 'DELIVERED',
      'OUT_FOR_DELIVERY' => 'DELIVERED',
      _ => null,
    };
    if (next == null) return;
    try {
      await _adminApi!.patch('/admin/orders/${order['id']}/status', body: {'status': next});
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pedidos')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: _orders.isEmpty
                          ? [const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nenhum pedido encontrado.')))]
                          : _orders.map((order) => Card(
                                child: ListTile(
                                  title: Text(
                                    order['order_number']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('${order['status']} · ${order['fulfillment_type']}'),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text('R\$ ${order['total_amount'] ?? '0.00'}'),
                                    if (!{'DELIVERED', 'CANCELLED'}.contains(order['status']))
                                      SizedBox(
                                        height: 40,
                                        child: TextButton(
                                          onPressed: () => _advance(order),
                                          child: const Text('Avançar'),
                                        ),
                                      ),
                                  ]),
                                ),
                              )).toList(),
                    ),
                  ),
      );
}

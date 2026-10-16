import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminFlavorPricesPage extends StatefulWidget {
  const AdminFlavorPricesPage(
      {required this.flavorId, required this.flavorName, super.key});

  final String flavorId;
  final String flavorName;

  @override
  State<AdminFlavorPricesPage> createState() => _AdminFlavorPricesPageState();
}

class _AdminFlavorPricesPageState extends State<AdminFlavorPricesPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _sizes = const [];
  Map<String, dynamic> _prices = {};
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
      final products = await _adminApi!.get('/admin/catalog/products');
      final priceResponse = await _adminApi!
          .get('/admin/catalog/flavor-prices?flavor_id=${widget.flavorId}');
      final sizes = <Map<String, dynamic>>[];
      if (products is List<dynamic>) {
        for (final product in products.whereType<Map<String, dynamic>>()) {
          if (product['product_type']?.toString() != 'PIZZA') continue;
          final productSizes = await _adminApi!
              .get('/admin/catalog/products/${product['id']}/sizes');
          if (productSizes is List<dynamic>) {
            for (final size in productSizes.whereType<Map<String, dynamic>>()) {
              sizes.add({...size, 'product_name': product['name']});
            }
          }
        }
      }
      final prices = <String, dynamic>{};
      if (priceResponse is List<dynamic>) {
        for (final price in priceResponse.whereType<Map<String, dynamic>>()) {
          prices[price['product_size_id'].toString()] = price;
        }
      }
      if (!mounted) return;
      setState(() {
        _sizes = sizes;
        _prices = prices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os preços dos sabores.';
        _loading = false;
      });
    }
  }

  Future<void> _save(Map<String, dynamic> size) async {
    final controller = TextEditingController(
        text: _prices[size['id']?.toString()]?['price']?.toString() ??
            size['price']?.toString() ??
            '0');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.flavorName} · ${size['name']}'),
        content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Preço do sabor')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Salvar'))
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null || value.trim().isEmpty || _adminApi == null) {
      return;
    }
    final body = {'price': value.trim().replaceAll(',', '.')};
    try {
      final existing = _prices[size['id']?.toString()];
      dynamic savedPrice;
      if (existing is Map<String, dynamic>) {
        savedPrice = await _adminApi!.patch(
            '/admin/catalog/flavor-prices/${existing['id']}',
            body: body);
      } else {
        savedPrice = await _adminApi!.post('/admin/catalog/flavor-prices',
            body: {
              'flavor_id': widget.flavorId,
              'product_size_id': size['id'],
              ...body
            });
      }
      if (!mounted) {
        return;
      }
      final updatedPrice = savedPrice is Map<String, dynamic>
          ? savedPrice
          : <String, dynamic>{
              if (existing is Map<String, dynamic>) ...existing,
              'product_size_id': size['id'],
              'price': body['price'],
            };
      setState(() {
        _prices = {..._prices, size['id'].toString(): updatedPrice};
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível salvar o preço do sabor.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
        title: 'Preços · ${widget.flavorName}',
        activeDestination: AdminDestinationId.flavors,
        body: _loading
            ? const AdminLoadingState(label: 'Carregando preços dos sabores')
            : _error != null
                ? AdminErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _sizes.isEmpty
                            ? [
                                const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                        child:
                                            Text('Nenhum tamanho cadastrado.')))
                              ]
                            : _sizes.map((size) {
                                final price = _prices[size['id']?.toString()];
                                return Card(
                                    child: ListTile(
                                        title: Text(
                                            '${size['product_name']} · ${size['name']}'),
                                        subtitle: Text(price
                                                is Map<String, dynamic>
                                            ? 'R\$ ${price['price']?.toString().replaceAll('.', ',')}'
                                            : 'Preço não configurado'),
                                        trailing: IconButton(
                                            icon:
                                                const Icon(Icons.edit_outlined),
                                            onPressed: () => _save(size))));
                              }).toList()),
                  ),
      );
}

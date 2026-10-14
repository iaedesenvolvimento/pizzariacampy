import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _items = const [];
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
      final response = await _adminApi!.get('/admin/coupons');
      if (!mounted) return;
      setState(() {
        _items = (response as List<dynamic>).whereType<Map<String, dynamic>>().toList();
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

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CouponForm(),
    );
    if (result == null || _adminApi == null) return;
    try {
      await _adminApi!.post('/admin/coupons', body: result);
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    try {
      await _adminApi!.patch('/admin/coupons/${item['id']}', body: {
        'code': item['code'],
        'discount_type': item['discount_type'],
        'value': item['value'],
        'minimum_order_amount': item['minimum_order_amount'],
        'usage_limit': item['usage_limit'],
        'per_customer_limit': item['per_customer_limit'],
        'is_active': item['is_active'] != true,
        'description': item['description'],
      });
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cupons')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: _items.isEmpty
                          ? [const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nenhum cupom cadastrado.')))]
                          : _items.map((item) => Card(
                                child: ListTile(
                                  title: Text(item['code']?.toString() ?? ''),
                                  subtitle: Text('${item['discount_type']} · ${item['value']} · usado ${item['usage_count'] ?? 0} vez(es)'),
                                  trailing: Switch(value: item['is_active'] == true, onChanged: (_) => _toggle(item)),
                                ),
                              )).toList(),
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Adicionar')),
      );
}

class _CouponForm extends StatefulWidget {
  const _CouponForm();

  @override
  State<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<_CouponForm> {
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _minimum = TextEditingController(text: '0');
  String _type = 'PERCENTAGE';

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _minimum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Novo cupom'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código')),
          DropdownButtonFormField<String>(value: _type, items: const [DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentual')), DropdownMenuItem(value: 'FIXED', child: Text('Valor fixo'))], onChanged: (value) => setState(() => _type = value ?? _type), decoration: const InputDecoration(labelText: 'Tipo')),
          TextField(controller: _value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor')),
          TextField(controller: _minimum, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Pedido mínimo')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (_code.text.trim().length < 3 || _value.text.trim().isEmpty) return;
            Navigator.pop(context, {'code': _code.text.trim().toUpperCase(), 'discount_type': _type, 'value': _value.text.trim().replaceAll(',', '.'), 'minimum_order_amount': _minimum.text.trim().replaceAll(',', '.'), 'is_active': true});
          }, child: const Text('Salvar')),
        ],
      );
}

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminDeliveryZonesPage extends StatefulWidget {
  const AdminDeliveryZonesPage({super.key});

  @override
  State<AdminDeliveryZonesPage> createState() => _AdminDeliveryZonesPageState();
}

class _AdminDeliveryZonesPageState extends State<AdminDeliveryZonesPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _zones = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    if (!mounted) return;
    _adminApi = AdminApiClient(_api, storage);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _adminApi!.get('/admin/delivery-zones');
      if (response is! List<dynamic>) throw const FormatException('Zonas inválidas.');
      if (!mounted) return;
      setState(() {
        _zones = response.whereType<Map<String, dynamic>>().toList();
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

  Future<void> _edit([Map<String, dynamic>? zone]) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _ZoneForm(initial: zone),
    );
    if (result == null || _adminApi == null) return;
    try {
      final id = zone?['id']?.toString();
      if (id == null) {
        await _adminApi!.post('/admin/delivery-zones', body: result);
      } else {
        await _adminApi!.patch('/admin/delivery-zones/$id', body: result);
      }
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggle(Map<String, dynamic> zone) async {
    final id = zone['id']?.toString();
    if (id == null || _adminApi == null) return;
    final body = {
      'name': zone['name'],
      'city': zone['city'],
      'neighborhood': zone['neighborhood'],
      'delivery_fee': zone['delivery_fee'],
      'minimum_order_amount': zone['minimum_order_amount'],
      'estimated_minutes': zone['estimated_minutes'],
      'is_active': zone['is_active'] != true,
    };
    try {
      await _adminApi!.patch('/admin/delivery-zones/$id', body: body);
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _delete(Map<String, dynamic> zone) async {
    final id = zone['id']?.toString();
    if (id == null || _adminApi == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir zona?'),
        content: Text('Excluir ${zone['neighborhood']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _adminApi!.delete('/admin/delivery-zones/$id');
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _setAllZonesStatus(bool isActive) async {
    if (_adminApi == null) return;
    final action = isActive ? 'habilitar' : 'desabilitar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isActive ? 'Habilitar' : 'Desabilitar'} todas as zonas?'),
        content: Text('Esta ação vai $action todas as zonas, sem alterar taxas, mínimos ou prazos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(isActive ? 'Habilitar' : 'Desabilitar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await _adminApi!.post(
        '/admin/delivery-zones/bulk-status',
        body: {'is_active': isActive},
      );
      await _load();
      if (!mounted) return;
      final count = response is Map<String, dynamic> ? response['updated_count'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${count ?? 'Todas as'} zonas foram ${isActive ? 'habilitadas' : 'desabilitadas'}.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Zonas de entrega')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _setAllZonesStatus(true),
                              icon: const Icon(Icons.public),
                              label: const Text('Habilitar todas'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _setAllZonesStatus(false),
                              icon: const Icon(Icons.public_off),
                              label: const Text('Desabilitar todas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_zones.isEmpty)
                          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nenhuma zona cadastrada.')))
                        else
                          ..._zones.map((zone) => Card(
                                child: ListTile(
                                  title: Text('${zone['neighborhood']} · ${zone['city']}'),
                                  subtitle: Text('Taxa R\$ ${zone['delivery_fee']} · mínimo R\$ ${zone['minimum_order_amount']} · ${zone['estimated_minutes']} min'),
                                  leading: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(zone)),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Switch(value: zone['is_active'] == true, onChanged: (_) => _toggle(zone)),
                                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(zone)),
                                  ]),
                                ),
                              )),
                      ],
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Zona')),
      );
}

class _ZoneForm extends StatefulWidget {
  const _ZoneForm({this.initial});
  final Map<String, dynamic>? initial;
  @override
  State<_ZoneForm> createState() => _ZoneFormState();
}

class _ZoneFormState extends State<_ZoneForm> {
  late final _name = TextEditingController(text: widget.initial?['name']?.toString() ?? '');
  late final _city = TextEditingController(text: widget.initial?['city']?.toString() ?? 'Carapicuíba');
  late final _neighborhood = TextEditingController(text: widget.initial?['neighborhood']?.toString() ?? '');
  late final _fee = TextEditingController(text: widget.initial?['delivery_fee']?.toString() ?? '0');
  late final _minimum = TextEditingController(text: widget.initial?['minimum_order_amount']?.toString() ?? '0');
  late final _minutes = TextEditingController(text: widget.initial?['estimated_minutes']?.toString() ?? '45');

  @override
  void dispose() { for (final c in [_name, _city, _neighborhood, _fee, _minimum, _minutes]) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? 'Nova zona' : 'Editar zona'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'Cidade')),
          TextField(controller: _neighborhood, decoration: const InputDecoration(labelText: 'Bairro')),
          TextField(controller: _fee, decoration: const InputDecoration(labelText: 'Taxa de entrega')),
          TextField(controller: _minimum, decoration: const InputDecoration(labelText: 'Pedido mínimo')),
          TextField(controller: _minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prazo em minutos')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (_name.text.trim().isEmpty || _city.text.trim().isEmpty || _neighborhood.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'name': _name.text.trim(), 'city': _city.text.trim(), 'neighborhood': _neighborhood.text.trim(),
              'delivery_fee': _fee.text.trim().replaceAll(',', '.'), 'minimum_order_amount': _minimum.text.trim().replaceAll(',', '.'),
              'estimated_minutes': _minutes.text.trim(), 'is_active': 'true',
            });
          }, child: const Text('Salvar')),
        ],
      );
}

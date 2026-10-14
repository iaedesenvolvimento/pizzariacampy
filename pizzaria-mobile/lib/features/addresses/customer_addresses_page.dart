import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

class CustomerAddressesPage extends StatefulWidget {
  const CustomerAddressesPage({required this.accessToken, super.key});
  final String? accessToken;

  @override
  State<CustomerAddressesPage> createState() => _CustomerAddressesPageState();
}

class _CustomerAddressesPageState extends State<CustomerAddressesPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  List<Map<String, dynamic>> _addresses = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get('/customer/addresses', headers: {'Authorization': 'Bearer ${widget.accessToken}'});
      _addresses = response is List<dynamic> ? response.whereType<Map<String, dynamic>>().toList() : const [];
    } catch (_) { _error = 'Não foi possível carregar os endereços.'; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _AddressDialog());
    if (result == null) return;
    try {
      await _api.post('/customer/addresses', headers: {'Authorization': 'Bearer ${widget.accessToken}'}, body: result);
      await _load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o endereço.'))); }
  }

  Future<void> _delete(String id) async {
    await _api.delete('/customer/addresses/$id', headers: {'Authorization': 'Bearer ${widget.accessToken}'});
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus endereços'), actions: [IconButton(onPressed: _add, icon: const Icon(Icons.add), tooltip: 'Adicionar endereço')]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!)) : RefreshIndicator(onRefresh: _load, child: _addresses.isEmpty ? ListView(children: const [SizedBox(height: 220), Center(child: Text('Nenhum endereço salvo.'))]) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _addresses.length, itemBuilder: (_, index) {
      final address = _addresses[index];
      return Card(child: ListTile(leading: Icon(address['is_default'] == true ? Icons.home : Icons.location_on_outlined), title: Text(address['label']?.toString() ?? 'Endereço'), subtitle: Text('${address['address']}\n${address['neighborhood']} · ${address['city']}'), trailing: IconButton(onPressed: () => _delete(address['id'].toString()), icon: const Icon(Icons.delete_outline))));
    })),
  );
}

class _AddressDialog extends StatefulWidget { const _AddressDialog(); @override State<_AddressDialog> createState() => _AddressDialogState(); }
class _AddressDialogState extends State<_AddressDialog> {
  final _label = TextEditingController(text: 'Casa');
  final _address = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController(text: 'Carapicuíba');
  final _complement = TextEditingController();
  bool _default = true;
  @override void dispose() { for (final c in [_label, _address, _neighborhood, _city, _complement]) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('Novo endereço'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _label, decoration: const InputDecoration(labelText: 'Identificação')), TextField(controller: _address, decoration: const InputDecoration(labelText: 'Endereço')), TextField(controller: _neighborhood, decoration: const InputDecoration(labelText: 'Bairro')), TextField(controller: _city, decoration: const InputDecoration(labelText: 'Cidade')), TextField(controller: _complement, decoration: const InputDecoration(labelText: 'Complemento')), CheckboxListTile(value: _default, onChanged: (value) => setState(() => _default = value ?? true), title: const Text('Usar como padrão'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, {'label': _label.text.trim(), 'address': _address.text.trim(), 'neighborhood': _neighborhood.text.trim(), 'city': _city.text.trim(), 'complement': _complement.text.trim().isEmpty ? null : _complement.text.trim(), 'is_default': _default}), child: const Text('Salvar'))]);
}

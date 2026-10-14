import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_flavor_prices_page.dart';

enum AdminOptionMode { flavors, edges, extras }

class AdminOptionsPage extends StatefulWidget {
  const AdminOptionsPage({required this.mode, super.key});

  final AdminOptionMode mode;

  @override
  State<AdminOptionsPage> createState() => _AdminOptionsPageState();
}

class _AdminOptionsPageState extends State<AdminOptionsPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _items = const [];
  String? _token;
  String? _error;
  bool _loading = true;

  String get _path => switch (widget.mode) {
        AdminOptionMode.flavors => 'flavors',
        AdminOptionMode.edges => 'edges',
        AdminOptionMode.extras => 'extras',
      };

  String get _title => switch (widget.mode) {
        AdminOptionMode.flavors => 'Sabores',
        AdminOptionMode.edges => 'Bordas',
        AdminOptionMode.extras => 'Adicionais',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    if (!mounted) return;
    _token = storage.accessToken;
    _adminApi = AdminApiClient(_api, storage);
    try {
      final response = await _adminApi!.get('/admin/catalog/$_path');
      if (response is! List<dynamic>) {
        throw const FormatException('Opções inválidas.');
      }
      if (!mounted) return;
      setState(() {
        _items = response.whereType<Map<String, dynamic>>().toList();
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
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) =>
          _OptionForm(withPrice: widget.mode != AdminOptionMode.flavors),
    );
    if (result == null || _token == null) return;
    final body = widget.mode == AdminOptionMode.flavors
        ? {'name': result['name'], 'description': result['description']}
        : {'name': result['name'], 'price': result['price']};
    try {
      await _adminApi!.post('/admin/catalog/$_path', body: body);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || _token == null) return;
    try {
      await _adminApi!.patch('/admin/catalog/$_path/$id',
          body: {'is_active': item['is_active'] != true});
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: _items.isEmpty
                          ? [
                              const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                      child:
                                          Text('Nenhum registro cadastrado.')))
                            ]
                          : _items
                              .map((item) => Card(
                                    child: ListTile(
                                      title:
                                          Text(item['name']?.toString() ?? ''),
                                      subtitle: widget.mode ==
                                              AdminOptionMode.flavors
                                          ? Text(
                                              item['description']?.toString() ??
                                                  '')
                                          : Text('R\$ ${item['price']}'),
                                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                        if (widget.mode == AdminOptionMode.flavors)
                                          IconButton(
                                            tooltip: 'Preços por tamanho',
                                            icon: const Icon(Icons.price_change_outlined),
                                            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AdminFlavorPricesPage(flavorId: item['id'].toString(), flavorName: item['name'].toString()))),
                                          ),
                                        Switch(value: item['is_active'] == true, onChanged: (_) => _toggle(item)),
                                      ]),
                                    ),
                                  ))
                              .toList(),
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar')),
      );
}

class _OptionForm extends StatefulWidget {
  const _OptionForm({required this.withPrice});

  final bool withPrice;

  @override
  State<_OptionForm> createState() => _OptionFormState();
}

class _OptionFormState extends State<_OptionForm> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.withPrice ? 'Novo adicional' : 'Novo sabor'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome')),
          if (!widget.withPrice)
            TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Descrição')),
          if (widget.withPrice)
            TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty ||
                  (widget.withPrice && _price.text.trim().isEmpty)) {
                return;
              }
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'description': _description.text.trim(),
                'price': _price.text.trim().replaceAll(',', '.')
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      );
}

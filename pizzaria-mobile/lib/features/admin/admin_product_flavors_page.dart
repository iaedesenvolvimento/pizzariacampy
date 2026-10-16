import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminProductFlavorsPage extends StatefulWidget {
  const AdminProductFlavorsPage({
    required this.productId,
    required this.productName,
    required this.sizeId,
    required this.sizeName,
    super.key,
  });

  final String productId;
  final String productName;
  final String sizeId;
  final String sizeName;

  @override
  State<AdminProductFlavorsPage> createState() => _AdminProductFlavorsPageState();
}

class _AdminProductFlavorsPageState extends State<AdminProductFlavorsPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _flavors = const [];
  Set<String> _selected = <String>{};
  String _query = '';
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    _adminApi = AdminApiClient(_api, storage);
    try {
      final all = await _adminApi!.get('/admin/catalog/flavors');
      final selected = await _adminApi!.get(
          '/admin/catalog/products/${widget.productId}/sizes/${widget.sizeId}/flavors');
      if (all is! List || selected is! List) {
        throw const FormatException('Sabores inválidos.');
      }
      if (!mounted) return;
      setState(() {
        _flavors = all
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['is_active'] == true)
            .toList()
          ..sort((a, b) => (a['name']?.toString() ?? '')
              .toLowerCase()
              .compareTo((b['name']?.toString() ?? '').toLowerCase()));
        _selected = selected
            .whereType<Map>()
            .map((item) => item['id']?.toString())
            .whereType<String>()
            .toSet();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os sabores.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_selected.isEmpty || _saving || _adminApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione pelo menos um sabor para esta pizza.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _adminApi!.put(
        '/admin/catalog/products/${widget.productId}/sizes/${widget.sizeId}/flavors',
        body: {'flavor_ids': _selected.toList()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sabores da pizza atualizados.')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível salvar os sabores.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _flavors.where((flavor) => (flavor['name']?.toString() ?? '')
        .toLowerCase()
        .contains(_query.trim().toLowerCase()));
    return AdminScaffold(
      title: 'Sabores · ${widget.productName}',
      activeDestination: AdminDestinationId.products,
      body: _loading
          ? const AdminLoadingState(label: 'Carregando sabores')
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sabores do tamanho ${widget.sizeName}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              const Text('O cliente verá somente os sabores selecionados aqui.'),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Buscar sabor',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) => setState(() => _query = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        children: visible
                            .map((flavor) => Card(
                                  child: CheckboxListTile(
                                    value: _selected.contains(flavor['id']?.toString()),
                                    title: Text(flavor['name']?.toString() ?? ''),
                                    subtitle: _selected.contains(flavor['id']?.toString())
                                        ? const Text('Disponível para o cliente')
                                        : null,
                                    onChanged: (value) => setState(() {
                                      final id = flavor['id']?.toString();
                                      if (id == null) return;
                                      if (value == true) {
                                        _selected.add(id);
                                      } else {
                                        _selected.remove(id);
                                      }
                                    }),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Salvando' : 'Salvar sabores'),
            ),
    );
  }
}

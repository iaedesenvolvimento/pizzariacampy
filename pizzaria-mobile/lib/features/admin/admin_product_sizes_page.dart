import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminProductSizesPage extends StatefulWidget {
  const AdminProductSizesPage(
      {required this.productId,
      required this.productName,
      required this.productType,
      super.key});

  final String productId;
  final String productName;
  final String productType;

  @override
  State<AdminProductSizesPage> createState() => _AdminProductSizesPageState();
}

class _AdminProductSizesPageState extends State<AdminProductSizesPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _sizes = const [];
  String? _token;
  String? _error;
  bool _loading = true;

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
      final response = await _adminApi!
          .get('/admin/catalog/products/${widget.productId}/sizes');
      if (response is! List<dynamic>) {
        throw const FormatException('Tamanhos inválidos.');
      }
      if (!mounted) return;
      setState(() {
        _sizes = response.whereType<Map<String, dynamic>>().toList();
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
    if (_token == null) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _SizeForm(productType: widget.productType),
    );
    if (result == null) return;
    try {
      await _adminApi!.post('/admin/catalog/products/${widget.productId}/sizes',
          body: result);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> size) async {
    final id = size['id']?.toString();
    if (_token == null || id == null) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _SizeForm(
        productType: widget.productType,
        initial: size,
      ),
    );
    if (result == null) return;
    try {
      await _adminApi!.patch('/admin/catalog/sizes/$id', body: result);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _toggle(Map<String, dynamic> size) async {
    final id = size['id']?.toString();
    if (_token == null || id == null) return;
    try {
      await _adminApi!.patch('/admin/catalog/sizes/$id',
          body: {'is_active': size['is_active'] != true});
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPizza = widget.productType == 'PIZZA';
    return Scaffold(
      appBar: AppBar(
          title: Text('${isPizza ? 'Tamanhos' : 'Variações e preços'} · '
              '${widget.productName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _sizes.isEmpty
                        ? [
                            const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                    child: Text('Nenhum tamanho cadastrado.')))
                          ]
                        : _sizes
                            .map((size) => Card(
                                  child: ListTile(
                                    title: Text(size['name']?.toString() ?? ''),
                                    subtitle: Text(isPizza
                                        ? "R\$ ${size['price']} · ${size['slices']} fatias · até ${size['max_flavors']} sabor(es)"
                                        : "R\$ ${size['price']}"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar preço e variação',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _edit(size),
                                        ),
                                        Switch(
                                            value: size['is_active'] == true,
                                            onChanged: (_) => _toggle(size)),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: Text(widget.productType == 'PIZZA' ? 'Tamanho' : 'Variação')),
    );
  }
}

class _SizeForm extends StatefulWidget {
  const _SizeForm({required this.productType, this.initial});

  final String productType;
  final Map<String, dynamic>? initial;

  @override
  State<_SizeForm> createState() => _SizeFormState();
}

class _SizeFormState extends State<_SizeForm> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _price = TextEditingController();
  final _slices = TextEditingController(text: '8');
  final _maxFlavors = TextEditingController(text: '1');
  String? _priceError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _name.text = initial['name']?.toString() ?? '';
    _slug.text = initial['slug']?.toString() ?? '';
    _price.text = initial['price']?.toString() ?? '';
    _slices.text = initial['slices']?.toString() ?? '8';
    _maxFlavors.text = initial['max_flavors']?.toString() ?? '1';
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _price.dispose();
    _slices.dispose();
    _maxFlavors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null
            ? (widget.productType == 'PIZZA' ? 'Novo tamanho' : 'Nova variação')
            : 'Editar preço e variação'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome')),
            TextField(
                controller: _slug,
                decoration: const InputDecoration(labelText: 'Slug')),
            TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  if (_priceError != null) {
                    setState(() => _priceError = null);
                  }
                },
                decoration: InputDecoration(
                    labelText: 'Preço (R\$)', errorText: _priceError)),
            TextField(
                controller: _slices,
                keyboardType: TextInputType.number,
                enabled: widget.productType == 'PIZZA',
                decoration: const InputDecoration(labelText: 'Fatias')),
            TextField(
                controller: _maxFlavors,
                keyboardType: TextInputType.number,
                enabled: widget.productType == 'PIZZA',
                decoration:
                    const InputDecoration(labelText: 'Máximo de sabores')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final normalizedPrice = _price.text.trim().replaceAll(',', '.');
              final parsedPrice = double.tryParse(normalizedPrice);
              if (parsedPrice == null || parsedPrice < 0) {
                setState(() => _priceError = 'Informe um preço válido.');
                return;
              }
              if (_name.text.trim().isEmpty ||
                  _slug.text.trim().isEmpty ||
                  _price.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'slug': _slug.text.trim().toLowerCase(),
                'price': parsedPrice.toStringAsFixed(2),
                'slices': _slices.text.trim(),
                'max_flavors': _maxFlavors.text.trim(),
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      );
}

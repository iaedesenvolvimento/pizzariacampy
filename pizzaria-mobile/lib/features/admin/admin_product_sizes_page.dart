import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_design_system.dart';
import 'admin_api_client.dart';
import 'admin_product_flavors_page.dart';

String _normalizeVariationSlug(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

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
        _error = 'Não foi possível carregar tamanhos e preços.';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível salvar a variação.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível atualizar a variação.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível alterar a disponibilidade.')));
      }
    }
  }

  Future<void> _configureFlavors(Map<String, dynamic> size) async {
    final sizeId = size['id']?.toString();
    if (sizeId == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AdminProductFlavorsPage(
        productId: widget.productId,
        productName: widget.productName,
        sizeId: sizeId,
        sizeName: size['name']?.toString() ?? 'Tamanho',
      ),
    ));
  }

  Future<void> _configureConfigurations(Map<String, dynamic> size) async {
    final sizeId = size['id']?.toString();
    if (sizeId == null || _adminApi == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _PizzaConfigurationsDialog(
        api: _adminApi!,
        productId: widget.productId,
        sizeId: sizeId,
        sizeName: size['name']?.toString() ?? 'Tamanho',
        maxFlavors: int.tryParse(size['max_flavors']?.toString() ?? '') ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPizza = widget.productType == 'PIZZA';
    return AdminScaffold(
      title: '${isPizza ? 'Tamanhos' : 'Variações e preços'} · '
          '${widget.productName}',
      activeDestination: AdminDestinationId.products,
      body: _loading
          ? const AdminLoadingState(label: 'Carregando tamanhos e preços')
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: Icon(isPizza
                              ? Icons.local_pizza_outlined
                              : Icons.sell_outlined),
                          title: Text(isPizza
                              ? 'Cadastre os tamanhos da pizza'
                              : 'Cadastre as variações do produto'),
                          subtitle: Text(isPizza
                              ? 'Cada tamanho precisa ter seu próprio preço.'
                              : 'Exemplo: 1 litro, lata ou unidade, sempre com preço.'),
                        ),
                      ),
                      if (_sizes.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: Text('Nenhuma variação cadastrada.')))
                      else
                        ..._sizes.map((size) => Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(size['name']?.toString() ?? ''),
                                    subtitle: Text(isPizza
                                        ? "${_money(size['price'])} · ${size['slices']} fatias · até ${size['max_flavors']} sabor(es)"
                                        : _money(size['price'])),
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
                                  if (isPizza)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _configureFlavors(size),
                                              icon: const Icon(
                                                  Icons.local_pizza_outlined),
                                              label: const Text(
                                                  'Sabores disponíveis'),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _configureConfigurations(
                                                      size),
                                              icon: const Icon(
                                                  Icons.tune_outlined),
                                              label: const Text(
                                                  'Ofertas de sabores'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: Text(widget.productType == 'PIZZA' ? 'Tamanho' : 'Variação')),
    );
  }

  String _money(dynamic value) {
    final text = value?.toString().replaceAll('.', ',') ?? '0,00';
    return 'R\$ $text';
  }
}

class _PizzaConfigurationsDialog extends StatefulWidget {
  const _PizzaConfigurationsDialog({
    required this.api,
    required this.productId,
    required this.sizeId,
    required this.sizeName,
    required this.maxFlavors,
  });

  final AdminApiClient api;
  final String productId;
  final String sizeId;
  final String sizeName;
  final int maxFlavors;

  @override
  State<_PizzaConfigurationsDialog> createState() =>
      _PizzaConfigurationsDialogState();
}

class _PizzaConfigurationsDialogState
    extends State<_PizzaConfigurationsDialog> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  String get _path =>
      '/admin/catalog/products/${widget.productId}/sizes/${widget.sizeId}/configurations';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await widget.api.get(_path);
      if (response is! List<dynamic>) throw const FormatException();
      if (!mounted) return;
      setState(() {
        _items = response.whereType<Map<String, dynamic>>().toList();
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar as ofertas.';
      });
    }
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _ConfigurationForm(maxFlavors: widget.maxFlavors),
    );
    if (result == null) return;
    try {
      await widget.api.post(_path, body: {
        'flavor_count': int.parse(result['flavor_count']!),
        'display_name': result['display_name'],
        'display_order': int.parse(result['display_order']!),
        'pricing_rule': result['pricing_rule'],
      });
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a oferta.')),
        );
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _ConfigurationForm(
        maxFlavors: widget.maxFlavors,
        initial: item,
      ),
    );
    if (result == null) return;
    try {
      await widget.api.patch('$_path/$id', body: {
        'flavor_count': int.parse(result['flavor_count']!),
        'display_name': result['display_name'],
        'display_order': int.parse(result['display_order']!),
        'pricing_rule': result['pricing_rule'],
      });
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar a oferta.')),
        );
      }
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    try {
      await widget.api
          .patch('$_path/$id', body: {'is_active': item['is_active'] != true});
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar a oferta.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Ofertas · ${widget.sizeName}'),
        content: SizedBox(
          width: 430,
          child: _loading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()))
              : _error != null
                  ? Text(_error!)
                  : _items.isEmpty
                      ? const Text(
                          'Nenhuma oferta cadastrada. Adicione 1 ou 2 sabores.')
                      : ListView(
                          shrinkWrap: true,
                          children: _items
                              .map((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                        item['display_name']?.toString() ?? ''),
                                    subtitle: Text(
                                        '${item['flavor_count']} sabor(es) · ${item['pricing_rule']}'),
                                    leading: Switch(
                                      value: item['is_active'] == true,
                                      onChanged: (_) => _toggle(item),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _edit(item),
                                    ),
                                  ))
                              .toList(),
                        ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
          FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar')),
        ],
      );
}

class _ConfigurationForm extends StatefulWidget {
  const _ConfigurationForm({required this.maxFlavors, this.initial});

  final int maxFlavors;
  final Map<String, dynamic>? initial;

  @override
  State<_ConfigurationForm> createState() => _ConfigurationFormState();
}

class _ConfigurationFormState extends State<_ConfigurationForm> {
  late final TextEditingController _count;
  late final TextEditingController _name;
  late final TextEditingController _order;
  String _pricingRule = 'MAX_FLAVOR_PRICE';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _count = TextEditingController(
        text: initial?['flavor_count']?.toString() ?? '1');
    _name = TextEditingController(
        text: initial?['display_name']?.toString() ?? '1 sabor');
    _order = TextEditingController(
        text: initial?['display_order']?.toString() ?? '0');
    _pricingRule = 'MAX_FLAVOR_PRICE';
  }

  @override
  void dispose() {
    _count.dispose();
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null
            ? 'Nova oferta de sabores'
            : 'Editar oferta'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText:
                      'Quantidade de sabores (até ${widget.maxFlavors})'),
            ),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome exibido')),
            TextField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ordem'),
            ),
            const InputDecorator(
              decoration: InputDecoration(labelText: 'Regra de preço'),
              child: Text('Maior preço dos sabores'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final count = int.tryParse(_count.text.trim());
              final order = int.tryParse(_order.text.trim());
              if (count == null ||
                  count < 1 ||
                  count > widget.maxFlavors ||
                  order == null ||
                  _name.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'flavor_count': count.toString(),
                'display_name': _name.text.trim(),
                'display_order': order.toString(),
                'pricing_rule': _pricingRule,
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      );
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
    _price.text = initial['price']?.toString() ?? '';
    _slices.text = initial['slices']?.toString() ?? '8';
    _maxFlavors.text = initial['max_flavors']?.toString() ?? '1';
  }

  @override
  void dispose() {
    _name.dispose();
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
              if (_name.text.trim().isEmpty || _price.text.trim().isEmpty) {
                return;
              }
              final slug =
                  widget.initial?['slug']?.toString().trim().isNotEmpty == true
                      ? widget.initial!['slug'].toString().trim()
                      : _normalizeVariationSlug(_name.text);
              if (slug.isEmpty) return;
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'slug': slug,
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

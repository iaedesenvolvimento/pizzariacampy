import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_product_sizes_page.dart';

String _normalizeSlug(String value) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  var normalized = value.trim().toLowerCase();
  replacements
      .forEach((from, to) => normalized = normalized.replaceAll(from, to));
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({required this.mode, super.key});

  final AdminCatalogMode mode;

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

enum AdminCatalogMode { categories, products }

class _AdminCatalogPageState extends State<AdminCatalogPage> {
  final _apiClient = ApiClient(config: AppConfig.fromEnvironment());
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _categories = const [];
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  String? _token;
  String? _error;
  bool _loading = true;

  bool get _isCategories => widget.mode == AdminCatalogMode.categories;

  List<Map<String, dynamic>> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    final categoryNames = {
      for (final category in _categories)
        category['id']?.toString(): category['name']?.toString() ?? '',
    };
    final items = _items.where((item) {
      final matchesCategory = _isCategories ||
          _selectedCategoryId == null ||
          item['category_id']?.toString() == _selectedCategoryId;
      final text = [
        item['name']?.toString() ?? '',
        item['slug']?.toString() ?? '',
        categoryNames[item['category_id']?.toString()] ?? '',
      ].join(' ').toLowerCase();
      return matchesCategory && (query.isEmpty || text.contains(query));
    }).toList();
    items.sort((first, second) {
      final firstCategory =
          categoryNames[first['category_id']?.toString()] ?? '';
      final secondCategory =
          categoryNames[second['category_id']?.toString()] ?? '';
      final categoryComparison =
          firstCategory.toLowerCase().compareTo(secondCategory.toLowerCase());
      if (categoryComparison != 0) return categoryComparison;
      return (first['name']?.toString() ?? '')
          .toLowerCase()
          .compareTo((second['name']?.toString() ?? '').toLowerCase());
    });
    return items;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final storage = await AppStorage.create();
    if (!mounted) return;
    _token = storage.accessToken;
    _adminApi = AdminApiClient(_apiClient, storage);
    try {
      final categories = await _adminApi!.get('/admin/catalog/categories');
      final products = await _adminApi!.get('/admin/catalog/products');
      if (categories is! List<dynamic> || products is! List<dynamic>) {
        throw const FormatException('Catálogo inválido.');
      }
      if (!mounted) return;
      setState(() {
        _categories = categories.whereType<Map<String, dynamic>>().toList();
        _items = (_isCategories ? categories : products)
            .whereType<Map<String, dynamic>>()
            .toList();
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
      builder: (_) => _CatalogForm(
          isCategory: _isCategories,
          categories: _categories,
          onUploadImage: _uploadImage),
    );
    if (result == null) return;
    try {
      final path = _isCategories
          ? '/admin/catalog/categories'
          : '/admin/catalog/products';
      final body = _isCategories
          ? {
              'name': result['name'],
              'slug': result['slug'],
              'description': result['description'],
              'sort_order': 0
            }
          : {
              'category_id': result['category_id'],
              'name': result['name'],
              'slug': result['slug'],
              'description': result['description'],
              'product_type': result['product_type'],
              'image_url': result['image_url'],
              'sort_order': 0,
            };
      final created = await _adminApi!.post(path, body: body);
      await _load();
      if (!mounted || _isCategories || created is! Map<String, dynamic>) {
        return;
      }
      final productId = created['id']?.toString();
      if (productId == null || productId.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Produto criado. Cadastre agora um tamanho e preço.')));
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AdminProductSizesPage(
                productId: productId,
                productName: created['name']?.toString() ?? 'Produto',
              )));
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    if (_token == null) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _CatalogForm(
        isCategory: _isCategories,
        categories: _categories,
        initial: item,
        onUploadImage: _uploadImage,
      ),
    );
    if (result == null) return;
    final id = item['id']?.toString();
    if (id == null) return;
    final path = _isCategories
        ? '/admin/catalog/categories/$id'
        : '/admin/catalog/products/$id';
    final body = _isCategories
        ? {
            'name': result['name'],
            'slug': result['slug'],
            'description': result['description'],
          }
        : {
            'category_id': result['category_id'],
            'name': result['name'],
            'slug': result['slug'],
            'description': result['description'],
            'product_type': result['product_type'],
            'image_url': result['image_url'],
          };
    try {
      await _adminApi!.patch(path, body: body);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<String?> _uploadImage(String filePath) async {
    final response = await _adminApi!.uploadFile('/admin/images/upload',
        filePath: filePath, fieldName: 'file');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta inválida do upload.');
    }
    return response['image_url']?.toString();
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    if (_token == null) return;
    final id = item['id']?.toString();
    if (id == null) return;
    final path = _isCategories
        ? '/admin/catalog/categories/$id'
        : '/admin/catalog/products/$id';
    try {
      await _adminApi!
          .patch(path, body: {'is_active': item['is_active'] != true});
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (_token == null) return;
    final name = item['name']?.toString() ?? 'este registro';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text('Deseja excluir "$name" definitivamente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = item['id']?.toString();
    if (id == null) return;
    final path = _isCategories
        ? '/admin/catalog/categories/$id'
        : '/admin/catalog/products/$id';
    try {
      await _adminApi!.delete(path);
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
    final title = _isCategories ? 'Categorias' : 'Produtos';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: _isCategories
                                ? 'Buscar categoria'
                                : 'Buscar produto',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar busca',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (!_isCategories)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            value: _categories.any((category) =>
                                    category['id']?.toString() ==
                                    _selectedCategoryId)
                                ? _selectedCategoryId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por categoria',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todas as categorias'),
                              ),
                              ..._categories.map(
                                (category) => DropdownMenuItem<String>(
                                  value: category['id']?.toString(),
                                  child:
                                      Text(category['name']?.toString() ?? ''),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedCategoryId = value),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_visibleItems.length} ${_isCategories ? 'categoria(s)' : 'produto(s)'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (_visibleItems.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: Text('Nenhum registro cadastrado.'))),
                      ..._visibleItems.map(
                        (item) => Card(
                          child: ListTile(
                            title: Text(item['name']?.toString() ?? ''),
                            subtitle: Text(_isCategories
                                ? 'Slug: ${item['slug'] ?? ''}'
                                : '${_categories.firstWhere(
                                      (category) =>
                                          category['id']?.toString() ==
                                          item['category_id']?.toString(),
                                      orElse: () => const {},
                                    )['name'] ?? 'Sem categoria'} · ${item['product_type'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Tamanhos',
                                  icon: const Icon(Icons.straighten_outlined),
                                  onPressed: _isCategories
                                      ? null
                                      : () => Navigator.of(context)
                                              .push(MaterialPageRoute<void>(
                                            builder: (_) =>
                                                AdminProductSizesPage(
                                              productId: item['id'].toString(),
                                              productName:
                                                  item['name'].toString(),
                                            ),
                                          )),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(item),
                                ),
                                IconButton(
                                  tooltip: 'Excluir',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(item),
                                ),
                                Switch(
                                  value: item['is_active'] == true,
                                  onChanged: (_) => _toggle(item),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: Text(_isCategories ? 'Nova categoria' : 'Novo produto')),
    );
  }
}

class _CatalogForm extends StatefulWidget {
  const _CatalogForm({
    required this.isCategory,
    required this.categories,
    required this.onUploadImage,
    this.initial,
  });

  final bool isCategory;
  final List<Map<String, dynamic>> categories;
  final Future<String?> Function(String filePath) onUploadImage;
  final Map<String, dynamic>? initial;

  @override
  State<_CatalogForm> createState() => _CatalogFormState();
}

class _CatalogFormState extends State<_CatalogForm> {
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  String? _categoryId;
  String _type = 'PIZZA';
  String? _validationError;
  bool _slugManuallyEdited = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?['name']?.toString() ?? '');
    _slug = TextEditingController(text: initial?['slug']?.toString() ?? '');
    _description =
        TextEditingController(text: initial?['description']?.toString() ?? '');
    _imageUrl =
        TextEditingController(text: initial?['image_url']?.toString() ?? '');
    _categoryId = initial?['category_id']?.toString();
    final initialType = initial?['product_type']?.toString();
    _type = initialType == 'DRINK' ? 'BEVERAGE' : initialType ?? 'PIZZA';
    _slugManuallyEdited = initial != null && _slug.text.isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final imageUrl = await widget.onUploadImage(path);
      if (imageUrl == null || imageUrl.isEmpty) {
        throw const FormatException('O Cloudinary não retornou uma URL.');
      }
      if (mounted) {
        setState(() => _imageUrl.text = imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem hospedada com sucesso.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isCategory
          ? (widget.initial == null ? 'Nova categoria' : 'Editar categoria')
          : (widget.initial == null ? 'Novo produto' : 'Editar produto')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_validationError != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _validationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome *'),
            onChanged: (value) {
              if (!_slugManuallyEdited) {
                _slug.text = _normalizeSlug(value);
              }
            },
          ),
          TextField(
              controller: _slug,
              decoration: const InputDecoration(
                  labelText: 'Slug *',
                  helperText:
                      'Preenchido automaticamente. Use letras, números e hífen.'),
              onChanged: (_) => _slugManuallyEdited = true),
          TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descrição')),
          if (!widget.isCategory) ...[
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: widget.categories
                  .map((category) => DropdownMenuItem(
                      value: category['id']?.toString(),
                      child: Text(category['name']?.toString() ?? '')))
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'PIZZA', child: Text('Pizza')),
                DropdownMenuItem(value: 'BEVERAGE', child: Text('Bebida')),
                DropdownMenuItem(value: 'DESSERT', child: Text('Sobremesa')),
                DropdownMenuItem(value: 'COMBO', child: Text('Combo'))
              ],
              onChanged: (value) => setState(() => _type = value ?? 'PIZZA'),
            ),
            TextField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                    labelText: 'URL da imagem (opcional)',
                    hintText: 'https://.../produto.webp',
                    helperText: 'Use o botão para hospedar no Cloudinary.',
                    suffixIcon: IconButton(
                      icon: _uploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      onPressed: _uploadingImage ? null : _pickImage,
                    )))
          ],
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty ||
                _slug.text.trim().isEmpty ||
                (!widget.isCategory && _categoryId == null)) {
              setState(
                  () => _validationError = 'Preencha os campos obrigatórios.');
              return;
            }
            final slug = _normalizeSlug(_slug.text);
            if (slug.isEmpty) {
              setState(() => _validationError = 'Informe um slug válido.');
              return;
            }
            Navigator.of(context).pop(<String, String>{
              'name': _name.text.trim(),
              'slug': slug,
              'description': _description.text.trim(),
              if (_categoryId != null) 'category_id': _categoryId!,
              'product_type': _type,
              if (!widget.isCategory) 'image_url': _imageUrl.text.trim(),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

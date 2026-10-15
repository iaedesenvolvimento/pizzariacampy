import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/storage/app_storage.dart';
import 'data/menu_models.dart';
import 'data/menu_service.dart';

enum MenuStatus { initial, loading, success, empty, error }

class MenuController extends ChangeNotifier {
  MenuController(this._service);

  final MenuService _service;
  Future<AppStorage>? _storageFuture;
  MenuStatus status = MenuStatus.initial;
  List<MenuCategory> categories = const [];
  List<MenuProduct> products = const [];
  List<MenuProduct> _loadedProducts = const [];
  String? selectedCategoryId;
  String? errorMessage;

  Future<void> load() async {
    final storage = await (_storageFuture ??= AppStorage.create());
    if (_loadedProducts.isEmpty) {
      final cached = storage.readMenuCache();
      if (cached != null) _applyCache(cached);
    }
    final hasVisibleData = _loadedProducts.isNotEmpty;
    if (!hasVisibleData) status = MenuStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchCategories(),
        _service.fetchProducts(),
      ]);
      categories = results[0] as List<MenuCategory>;
      _loadedProducts = results[1] as List<MenuProduct>;
      products = _loadedProducts;
      await storage.saveMenuCache(
        categories: categories.map((category) => category.toJson()).toList(),
        products: _loadedProducts.map((product) => product.toJson()).toList(),
      );
      status = products.isEmpty ? MenuStatus.empty : MenuStatus.success;
    } on AppException catch (error) {
      status = MenuStatus.error;
      errorMessage = error.message;
    } catch (_) {
      status = MenuStatus.error;
      errorMessage = 'Não foi possível carregar o cardápio.';
    }
    notifyListeners();
  }

  void _applyCache(Map<String, dynamic> cache) {
    final cachedCategories = cache['categories'];
    final cachedProducts = cache['products'];
    if (cachedCategories is! List || cachedProducts is! List) return;
    categories = cachedCategories
        .whereType<Map<String, dynamic>>()
        .map(MenuCategory.fromJson)
        .toList();
    _loadedProducts = cachedProducts
        .whereType<Map<String, dynamic>>()
        .map(MenuProduct.fromJson)
        .toList();
    products = _loadedProducts;
    status = products.isEmpty ? MenuStatus.empty : MenuStatus.success;
  }

  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
    status = MenuStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      _loadedProducts = await _service.fetchProducts(categoryId: categoryId);
      products = _loadedProducts;
      status = products.isEmpty ? MenuStatus.empty : MenuStatus.success;
    } catch (_) {
      status = MenuStatus.error;
      errorMessage = 'Não foi possível carregar esta categoria.';
    }
    notifyListeners();
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    products = _loadedProducts.where((product) {
      final searchableText = [
        product.name,
        product.description ?? '',
      ].join(' ').toLowerCase();
      return searchableText.contains(normalizedQuery);
    }).toList();
    status = products.isEmpty ? MenuStatus.empty : MenuStatus.success;
    notifyListeners();
  }
}

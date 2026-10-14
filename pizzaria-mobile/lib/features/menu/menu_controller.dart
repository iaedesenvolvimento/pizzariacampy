import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import 'data/menu_models.dart';
import 'data/menu_service.dart';

enum MenuStatus { initial, loading, success, empty, error }

class MenuController extends ChangeNotifier {
  MenuController(this._service);

  final MenuService _service;
  MenuStatus status = MenuStatus.initial;
  List<MenuCategory> categories = const [];
  List<MenuProduct> products = const [];
  String? selectedCategoryId;
  String? errorMessage;

  Future<void> load() async {
    status = MenuStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchCategories(),
        _service.fetchProducts(),
      ]);
      categories = results[0] as List<MenuCategory>;
      products = results[1] as List<MenuProduct>;
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

  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
    status = MenuStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      products = await _service.fetchProducts(categoryId: categoryId);
      status = products.isEmpty ? MenuStatus.empty : MenuStatus.success;
    } catch (_) {
      status = MenuStatus.error;
      errorMessage = 'Não foi possível carregar esta categoria.';
    }
    notifyListeners();
  }

  Future<void> search(String query) async {
    status = MenuStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      products = await _service.fetchProducts(search: query);
      status = products.isEmpty ? MenuStatus.empty : MenuStatus.success;
    } catch (_) {
      status = MenuStatus.error;
      errorMessage = 'Não foi possível realizar a busca.';
    }
    notifyListeners();
  }
}

import '../../../core/network/api_client.dart';
import 'menu_models.dart';

class MenuService {
  MenuService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MenuCategory>> fetchCategories() async {
    final response = await _apiClient.get('/categories');
    return _decodeList(response).map(MenuCategory.fromJson).toList();
  }

  Future<List<MenuProduct>> fetchProducts({String? categoryId, String? search}) async {
    final query = <String, String>{
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final path = Uri(path: '/products', queryParameters: query).toString();
    final response = await _apiClient.get(path);
    return _decodeList(response).map(MenuProduct.fromJson).toList();
  }

  Future<MenuProductOptions> fetchOptions(String productId,
      {bool halfHalf = false}) async {
    final suffix = halfHalf ? '?flavor_mode=HALF_HALF' : '';
    final response = await _apiClient.get('/products/$productId/options$suffix');
    return MenuProductOptions.fromJson(response as Map<String, dynamic>);
  }

  List<Map<String, dynamic>> _decodeList(dynamic response) {
    if (response is! List) throw const FormatException('Resposta de cardápio inválida.');
    return response.whereType<Map<String, dynamic>>().toList();
  }
}

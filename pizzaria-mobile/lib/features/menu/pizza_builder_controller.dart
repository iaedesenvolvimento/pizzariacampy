import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import 'data/menu_models.dart';

class PizzaBuilderController extends ChangeNotifier {
  PizzaBuilderController(
    this._apiClient,
    this.options,
    this.accessToken, {
    this.refreshAccessToken,
  });

  final ApiClient _apiClient;
  final MenuProductOptions options;
  final String? accessToken;
  final Future<String?> Function()? refreshAccessToken;
  String? selectedSizeId;
  String? selectedEdgeId;
  final Set<String> selectedFlavorIds = {};
  final Map<String, int> selectedExtras = {};
  int quantity = 1;
  double? quoteTotal;
  bool isQuoting = false;
  String? errorMessage;
  int _quoteVersion = 0;

  MenuProductSize? get selectedSize => _findSize(selectedSizeId);
  List<MenuProductSize> get sizesByPrice => [...options.sizes]
    ..sort((first, second) => second.price.compareTo(first.price));
  bool get canCustomize => selectedSize != null && selectedFlavorIds.isNotEmpty;

  void initialize() {
    selectedSizeId ??= sizesByPrice.firstOrNull?.id;
  }

  void selectSize(String sizeId) {
    final size = _findSize(sizeId);
    if (size == null) return;
    selectedSizeId = sizeId;
    if (selectedFlavorIds.length > size.maxFlavors) {
      selectedFlavorIds
          .removeWhere((_) => selectedFlavorIds.length > size.maxFlavors);
    }
    errorMessage = null;
    notifyListeners();
    refreshQuote();
  }

  void toggleFlavor(String flavorId) {
    final size = selectedSize;
    if (selectedFlavorIds.contains(flavorId)) {
      selectedFlavorIds.remove(flavorId);
      errorMessage = null;
    } else if (size != null && selectedFlavorIds.length < size.maxFlavors) {
      selectedFlavorIds.add(flavorId);
      errorMessage = null;
    } else {
      errorMessage =
          'Este tamanho permite até ${size?.maxFlavors ?? 0} sabores.';
    }
    notifyListeners();
    refreshQuote();
  }

  void selectEdge(String? edgeId) {
    selectedEdgeId = edgeId;
    notifyListeners();
    refreshQuote();
  }

  void toggleExtra(String extraId) {
    if (selectedExtras.containsKey(extraId)) {
      selectedExtras.remove(extraId);
    } else {
      selectedExtras[extraId] = 1;
    }
    notifyListeners();
    refreshQuote();
  }

  void setQuantity(int value) {
    if (value < 1) return;
    quantity = value;
    notifyListeners();
    refreshQuote();
  }

  Future<void> refreshQuote() async {
    if (!canCustomize) {
      quoteTotal = null;
      return;
    }
    final requestVersion = ++_quoteVersion;
    isQuoting = true;
    notifyListeners();
    var token = accessToken;
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await _apiClient.post(
            '/pricing/quote',
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
            body: {
              'items': [
                {
                  'product_id': options.product.id,
                  'product_size_id': selectedSizeId,
                  'flavor_ids': selectedFlavorIds.toList(),
                  'edge_id': selectedEdgeId,
                  'extras': selectedExtras.entries
                      .map((entry) =>
                          {'extra_id': entry.key, 'quantity': entry.value})
                      .toList(),
                  'quantity': quantity,
                },
              ],
              'fulfillment_type': 'PICKUP',
            },
          );
          if (requestVersion == _quoteVersion && response is Map<String, dynamic>) {
            quoteTotal = double.tryParse(response['total_amount'].toString());
            errorMessage = null;
          }
          break;
        } on ApiException catch (error) {
          if (error.statusCode != 401 || attempt > 0 || refreshAccessToken == null) {
            rethrow;
          }
          token = await refreshAccessToken!();
          if (token == null) rethrow;
        }
      }
    } on AppException catch (error) {
      if (requestVersion == _quoteVersion) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (requestVersion == _quoteVersion) {
        errorMessage = 'Não foi possível atualizar o preço.';
      }
    } finally {
      if (requestVersion == _quoteVersion) {
        isQuoting = false;
        notifyListeners();
      }
    }
  }

  MenuProductSize? _findSize(String? sizeId) {
    if (sizeId == null) return null;
    for (final size in options.sizes) {
      if (size.id == sizeId) return size;
    }
    return null;
  }
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

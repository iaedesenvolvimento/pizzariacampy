import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import 'data/menu_models.dart';

class PizzaBuilderController extends ChangeNotifier {
  PizzaBuilderController(
    this._apiClient,
    this.options,
    this.accessToken, {
    this.maxFlavorsOverride,
    this.refreshAccessToken,
  });

  final ApiClient _apiClient;
  final MenuProductOptions options;
  final String? accessToken;
  final int? maxFlavorsOverride;
  final Future<String?> Function()? refreshAccessToken;
  String? selectedSizeId;
  String? selectedConfigurationId;
  String? selectedEdgeId;
  String? selectedDoughName;
  final Set<String> selectedFlavorIds = {};
  final Map<String, int> selectedExtras = {};
  int quantity = 1;
  double? quoteTotal;
  bool isQuoting = false;
  String? errorMessage;
  int _quoteVersion = 0;

  MenuProductSize? get selectedSize => _findSize(selectedSizeId);
  MenuPizzaConfiguration? get selectedConfiguration =>
      _findConfiguration(selectedConfigurationId);
  int get flavorLimit {
    final sizeLimit = selectedSize?.maxFlavors ?? 0;
    final requestedLimit =
        selectedConfiguration?.flavorCount ?? maxFlavorsOverride ?? sizeLimit;
    return requestedLimit < sizeLimit ? requestedLimit : sizeLimit;
  }

  List<MenuProductSize> get sizesByPrice => [...options.sizes]
    ..sort((first, second) => second.price.compareTo(first.price));
  bool get canCustomize =>
      selectedSize != null &&
      selectedDoughName != null &&
      selectedFlavorIds.isNotEmpty;

  void initialize() {
    selectedSizeId ??= sizesByPrice.firstOrNull?.id;
    _selectDefaultConfiguration();
  }

  void selectSize(String sizeId) {
    final size = _findSize(sizeId);
    if (size == null) return;
    selectedSizeId = sizeId;
    _selectDefaultConfiguration();
    if (selectedFlavorIds.length > flavorLimit) {
      selectedFlavorIds
          .removeWhere((_) => selectedFlavorIds.length > flavorLimit);
    }
    errorMessage = null;
    notifyListeners();
    refreshQuote();
  }

  void selectConfiguration(String configurationId) {
    final configuration = _findConfiguration(configurationId);
    if (configuration == null ||
        configuration.productSizeId != selectedSizeId) {
      return;
    }
    selectedConfigurationId = configurationId;
    selectedFlavorIds.clear();
    errorMessage = null;
    notifyListeners();
    refreshQuote();
  }

  void _selectDefaultConfiguration() {
    final sizeId = selectedSizeId;
    if (sizeId == null) return;
    final available = options.configurations
        .where((configuration) =>
            configuration.productSizeId == sizeId && configuration.isActive)
        .toList()
      ..sort(
          (first, second) => first.displayOrder.compareTo(second.displayOrder));
    final requested = maxFlavorsOverride;
    selectedConfigurationId = available
            .where((configuration) =>
                requested == null || configuration.flavorCount == requested)
            .map((configuration) => configuration.id)
            .firstOrNull ??
        available.firstOrNull?.id;
  }

  void toggleFlavor(String flavorId) {
    final size = selectedSize;
    if (selectedFlavorIds.contains(flavorId)) {
      selectedFlavorIds.remove(flavorId);
      errorMessage = null;
    } else if (size != null && selectedFlavorIds.length < flavorLimit) {
      selectedFlavorIds.add(flavorId);
      errorMessage = null;
    } else {
      errorMessage = 'Esta modalidade permite até $flavorLimit sabores.';
    }
    notifyListeners();
    refreshQuote();
  }

  void selectEdge(String? edgeId) {
    selectedEdgeId = edgeId;
    notifyListeners();
    refreshQuote();
  }

  void selectDough(String doughName) {
    selectedDoughName = doughName;
    notifyListeners();
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
                  'pizza_configuration_id': selectedConfigurationId,
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
          if (requestVersion == _quoteVersion &&
              response is Map<String, dynamic>) {
            quoteTotal = double.tryParse(response['total_amount'].toString());
            errorMessage = null;
          }
          break;
        } on ApiException catch (error) {
          if (error.statusCode != 401 ||
              attempt > 0 ||
              refreshAccessToken == null) {
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

  MenuPizzaConfiguration? _findConfiguration(String? configurationId) {
    if (configurationId == null) return null;
    for (final configuration in options.configurations) {
      if (configuration.id == configurationId) return configuration;
    }
    return null;
  }
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

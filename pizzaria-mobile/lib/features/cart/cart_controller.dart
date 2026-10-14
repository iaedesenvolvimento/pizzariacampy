import 'package:flutter/foundation.dart';

import '../../core/storage/app_storage.dart';
import 'cart_models.dart';

class CartController extends ChangeNotifier {
  CartController(this._storage);

  final AppStorage _storage;
  List<CartItem> items = const [];
  bool isLoading = true;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);
  double get subtotal => items.fold(0, (total, item) => total + item.totalPrice);
  bool get isEmpty => items.isEmpty;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    items = _storage.readCart().map(CartItem.fromJson).toList();
    isLoading = false;
    notifyListeners();
  }

  Future<void> add(CartItem item) async {
    items = [...items, item];
    await _persist();
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) return remove(itemId);
    items = [for (final item in items) item.id == itemId ? item.copyWith(quantity: quantity) : item];
    await _persist();
  }

  Future<void> remove(String itemId) async {
    items = items.where((item) => item.id != itemId).toList();
    await _persist();
  }

  Future<void> clear() async {
    items = const [];
    await _persist();
  }

  Future<void> _persist() async {
    await _storage.saveCart(items.map((item) => item.toJson()).toList());
    notifyListeners();
  }
}

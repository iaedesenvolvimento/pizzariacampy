import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaria_mobile/features/cart/cart_models.dart';

void main() {
  test('calculates cart item total from quantity', () {
    const item = CartItem(
      id: 'item-1',
      productId: 'product-1',
      productName: 'Pizza Campy',
      sizeId: 'size-1',
      sizeName: 'Grande',
      flavorIds: [],
      flavorNames: [],
      edgeId: null,
      edgeName: null,
      extras: [],
      quantity: 3,
      unitPrice: 42.5,
    );

    expect(item.totalPrice, 127.5);
  });

  test('serializes and restores cart item', () {
    const item = CartItem(
      id: 'item-1',
      productId: 'product-1',
      productName: 'Pizza Campy',
      sizeId: 'size-1',
      sizeName: 'Grande',
      flavorIds: ['flavor-1'],
      flavorNames: ['Calabresa'],
      edgeId: null,
      edgeName: null,
      extras: [],
      quantity: 1,
      unitPrice: 42.5,
    );

    final restored = CartItem.fromJson(item.toJson());
    expect(restored.productName, item.productName);
    expect(restored.flavorNames, item.flavorNames);
    expect(restored.unitPrice, item.unitPrice);
  });
}

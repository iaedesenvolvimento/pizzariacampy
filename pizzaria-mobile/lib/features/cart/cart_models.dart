class CartExtra {
  const CartExtra({required this.id, required this.name, required this.price});

  factory CartExtra.fromJson(Map<String, dynamic> json) {
    return CartExtra(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      price: _number(json['price']),
    );
  }

  final String id;
  final String name;
  final double price;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sizeId,
    required this.sizeName,
    required this.flavorIds,
    required this.flavorNames,
    required this.edgeId,
    required this.edgeName,
    required this.extras,
    required this.quantity,
    required this.unitPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      productName: json['product_name'] as String? ?? '',
      sizeId: json['size_id'].toString(),
      sizeName: json['size_name'] as String? ?? '',
      flavorIds: _strings(json['flavor_ids']),
      flavorNames: _strings(json['flavor_names']),
      edgeId: json['edge_id'] as String?,
      edgeName: json['edge_name'] as String?,
      extras: _maps(json['extras']).map(CartExtra.fromJson).toList(),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: _number(json['unit_price']),
    );
  }

  final String id;
  final String productId;
  final String productName;
  final String sizeId;
  final String sizeName;
  final List<String> flavorIds;
  final List<String> flavorNames;
  final String? edgeId;
  final String? edgeName;
  final List<CartExtra> extras;
  final int quantity;
  final double unitPrice;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        productName: productName,
        sizeId: sizeId,
        sizeName: sizeName,
        flavorIds: flavorIds,
        flavorNames: flavorNames,
        edgeId: edgeId,
        edgeName: edgeName,
        extras: extras,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'size_id': sizeId,
        'size_name': sizeName,
        'flavor_ids': flavorIds,
        'flavor_names': flavorNames,
        'edge_id': edgeId,
        'edge_name': edgeName,
        'extras': extras.map((extra) => extra.toJson()).toList(),
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

double _number(dynamic value) => double.tryParse(value.toString()) ?? 0;

List<String> _strings(dynamic value) => value is List ? value.map((item) => item.toString()).toList() : const [];

List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

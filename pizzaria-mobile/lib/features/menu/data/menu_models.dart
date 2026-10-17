class MenuCategory {
  const MenuCategory(
      {required this.id, required this.name, required this.slug});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String slug;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

bool isPizzaProductType(String type) => type.trim().toUpperCase() == 'PIZZA';

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.type,
    required this.imageUrl,
    required this.isActive,
  });

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    return MenuProduct(
      id: json['id'].toString(),
      categoryId: json['category_id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: json['product_type'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final String type;
  final String? imageUrl;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'product_type': type,
        'image_url': imageUrl,
        'is_active': isActive,
      };
}

class MenuProductSize {
  const MenuProductSize({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.slices,
    required this.maxFlavors,
  });

  factory MenuProductSize.fromJson(Map<String, dynamic> json) {
    return MenuProductSize(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      name: json['name'] as String? ?? '',
      price: json['price'] == null ? null : _decimal(json['price']),
      slices: json['slices'] as int? ?? 8,
      maxFlavors: json['max_flavors'] as int? ?? 1,
    );
  }

  final String id;
  final String productId;
  final String name;
  final double? price;
  final int slices;
  final int maxFlavors;
}

class MenuPizzaConfiguration {
  const MenuPizzaConfiguration({
    required this.id,
    required this.productSizeId,
    required this.flavorCount,
    required this.displayName,
    required this.displayOrder,
    required this.pricingRule,
    required this.isActive,
  });

  factory MenuPizzaConfiguration.fromJson(Map<String, dynamic> json) {
    return MenuPizzaConfiguration(
      id: json['id'].toString(),
      productSizeId: json['product_size_id'].toString(),
      flavorCount: json['flavor_count'] as int? ?? 1,
      displayName: json['display_name'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      pricingRule: json['pricing_rule'] as String? ?? 'MAX_FLAVOR_PRICE',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String productSizeId;
  final int flavorCount;
  final String displayName;
  final int displayOrder;
  final String pricingRule;
  final bool isActive;
}

class MenuFlavor {
  const MenuFlavor(
      {required this.id, required this.name, required this.description});

  factory MenuFlavor.fromJson(Map<String, dynamic> json) {
    return MenuFlavor(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  final String id;
  final String name;
  final String? description;
}

class MenuPricedOption {
  const MenuPricedOption(
      {required this.id, required this.name, required this.price});

  factory MenuPricedOption.fromJson(Map<String, dynamic> json) {
    return MenuPricedOption(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      price: _decimal(json['price']),
    );
  }

  final String id;
  final String name;
  final double price;
}

class MenuProductOptions {
  const MenuProductOptions({
    required this.product,
    required this.sizes,
    required this.configurations,
    required this.flavors,
    required this.edges,
    required this.extras,
  });

  factory MenuProductOptions.fromJson(Map<String, dynamic> json) {
    return MenuProductOptions(
      product: MenuProduct.fromJson(json['product'] as Map<String, dynamic>),
      sizes: _list(json['sizes'], MenuProductSize.fromJson),
      configurations:
          _list(json['configurations'], MenuPizzaConfiguration.fromJson),
      flavors: _list(json['flavors'], MenuFlavor.fromJson),
      edges: _list(json['edges'], MenuPricedOption.fromJson),
      extras: _list(json['extras'], MenuPricedOption.fromJson),
    );
  }

  final MenuProduct product;
  final List<MenuProductSize> sizes;
  final List<MenuPizzaConfiguration> configurations;
  final List<MenuFlavor> flavors;
  final List<MenuPricedOption> edges;
  final List<MenuPricedOption> extras;
}

double _decimal(dynamic value) => double.tryParse(value.toString()) ?? 0;

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().map(parser).toList();
}

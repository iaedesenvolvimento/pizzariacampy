import 'package:flutter/material.dart';

import 'cart_controller.dart';
import 'cart_models.dart';
import '../checkout/checkout_pages.dart';
import '../menu/data/menu_models.dart';
import '../menu/data/menu_service.dart';
import '../menu/presentation/menu_pages.dart';

class CartPage extends StatelessWidget {
  const CartPage(
      {required this.controller,
      required this.accessToken,
      required this.refreshAccessToken,
      required this.menuService,
      required this.isStoreOpen,
      this.storeStatusMessage,
      super.key});

  final CartController controller;
  final String? accessToken;
  final Future<String?> Function() refreshAccessToken;
  final MenuService menuService;
  final bool isStoreOpen;
  final String? storeStatusMessage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Carrinho'),
            actions: [
              if (!controller.isEmpty)
                IconButton(
                  tooltip: 'Limpar carrinho',
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.isEmpty
                  ? _EmptyCart(onBrowse: () => Navigator.of(context).pop())
                  : _CartContents(
                      controller: controller,
                      accessToken: accessToken,
                      refreshAccessToken: refreshAccessToken,
                      menuService: menuService,
                      isStoreOpen: isStoreOpen,
                      storeStatusMessage: storeStatusMessage,
                    ),
          bottomNavigationBar: controller.isEmpty
              ? null
              : _CartSummary(
                  controller: controller,
                  accessToken: accessToken,
                  refreshAccessToken: refreshAccessToken,
                ),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar carrinho?'),
        content: const Text('Todos os itens serão removidos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Limpar')),
        ],
      ),
    );
    if (shouldClear == true) await controller.clear();
  }
}

class _CartContents extends StatelessWidget {
  const _CartContents({
    required this.controller,
    required this.accessToken,
    required this.refreshAccessToken,
    required this.menuService,
    required this.isStoreOpen,
    this.storeStatusMessage,
  });

  final CartController controller;
  final String? accessToken;
  final Future<String?> Function() refreshAccessToken;
  final MenuService menuService;
  final bool isStoreOpen;
  final String? storeStatusMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...controller.items.expand((item) => [
              _CartItemTile(controller: controller, item: item),
              const SizedBox(height: 12),
            ]),
        _CartSuggestions(
          cartController: controller,
          accessToken: accessToken,
          refreshAccessToken: refreshAccessToken,
          menuService: menuService,
          isStoreOpen: isStoreOpen,
          storeStatusMessage: storeStatusMessage,
        ),
      ],
    );
  }
}

class _CartSuggestions extends StatefulWidget {
  const _CartSuggestions({
    required this.cartController,
    required this.accessToken,
    required this.refreshAccessToken,
    required this.menuService,
    required this.isStoreOpen,
    this.storeStatusMessage,
  });

  final String? accessToken;
  final CartController cartController;
  final Future<String?> Function() refreshAccessToken;
  final MenuService menuService;
  final bool isStoreOpen;
  final String? storeStatusMessage;

  @override
  State<_CartSuggestions> createState() => _CartSuggestionsState();
}

class _CartSuggestionsState extends State<_CartSuggestions> {
  late final Future<List<MenuProduct>> _products;

  @override
  void initState() {
    super.initState();
    _products = _loadSuggestions();
  }

  Future<List<MenuProduct>> _loadSuggestions() async {
    try {
      final categories = await widget.menuService.fetchCategories();
      final products = await widget.menuService.fetchProducts();
      final categoryNames = {
        for (final category in categories)
          category.id: '${category.name} ${category.slug}'.toLowerCase(),
      };
      final suggestions = products.where((product) {
        final category = categoryNames[product.categoryId] ?? '';
        final searchable =
            '${product.name} ${product.description ?? ''} $category'
                .toLowerCase();
        return !isPizzaProductType(product.type) &&
            (searchable.contains('bebida') ||
                searchable.contains('doce') ||
                searchable.contains('sobremesa') ||
                searchable.contains('esfiha') ||
                searchable.contains('combo'));
      }).toList();
      return suggestions.take(8).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openProduct(MenuProduct product) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductDetailsPage(
          product: product,
          cartController: widget.cartController,
          accessToken: widget.accessToken,
          isStoreOpen: widget.isStoreOpen,
          storeStatusMessage: widget.storeStatusMessage,
          refreshAccessToken: widget.refreshAccessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuProduct>>(
      future: _products,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <MenuProduct>[];
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Que tal completar seu pedido?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Bebidas, doces e outros itens para acompanhar.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 156,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openProduct(product),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_productIcon(product),
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28),
                              const Spacer(),
                              Text(product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text('Ver opções →',
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

IconData _productIcon(MenuProduct product) {
  final text = '${product.name} ${product.description ?? ''}'.toLowerCase();
  if (text.contains('bebida') ||
      text.contains('suco') ||
      text.contains('refrigerante')) {
    return Icons.local_drink_outlined;
  }
  if (text.contains('doce') || text.contains('sobremesa')) {
    return Icons.icecream_outlined;
  }
  return Icons.restaurant_outlined;
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.controller, required this.item});

  final CartController controller;
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final flavorText = item.flavorNames.join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text(item.productName,
                        style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: () => controller.remove(item.id),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(item.sizeName),
            if (item.doughName != null) Text('Massa: ${item.doughName}'),
            if (flavorText.isNotEmpty) Text(flavorText),
            if (item.edgeName != null) Text('Borda: ${item.edgeName}'),
            if (item.extras.isNotEmpty)
              Text(
                  'Adicionais: ${item.extras.map((extra) => extra.name).join(', ')}'),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      controller.updateQuantity(item.id, item.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: () =>
                      controller.updateQuantity(item.id, item.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(_formatPrice(item.totalPrice),
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.controller,
    required this.accessToken,
    required this.refreshAccessToken,
  });

  final CartController controller;
  final String? accessToken;
  final Future<String?> Function() refreshAccessToken;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Subtotal'),
            Text(_formatPrice(controller.subtotal),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CheckoutPage(
                    cartController: controller,
                    accessToken: accessToken,
                    refreshAccessToken: refreshAccessToken,
                  ),
                ),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64),
            const SizedBox(height: 16),
            Text('Seu carrinho está vazio.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Escolha um produto no cardápio para começar.'),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: onBrowse, child: const Text('Voltar ao cardápio')),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(double price) =>
    'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../admin/admin_dashboard_page.dart';
import '../../cart/cart_controller.dart';
import '../../cart/cart_models.dart';
import '../../cart/cart_pages.dart';
import '../../addresses/customer_addresses_page.dart';
import '../../orders/order_history_page.dart';
import '../business_status.dart';
import '../data/menu_models.dart';
import '../data/menu_service.dart';
import '../menu_controller.dart' as menu_state;
import 'pizza_builder_page.dart';

class MenuHomePage extends StatefulWidget {
  const MenuHomePage(
      {required this.authController, required this.cartController, super.key});

  final AuthController authController;
  final CartController cartController;

  @override
  State<MenuHomePage> createState() => _MenuHomePageState();
}

class _MenuHomePageState extends State<MenuHomePage> {
  late final menu_state.MenuController _menuController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _menuController = menu_state.MenuController(MenuService(ApiClient()))
      ..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _menuController.search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pizzaria Campy'),
            actions: [
              IconButton(
                tooltip: 'Meus endereços',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => CustomerAddressesPage(
                            accessToken: widget.authController.accessToken))),
                icon: const Icon(Icons.location_on_outlined),
              ),
              IconButton(
                tooltip: 'Meus pedidos',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderHistoryPage(
                      accessToken: widget.authController.accessToken,
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              AnimatedBuilder(
                animation: widget.cartController,
                builder: (context, _) => IconButton(
                  tooltip: 'Carrinho',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CartPage(
                        controller: widget.cartController,
                        accessToken: widget.authController.accessToken,
                      ),
                    ),
                  ),
                  icon: Badge(
                    isLabelVisible: widget.cartController.itemCount > 0,
                    label: Text('${widget.cartController.itemCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
              ),
              if ({'ADMIN', 'MANAGER'}
                  .contains(widget.authController.user?.role))
                IconButton(
                  tooltip: 'Painel administrativo',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const AdminDashboardPage()),
                  ),
                  icon: const Icon(Icons.dashboard_outlined),
                ),
              IconButton(
                tooltip: 'Sair',
                onPressed: () async {
                  await widget.authController.logout();
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _menuController.load,
            child: _buildBody(context),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_menuController.status == menu_state.MenuStatus.loading ||
        _menuController.status == menu_state.MenuStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_menuController.status == menu_state.MenuStatus.error) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        message: _menuController.errorMessage ??
            'Não foi possível carregar o cardápio.',
        actionLabel: 'Tentar novamente',
        onAction: _menuController.load,
      );
    }
    if (_menuController.status == menu_state.MenuStatus.empty) {
      return _StateMessage(
        icon: Icons.restaurant_menu_outlined,
        message: 'Nenhum produto encontrado.',
        actionLabel: 'Limpar filtro',
        onAction: () => _menuController.selectCategory(null),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Olá, ${widget.authController.user?.name ?? 'cliente'}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Escolha seu próximo sabor.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Buscar no cardápio',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
                onPressed: _search, icon: const Icon(Icons.arrow_forward)),
          ),
        ),
        const SizedBox(height: 20),
        const BusinessStatusBanner(),
        const SizedBox(height: 20),
        _CategoryList(controller: _menuController),
        const SizedBox(height: 24),
        Text('Destaques', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ..._menuController.products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProductCard(
              product: product,
              cartController: widget.cartController,
              accessToken: widget.authController.accessToken,
            ),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(
      {required this.product,
      required this.cartController,
      required this.accessToken,
      super.key});

  final MenuProduct product;
  final CartController cartController;
  final String? accessToken;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailsPage(
              product: product,
              cartController: cartController,
              accessToken: accessToken,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 112,
                height: 112,
                child: _ProductImage(url: product.imageUrl)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (product.description != null) ...[
                      const SizedBox(height: 4),
                      Text(product.description!,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 12),
                    Text('Ver opções',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage(
      {required this.product,
      required this.cartController,
      required this.accessToken,
      super.key});

  final MenuProduct product;
  final CartController cartController;
  final String? accessToken;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final Future<MenuProductOptions> _options;

  @override
  void initState() {
    super.initState();
    _options = MenuService(ApiClient()).fetchOptions(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: FutureBuilder<MenuProductOptions>(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _StateMessage(
              icon: Icons.error_outline,
              message: 'Não foi possível carregar as opções deste produto.',
              actionLabel: 'Voltar',
              onAction: () => Navigator.of(context).pop(),
            );
          }
          return _ProductOptionsView(
            options: snapshot.data!,
            cartController: widget.cartController,
            accessToken: widget.accessToken,
          );
        },
      ),
    );
  }
}

class _ProductOptionsView extends StatefulWidget {
  const _ProductOptionsView(
      {required this.options,
      required this.cartController,
      required this.accessToken});

  final MenuProductOptions options;
  final CartController cartController;
  final String? accessToken;

  @override
  State<_ProductOptionsView> createState() => _ProductOptionsViewState();
}

class _ProductOptionsViewState extends State<_ProductOptionsView> {
  bool _adding = false;

  Future<void> _openPizzaBuilder() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PizzaBuilderPage(
          options: widget.options,
          cartController: widget.cartController,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (added == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _addSimpleProduct() async {
    final size = widget.options.sizes.firstOrNull;
    final token = widget.accessToken;
    if (size == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível adicionar este produto.')),
      );
      return;
    }
    setState(() => _adding = true);
    try {
      final response = await ApiClient().post(
        '/pricing/quote',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'items': [
            {
              'product_id': widget.options.product.id,
              'product_size_id': size.id,
              'flavor_ids': const <String>[],
              'edge_id': null,
              'extras': const <Map<String, dynamic>>[],
              'quantity': 1,
            },
          ],
          'fulfillment_type': 'PICKUP',
        },
      );
      final total = double.tryParse(
          (response as Map<String, dynamic>)['total_amount'].toString());
      if (total == null) throw const FormatException('Cotação inválida.');
      await widget.cartController.add(
        CartItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          productId: widget.options.product.id,
          productName: widget.options.product.name,
          sizeId: size.id,
          sizeName: size.name,
          flavorIds: const [],
          flavorNames: const [],
          edgeId: null,
          edgeName: null,
          extras: const [],
          quantity: 1,
          unitPrice: total,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível adicionar o produto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _openImageZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                url,
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPizza = isPizzaProductType(widget.options.product.type);
    final hasSizes = widget.options.sizes.isNotEmpty;
    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.viewPaddingOf(context).bottom + 64),
      children: [
        if (widget.options.product.imageUrl != null)
          _ProductImage(
            url: widget.options.product.imageUrl,
            height: 280,
            fit: BoxFit.cover,
            onTap: () =>
                _openImageZoom(context, widget.options.product.imageUrl!),
          ),
        Text(widget.options.product.name,
            style: Theme.of(context).textTheme.headlineMedium),
        if (widget.options.product.description != null) ...[
          const SizedBox(height: 8),
          Text(widget.options.product.description!),
        ],
        if (widget.options.sizes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Tamanhos', style: Theme.of(context).textTheme.titleLarge),
          ...widget.options.sizes.map(
            (size) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(size.name),
              subtitle: Text(
                  '${size.slices} fatias · até ${size.maxFlavors} sabores'),
              trailing: Text(_formatPrice(size.price)),
            ),
          ),
        ],
        if (isPizza && widget.options.flavors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Sabores disponíveis',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.flavors
                  .map((flavor) => Chip(label: Text(flavor.name)))
                  .toList()),
        ],
        if (isPizza && widget.options.edges.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Bordas', style: Theme.of(context).textTheme.titleLarge),
          ...widget.options.edges.map((edge) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(edge.name),
              trailing: Text(_formatPrice(edge.price)))),
        ],
        if (isPizza && widget.options.extras.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Adicionais', style: Theme.of(context).textTheme.titleLarge),
          ...widget.options.extras.map((extra) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(extra.name),
              trailing: Text(_formatPrice(extra.price)))),
        ],
        if (!hasSizes)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
                'Este produto ainda não está disponível. O tamanho e o preço precisam ser configurados pela pizzaria.'),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _adding || !hasSizes
              ? null
              : widget.options.product.type == 'PIZZA'
                  ? _openPizzaBuilder
                  : _addSimpleProduct,
          child: _adding
              ? const CircularProgressIndicator()
              : Text(!hasSizes
                  ? 'Produto indisponível'
                  : widget.options.product.type == 'PIZZA'
                      ? 'Personalizar produto'
                      : 'Adicionar ao carrinho'),
        ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.controller});

  final menu_state.MenuController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: controller.selectedCategoryId == null,
            onSelected: (_) => controller.selectCategory(null),
          ),
          const SizedBox(width: 8),
          ...controller.categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.name),
                selected: controller.selectedCategoryId == category.id,
                onSelected: (_) => controller.selectCategory(category.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage(
      {required this.url,
      this.height = 112,
      this.fit = BoxFit.cover,
      this.onTap});

  final String? url;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.local_pizza_outlined, size: 40),
      );
    }
    final image = Container(
      height: height,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Image.network(
        url!,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      ),
    );
    return onTap == null ? image : GestureDetector(onTap: onTap, child: image);
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage(
      {required this.icon,
      required this.message,
      required this.actionLabel,
      required this.onAction});

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

String _formatPrice(double price) =>
    'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

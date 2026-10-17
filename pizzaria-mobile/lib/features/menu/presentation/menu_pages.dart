import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../../theme/app_theme.dart';
import '../../admin/admin_dashboard_page.dart';
import '../../cart/cart_controller.dart';
import '../../cart/cart_models.dart';
import '../../cart/cart_pages.dart';
import '../../addresses/customer_addresses_page.dart';
import '../../orders/order_history_page.dart';
import '../../settings/settings_pages.dart';
import '../business_status.dart';
import '../data/menu_models.dart';
import '../data/menu_service.dart';
import '../menu_controller.dart' as menu_state;
import 'pizza_builder_page.dart';

class MenuHomePage extends StatefulWidget {
  const MenuHomePage({
    required this.authController,
    required this.cartController,
    required this.settingsController,
    super.key,
  });

  final AuthController authController;
  final CartController cartController;
  final AppSettingsController settingsController;

  @override
  State<MenuHomePage> createState() => _MenuHomePageState();
}

class _MenuHomePageState extends State<MenuHomePage> {
  late final menu_state.MenuController _menuController;
  late final BusinessStatusController _businessStatusController;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _menuController = menu_state.MenuController(MenuService(ApiClient()))
      ..load();
    _businessStatusController = BusinessStatusController()..load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _menuController.dispose();
    _businessStatusController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      if (_menuController.selectedCategoryId == null) {
        await _menuController.load();
      } else {
        await _menuController
            .selectCategory(_menuController.selectedCategoryId);
      }
      return;
    }
    await _menuController.search(normalizedQuery);
  }

  Future<void> _openProduct(MenuProduct product,
      {int? maxFlavorsOverride}) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductDetailsPage(
          product: product,
          cartController: widget.cartController,
          accessToken: widget.authController.accessToken,
          isStoreOpen: _businessStatusController.isOpen &&
              !_businessStatusController.isLoading,
          storeStatusMessage: _businessStatusController.message,
          refreshAccessToken: () async {
            await widget.authController.refreshSession();
            return widget.authController.accessToken;
          },
          maxFlavorsOverride: maxFlavorsOverride,
        ),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item adicionado ao carrinho.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openPizzaMode(int maxFlavors) async {
    final pizzas = _menuController.products
        .where((product) => isPizzaProductType(product.type))
        .toList();
    if (pizzas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhuma pizza disponível no momento.')));
      return;
    }
    final product = await showModalBottomSheet<MenuProduct>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Escolha a pizza base',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ...pizzas.map((product) => ListTile(
                  leading: const Icon(Icons.local_pizza_outlined),
                  title: Text(product.name),
                  subtitle: Text(product.description ?? 'Pizza'),
                  onTap: () => Navigator.of(context).pop(product),
                )),
          ],
        ),
      ),
    );
    if (product != null && mounted) {
      await _openProduct(product, maxFlavorsOverride: maxFlavors);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, _) {
        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            final now = DateTime.now();
            final isSecondPress = _lastBackPress != null &&
                now.difference(_lastBackPress!) <= const Duration(seconds: 2);
            if (isSecondPress) {
              SystemNavigator.pop();
              return;
            }
            _lastBackPress = now;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Pressione voltar novamente para sair.'),
                duration: Duration(seconds: 2),
              ));
          },
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_pizza_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Pizzaria Campy',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
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
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  onSelected: (value) async {
                    switch (value) {
                      case 'addresses':
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CustomerAddressesPage(
                              accessToken: widget.authController.accessToken,
                            ),
                          ),
                        );
                      case 'orders':
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderHistoryPage(
                              accessToken: widget.authController.accessToken,
                            ),
                          ),
                        );
                      case 'admin':
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminDashboardPage(),
                          ),
                        );
                      case 'settings':
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SettingsPage(
                              controller: widget.settingsController,
                            ),
                          ),
                        );
                      case 'logout':
                        await widget.authController.logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'addresses',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.location_on_outlined),
                        title: Text('Meus endereços'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'orders',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.receipt_long_outlined),
                        title: Text('Meus pedidos'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Configurações'),
                      ),
                    ),
                    if ({'ADMIN', 'MANAGER'}
                        .contains(widget.authController.user?.role))
                      const PopupMenuItem(
                        value: 'admin',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.dashboard_outlined),
                          title: Text('Painel administrativo'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.logout),
                        title: Text('Sair'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async => Future.wait([
                _menuController.load(),
                _businessStatusController.load(),
              ]),
              notificationPredicate: (notification) => notification.depth == 0,
              child: _buildBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return AnimatedBuilder(
      animation: _businessStatusController,
      builder: (context, _) => _buildBodyContent(context),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _MenuHero(userName: widget.authController.user?.name),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _PizzaModeCard(
                title: 'Pizza grande',
                subtitle: '1 sabor',
                icon: Icons.looks_one_outlined,
                onTap: () => _openPizzaMode(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PizzaModeCard(
                title: 'Pizza grande',
                subtitle: '2 sabores',
                icon: Icons.looks_two_outlined,
                onTap: () => _openPizzaMode(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Buscar no cardápio',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                      setState(() {});
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        BusinessStatusBanner(controller: _businessStatusController),
        const SizedBox(height: 16),
        _CategoryList(controller: _menuController),
        const SizedBox(height: 24),
        if (_menuController.status == menu_state.MenuStatus.empty) ...[
          _StateMessage(
            icon: Icons.restaurant_menu_outlined,
            message: 'Nenhum produto encontrado.',
            actionLabel: 'Limpar filtro',
            onAction: () {
              _searchController.clear();
              _menuController.search('');
            },
          ),
        ] else ...[
          Text('Destaques', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ..._menuController.products
              .where((product) => !isPizzaProductType(product.type))
              .map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ProductCard(
                    product: product,
                    cartController: widget.cartController,
                    accessToken: widget.authController.accessToken,
                    isOpen: _businessStatusController.isOpen &&
                        !_businessStatusController.isLoading,
                    onOpen: () => _openProduct(product),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _MenuHero extends StatelessWidget {
  const _MenuHero({this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim();
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E4D6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -35,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDCA35A).withValues(alpha: .35),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PIZZARIA CAMPY',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Uma boa pizza\ncomeça aqui.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'serif',
                      fontSize: 28,
                      height: 1.08,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                name == null || name.isEmpty
                    ? 'Monte seu pedido com seus sabores favoritos.'
                    : 'Olá, $name. Monte seu pedido com seus sabores favoritos.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF766451),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  _HeroTag(icon: Icons.local_pizza_outlined, label: '1 sabor'),
                  SizedBox(width: 14),
                  _HeroTag(icon: Icons.pie_chart_outline, label: 'Meio a meio'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF80674B)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF80674B))),
        ],
      );
}

class ProductCard extends StatelessWidget {
  const ProductCard(
      {required this.product,
      required this.cartController,
      required this.accessToken,
      required this.isOpen,
      required this.onOpen,
      super.key});

  final MenuProduct product;
  final CartController cartController;
  final String? accessToken;
  final bool isOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFFFF7F4),
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
                width: 124,
                height: 124,
                child: _ProductImage(
                  url: product.imageUrl,
                  semanticLabel: 'Imagem de ${product.name}',
                )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(isOpen ? 'Ver opções' : 'Indisponível agora',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
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

class _PizzaModeCard extends StatelessWidget {
  const _PizzaModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFF3E7DB),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 21),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle),
              const SizedBox(height: 8),
              Text('Montar agora',
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
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
      required this.isStoreOpen,
      required this.storeStatusMessage,
      required this.refreshAccessToken,
      this.maxFlavorsOverride,
      super.key});

  final MenuProduct product;
  final CartController cartController;
  final String? accessToken;
  final bool isStoreOpen;
  final String? storeStatusMessage;
  final Future<String?> Function() refreshAccessToken;
  final int? maxFlavorsOverride;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final Future<MenuProductOptions> _options;

  @override
  void initState() {
    super.initState();
    _options = MenuService(ApiClient()).fetchOptions(
      widget.product.id,
      halfHalf: widget.maxFlavorsOverride == 2,
    );
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
            isStoreOpen: widget.isStoreOpen,
            storeStatusMessage: widget.storeStatusMessage,
            refreshAccessToken: widget.refreshAccessToken,
            maxFlavorsOverride: widget.maxFlavorsOverride,
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
      required this.accessToken,
      required this.isStoreOpen,
      required this.storeStatusMessage,
      required this.refreshAccessToken,
      this.maxFlavorsOverride});

  final MenuProductOptions options;
  final CartController cartController;
  final String? accessToken;
  final bool isStoreOpen;
  final String? storeStatusMessage;
  final Future<String?> Function() refreshAccessToken;
  final int? maxFlavorsOverride;

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
          refreshAccessToken: widget.refreshAccessToken,
          maxFlavorsOverride: widget.maxFlavorsOverride,
          initialFlavorId: _matchingFlavorId(widget.options),
        ),
      ),
    );
    if (added == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String? _matchingFlavorId(MenuProductOptions options) {
    final productName = options.product.name.trim().toLowerCase();
    return options.flavors
        .where((flavor) => flavor.name.trim().toLowerCase() == productName)
        .map((flavor) => flavor.id)
        .firstOrNull;
  }

  Future<void> _addSimpleProduct() async {
    final size = widget.options.sizes.firstOrNull;
    var token = widget.accessToken;
    token ??= await widget.refreshAccessToken();
    if (!mounted) return;
    if (size == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível adicionar este produto.')),
      );
      return;
    }
    setState(() => _adding = true);
    try {
      Future<dynamic> quote(String accessToken) => ApiClient().post(
            '/pricing/quote',
            headers: {'Authorization': 'Bearer $accessToken'},
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

      dynamic response;
      try {
        response = await quote(token);
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
        token = await widget.refreshAccessToken();
        if (token == null) rethrow;
        response = await quote(token);
      }
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
          doughName: null,
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
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível adicionar o produto.')));
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
        if (!widget.isStoreOpen)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.store_mall_directory_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.storeStatusMessage == null ||
                            widget.storeStatusMessage!.isEmpty
                        ? 'Estamos fechados no momento. Consulte o produto e volte durante o próximo horário de funcionamento para fazer seu pedido.'
                        : '${widget.storeStatusMessage}. Os pedidos estarão disponíveis durante o horário de funcionamento.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        if (widget.options.product.imageUrl != null)
          _ProductImage(
            url: widget.options.product.imageUrl,
            height: 280,
            fit: BoxFit.cover,
            semanticLabel: 'Imagem de ${widget.options.product.name}',
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
              subtitle: isPizza
                  ? Text(
                      '${size.slices} fatias · até ${size.maxFlavors} sabores')
                  : null,
              trailing: Text(size.price == null
                  ? 'Conforme o sabor'
                  : _formatPrice(size.price!)),
            ),
          ),
        ],
        if (isPizza) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Na próxima etapa você escolhe o tamanho, a massa, a borda, os sabores e os adicionais.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          onPressed: _adding || !hasSizes || !widget.isStoreOpen
              ? null
              : isPizza
                  ? _openPizzaBuilder
                  : _addSimpleProduct,
          child: _adding
              ? const CircularProgressIndicator()
              : Text(!hasSizes
                  ? 'Produto indisponível'
                  : !widget.isStoreOpen
                      ? 'Loja fechada'
                      : isPizza
                          ? 'Avançar'
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
      this.onTap,
      this.semanticLabel});

  final String? url;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7E3DC), Color(0xFFFDEFE8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: semanticLabel ?? 'Imagem do produto indisponível',
              image: true,
              child: const Icon(Icons.local_pizza_outlined,
                  size: 34, color: AppTheme.primary),
            ),
            const SizedBox(height: 4),
            Text('Pizzaria Campy',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ],
        ),
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
        semanticLabel: semanticLabel,
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

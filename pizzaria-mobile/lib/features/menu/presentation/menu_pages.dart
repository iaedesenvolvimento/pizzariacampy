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
      {int? maxFlavorsOverride, String? preferredSizeName}) async {
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
          preferredSizeName: preferredSizeName,
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

  Future<void> _openPizzaMode(int maxFlavors,
      {String? preferredSizeName}) async {
    final pizzas = _menuController.products
        .where((product) => isPizzaProductType(product.type))
        .toList();
    if (pizzas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhuma pizza disponível no momento.')));
      return;
    }
    final normalizedBase = pizzas.where((product) {
      final slug = product.name.trim().toLowerCase();
      return slug == 'pizza salgada' || slug == 'pizza doce';
    }).toList();
    if (normalizedBase.isNotEmpty) {
      final product = normalizedBase.firstWhere(
        (product) => product.name.trim().toLowerCase() == 'pizza salgada',
        orElse: () => normalizedBase.first,
      );
      await _openProduct(product,
          maxFlavorsOverride: maxFlavors, preferredSizeName: preferredSizeName);
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
      await _openProduct(product,
          maxFlavorsOverride: maxFlavors, preferredSizeName: preferredSizeName);
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
                          refreshAccessToken: () async {
                            await widget.authController.refreshSession();
                            return widget.authController.accessToken;
                          },
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
    if (_menuController.status == menu_state.MenuStatus.empty) {
      return _StateMessage(
        icon: Icons.restaurant_menu_outlined,
        message: _menuController.selectedCategoryId == null
            ? 'Nenhum produto encontrado.'
            : 'Ainda não há produtos disponíveis nesta categoria.',
        actionLabel: _menuController.selectedCategoryId == null
            ? 'Limpar filtro'
            : 'Voltar ao cardápio',
        onAction: () async {
          _searchController.clear();
          if (_menuController.selectedCategoryId != null) {
            await _menuController.selectCategory(null);
          } else {
            await _menuController.search('');
          }
        },
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _CategoryList(controller: _menuController),
        const SizedBox(height: 18),
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
        if (_menuController.selectedCategoryId == null) ...[
          const _CampyHeroCard(),
          const SizedBox(height: 24),
          Text('Pizzas salgadas',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Escolha o tamanho e deixe o resto com seus sabores favoritos.',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PizzaModeCard(
                  title: 'Pizza Grande · 1 sabor',
                  description:
                      'Um sabor inteiro, do primeiro ao último pedaço.',
                  onTap: () => _openPizzaMode(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PizzaModeCard(
                  title: 'Pizza Grande · meio a meio',
                  description:
                      'Escolha 2 sabores. Uma metade de cada, do seu jeito.',
                  isHalfAndHalf: true,
                  onTap: () => _openPizzaMode(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 44) / 2,
            child: _PizzaModeCard(
              title: 'Pizza Broto · 1 sabor',
              description: 'Um sabor inteiro, do primeiro ao último pedaço.',
              priceLabel: 'R\$ 30,00',
              onTap: () => _openPizzaMode(
                1,
                preferredSizeName: 'Broto',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Row(
            children: [
              IconButton(
                tooltip: 'Voltar ao cardápio',
                onPressed: () => _menuController.selectCategory(null),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  _menuController.categories
                      .firstWhere(
                        (category) =>
                            category.id == _menuController.selectedCategoryId,
                        orElse: () => const MenuCategory(
                            id: '', name: 'Cardápio', slug: ''),
                      )
                      .name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_menuController.selectedCategoryId != null) ...[
          const SizedBox(height: 8),
          ..._menuController.products.map(
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

class _CampyHeroCard extends StatelessWidget {
  const _CampyHeroCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;
    final bodyColor =
        isDark ? const Color(0xFFE4D5CE) : Colors.white.withValues(alpha: .82);
    final panelColor = isDark ? const Color(0xFF3A211D) : AppTheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 188),
        decoration: BoxDecoration(
          color: panelColor,
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF4A241F), Color(0xFF241816)]
                : const [Color(0xFFB72D2D), Color(0xFF7E2025)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -48,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: .10), width: 22),
                ),
              ),
            ),
            Positioned(
              right: 102,
              bottom: -66,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.secondary.withValues(alpha: .16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: .18)),
                          ),
                          child: Text(
                            'O SABOR COMEÇA AQUI',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Seu próximo pedaço\ninesquecível.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                                height: 1.02,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Escolha a massa, combine sabores\ne monte do seu jeito.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: bodyColor,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 126,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 122,
                          height: 122,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: .16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .24),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                        ),
                        Transform.rotate(
                          angle: -.08,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: Image.asset(
                              'assets/catalogo-piloto/a-moda-do-chefe-i.png',
                              width: 118,
                              height: 118,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  'Pizza artesanal da Pizzaria Campy',
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3)),
                              ],
                            ),
                            child: Text(
                              'feito na hora',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryText =
        isDark ? const Color(0xFFD8C8C2) : AppTheme.textSecondary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isDark ? const Color(0xFF2B211E) : const Color(0xFFFFF7F4),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: primaryText,
                                )),
                    if (product.description != null) ...[
                      const SizedBox(height: 4),
                      Text(product.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: secondaryText)),
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
    required this.description,
    required this.onTap,
    this.isHalfAndHalf = false,
    this.priceLabel = 'R\$ 45,00',
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isHalfAndHalf;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2B211E) : Colors.white;
    final primaryText = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryText =
        isDark ? const Color(0xFFD8C8C2) : AppTheme.textSecondary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      elevation: isDark ? 1 : 0,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              width: double.infinity,
              child: _PizzaTypeVisual(
                isHalfAndHalf: isHalfAndHalf,
                isSmall: priceLabel != 'R\$ 45,00',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: primaryText,
                            fontSize: 16,
                            height: 1.15,
                          )),
                  const SizedBox(height: 10),
                  Text(description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: secondaryText,
                            fontSize: 13,
                            height: 1.3,
                          )),
                  const SizedBox(height: 16),
                  Text('A partir de',
                      style: TextStyle(fontSize: 11, color: secondaryText)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(priceLabel,
                          style: TextStyle(
                              fontSize: 20,
                              height: 1.1,
                              color: primaryText,
                              fontWeight: FontWeight.w700)),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 18, color: colors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PizzaTypeVisual extends StatelessWidget {
  const _PizzaTypeVisual({
    required this.isHalfAndHalf,
    required this.isSmall,
  });

  final bool isHalfAndHalf;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? const Color(0xFFFFB174) : AppTheme.primary;
    final background =
        isDark ? const Color(0xFF382722) : const Color(0xFFF8EBDD);
    final label = isSmall
        ? 'BROTO'
        : isHalfAndHalf
            ? '2 SABORES'
            : '1 SABOR';
    final title = isSmall
        ? 'Pizza broto'
        : isHalfAndHalf
            ? 'Meio a meio'
            : 'Pizza grande';

    return Semantics(
      label: '$title, $label',
      child: Container(
        color: background,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -22,
              top: -34,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: foreground.withValues(alpha: .10),
                    width: 18,
                  ),
                ),
              ),
            ),
            Container(
              width: isSmall ? 76 : 92,
              height: isSmall ? 76 : 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2B45C),
                border: Border.all(color: foreground, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: foreground.withValues(alpha: .20),
                    blurRadius: 0,
                    spreadRadius: 7,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (isHalfAndHalf)
                    ClipOval(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: isSmall ? 38 : 46,
                          height: isSmall ? 76 : 92,
                          color: const Color(0xFFF7D98D),
                        ),
                      ),
                    ),
                  Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: isSmall ? 18 : 22,
                    top: isSmall ? 20 : 24,
                    child: _VisualDot(color: foreground),
                  ),
                  Positioned(
                    right: isSmall ? 16 : 20,
                    bottom: isSmall ? 18 : 22,
                    child: _VisualDot(color: foreground),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF251A18) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: foreground.withValues(alpha: .24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHalfAndHalf
                          ? Icons.compare_arrows_rounded
                          : Icons.local_pizza_rounded,
                      size: 13,
                      color: foreground,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
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

class _VisualDot extends StatelessWidget {
  const _VisualDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .88),
        shape: BoxShape.circle,
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
      this.preferredSizeName,
      super.key});

  final MenuProduct product;
  final CartController cartController;
  final String? accessToken;
  final bool isStoreOpen;
  final String? storeStatusMessage;
  final Future<String?> Function() refreshAccessToken;
  final int? maxFlavorsOverride;
  final String? preferredSizeName;

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
            preferredSizeName: widget.preferredSizeName,
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
      this.maxFlavorsOverride,
      this.preferredSizeName});

  final MenuProductOptions options;
  final CartController cartController;
  final String? accessToken;
  final bool isStoreOpen;
  final String? storeStatusMessage;
  final Future<String?> Function() refreshAccessToken;
  final int? maxFlavorsOverride;
  final String? preferredSizeName;

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
          preferredSizeName: widget.preferredSizeName,
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
    final isPizza = isPizzaProductType(widget.options.product.type) &&
        widget.options.flavors.isNotEmpty;
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

class _CategoryList extends StatefulWidget {
  const _CategoryList({required this.controller});

  final menu_state.MenuController controller;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void didUpdateWidget(covariant _CategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.selectedCategoryId !=
        widget.controller.selectedCategoryId) {
      _ensureSelectedCategoryVisible();
    }
  }

  void _ensureSelectedCategoryVisible() {
    final selectedId = widget.controller.selectedCategoryId;
    if (selectedId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final categoryContext = _categoryKeys[selectedId]?.currentContext;
      if (categoryContext == null) return;
      Scrollable.ensureVisible(
        categoryContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = <({String label, String emoji, String? id})>[
      (label: 'Pizzas salgadas', emoji: '🍕', id: null),
      ...widget.controller.categories
          .where((category) =>
              category.name.trim().toLowerCase() != 'pizzas salgadas')
          .map((category) => (
                label: category.name,
                emoji: _categoryEmoji(category.name),
                id: category.id,
              )),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                key: category.id == null
                    ? null
                    : (_categoryKeys[category.id!] ??= GlobalKey()),
                avatar:
                    Text(category.emoji, style: const TextStyle(fontSize: 16)),
                label: Text(category.label),
                side: BorderSide(
                  color: widget.controller.selectedCategoryId == category.id
                      ? (isDark ? const Color(0xFFFF6B61) : AppTheme.primary)
                      : (isDark
                          ? const Color(0xFF6B554D)
                          : const Color(0xFFE1D2C8)),
                ),
                backgroundColor: widget.controller.selectedCategoryId ==
                        category.id
                    ? (isDark
                        ? const Color(0xFF8F302C)
                        : const Color(0xFFFFF0E8))
                    : (isDark ? const Color(0xFF2B211E) : Colors.transparent),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                onPressed: () => widget.controller.selectCategory(category.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryEmoji(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('doce')) return '🍫';
  if (normalized.contains('bebida')) return '🥤';
  if (normalized.contains('esfiha')) return '🥟';
  if (normalized.contains('doce') || normalized.contains('sobremesa')) {
    return '🍰';
  }
  if (normalized.contains('combo')) return '📦';
  return '🍴';
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

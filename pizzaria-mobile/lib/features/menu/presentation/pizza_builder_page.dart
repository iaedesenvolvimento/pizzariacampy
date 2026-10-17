import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../cart/cart_controller.dart';
import '../../cart/cart_models.dart';
import '../data/menu_models.dart';
import '../pizza_builder_controller.dart';

class PizzaBuilderPage extends StatefulWidget {
  const PizzaBuilderPage(
      {required this.options,
      required this.cartController,
      required this.accessToken,
      required this.refreshAccessToken,
      this.maxFlavorsOverride,
      this.preferredSizeName,
      this.initialFlavorId,
      super.key});

  final MenuProductOptions options;
  final CartController cartController;
  final String? accessToken;
  final Future<String?> Function() refreshAccessToken;
  final int? maxFlavorsOverride;
  final String? preferredSizeName;
  final String? initialFlavorId;

  static const fixedDoughs = ['Tradicional', 'Fina', 'Grossa'];

  @override
  State<PizzaBuilderPage> createState() => _PizzaBuilderPageState();
}

class _PizzaBuilderPageState extends State<PizzaBuilderPage> {
  static const _noEdgeId = '__no_edge__';
  late final PizzaBuilderController _controller;
  String _flavorQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = PizzaBuilderController(
      ApiClient(),
      widget.options,
      widget.accessToken,
      maxFlavorsOverride: widget.maxFlavorsOverride,
      preferredSizeName: widget.preferredSizeName,
      initialFlavorId: widget.initialFlavorId,
      refreshAccessToken: widget.refreshAccessToken,
    );
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monte sua pizza')),
      body: Builder(
        builder: (context) {
          try {
            return _buildBody(context);
          } catch (error) {
            return Center(
                child: Text('Não foi possível montar a pizza: $error'));
          }
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          try {
            return _buildBottomBar(context);
          } catch (error) {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.options.sizes.isEmpty) {
      return const Center(
          child: Text('Este produto não possui tamanhos disponíveis.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.options.product.name,
              style: Theme.of(context).textTheme.headlineMedium),
          if (widget.options.product.description != null) ...[
            const SizedBox(height: 8),
            Text(widget.options.product.description!),
          ],
          _sectionTitle(context, '1. Escolha o tamanho'),
          ..._controller.sizesByPrice.map(
            (size) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: size.id,
              groupValue: _controller.selectedSizeId,
              onChanged: (value) {
                if (value != null) _controller.selectSize(value);
              },
              title: Text(size.name),
              subtitle: Text(
                  '${size.slices} fatias · até ${size.maxFlavors} sabores'),
              secondary: Text(size.price == null
                  ? 'Preço conforme o sabor'
                  : _formatPrice(size.price!)),
            ),
          ),
          _sectionTitle(context, '2. Escolha a massa'),
          ...PizzaBuilderPage.fixedDoughs.map(
            (dough) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: dough,
              groupValue: _controller.selectedDoughName,
              onChanged: (value) {
                if (value != null) _controller.selectDough(value);
              },
              title: Text(dough),
            ),
          ),
          if (_configurationsForSelectedSize.isNotEmpty) ...[
            _sectionTitle(context, '3. Escolha a oferta'),
            ..._configurationsForSelectedSize.map(
              (configuration) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: configuration.id,
                groupValue: _controller.selectedConfigurationId,
                onChanged: (value) {
                  if (value != null) _controller.selectConfiguration(value);
                },
                title: Text(configuration.displayName),
                subtitle: Text('${configuration.flavorCount} sabor(es)'),
              ),
            ),
          ],
          _buildFlavorSelection(context),
          if (widget.options.edges.isNotEmpty) ...[
            _sectionTitle(context, '5. Escolha a borda'),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: _noEdgeId,
              groupValue: _controller.selectedEdgeId ?? _noEdgeId,
              onChanged: (_) => _controller.selectEdge(null),
              title: const Text('Sem borda'),
            ),
            ...widget.options.edges.map(
              (edge) => RadioListTile<String?>(
                contentPadding: EdgeInsets.zero,
                value: edge.id,
                groupValue: _controller.selectedEdgeId,
                onChanged: (value) => _controller.selectEdge(value),
                title: Text(edge.name),
                secondary: Text('+ ${_formatPrice(edge.price)}'),
              ),
            ),
          ],
          if (widget.options.extras.isNotEmpty) ...[
            _sectionTitle(context, '6. Adicionais'),
            ...widget.options.extras.map(
              (extra) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _controller.selectedExtras.containsKey(extra.id),
                onChanged: (_) => _controller.toggleExtra(extra.id),
                title: Text(extra.name),
                secondary: Text('+ ${_formatPrice(extra.price)}'),
              ),
            ),
          ],
          _sectionTitle(context, '7. Quantidade'),
          Row(
            children: [
              IconButton(
                onPressed: _controller.quantity > 1
                    ? () => _controller.setQuantity(_controller.quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${_controller.quantity}',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed: () =>
                    _controller.setQuantity(_controller.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (_controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (widget.options.sizes.isEmpty) return const SizedBox.shrink();
    final canAdd = _controller.canCustomize && !_controller.isQuoting;
    return SafeArea(
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
          ),
          child: Row(
            children: [
              _QuantityControl(
                quantity: _controller.quantity,
                onDecrease: _controller.quantity > 1
                    ? () => _controller.setQuantity(_controller.quantity - 1)
                    : null,
                onIncrease: () =>
                    _controller.setQuantity(_controller.quantity + 1),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total do item', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _controller.isQuoting || _controller.quoteTotal == null
                          ? '—'
                          : _formatPrice(_controller.quoteTotal!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: canAdd ? _addToCart : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildFlavorSelection(BuildContext context) {
    final limit = _controller.flavorLimit;
    final selectedCount = _controller.selectedFlavorIds.length;
    final query = _flavorQuery.trim().toLowerCase();
    final flavors = widget.options.flavors.where((flavor) {
      if (query.isEmpty) return true;
      return '${flavor.name} ${flavor.description ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                limit == 2 ? '01. Escolha os 2 sabores' : '01. Escolha o sabor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '$selectedCount de $limit selecionado${limit == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Text(
          limit == 2
              ? 'Escolha dois sabores diferentes para sua pizza.'
              : 'Escolha o sabor da sua pizza.',
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _flavorQuery = value),
          decoration: const InputDecoration(
            hintText: 'Buscar sabor ou ingrediente',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        ...flavors.map(
          (flavor) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _controller.toggleFlavor(flavor.id),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Checkbox(
                      value: _controller.selectedFlavorIds.contains(flavor.id),
                      onChanged: (_) => _controller.toggleFlavor(flavor.id),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(flavor.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (flavor.description != null) ...[
                            const SizedBox(height: 3),
                            Text(flavor.description!,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _flavorPrice(flavor) == null
                          ? 'Conforme tamanho'
                          : _formatPrice(_flavorPrice(flavor)!),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (flavors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Nenhum sabor encontrado.'),
          ),
      ],
    );
  }

  double? _flavorPrice(MenuFlavor flavor) {
    final sizeId = _controller.selectedSizeId;
    if (sizeId == null) return null;
    for (final price in widget.options.flavorPrices) {
      if (price.flavorId == flavor.id && price.productSizeId == sizeId) {
        return price.price;
      }
    }
    return null;
  }

  List<MenuPizzaConfiguration> get _configurationsForSelectedSize => widget
      .options.configurations
      .where((configuration) =>
          configuration.productSizeId == _controller.selectedSizeId &&
          configuration.isActive)
      .toList()
    ..sort(
        (first, second) => first.displayOrder.compareTo(second.displayOrder));

  Future<void> _addToCart() async {
    final selectedSize = _controller.selectedSize;
    final quoteTotal = _controller.quoteTotal;
    if (selectedSize == null || quoteTotal == null) return;
    final selectedFlavors = widget.options.flavors
        .where((flavor) => _controller.selectedFlavorIds.contains(flavor.id))
        .toList();
    final selectedExtras = widget.options.extras
        .where((extra) => _controller.selectedExtras.containsKey(extra.id))
        .map((extra) =>
            CartExtra(id: extra.id, name: extra.name, price: extra.price))
        .toList();
    await widget.cartController.add(
      CartItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: widget.options.product.id,
        productName: widget.options.product.name,
        sizeId: selectedSize.id,
        sizeName: selectedSize.name,
        pizzaConfigurationId: _controller.selectedConfigurationId,
        doughName: _controller.selectedDoughName,
        flavorIds: selectedFlavors.map((flavor) => flavor.id).toList(),
        flavorNames: selectedFlavors.map((flavor) => flavor.name).toList(),
        edgeId: _controller.selectedEdgeId,
        edgeName: widget.options.edges
            .where((edge) => edge.id == _controller.selectedEdgeId)
            .map((edge) => edge.name)
            .firstOrNull,
        extras: selectedExtras,
        quantity: _controller.quantity,
        unitPrice: quoteTotal / _controller.quantity,
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }
}

String _formatPrice(double price) =>
    'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1D8D2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir quantidade',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$quantity'),
          IconButton(
            tooltip: 'Aumentar quantidade',
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

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
      super.key});

  final MenuProductOptions options;
  final CartController cartController;
  final String? accessToken;
  final Future<String?> Function() refreshAccessToken;

  @override
  State<PizzaBuilderPage> createState() => _PizzaBuilderPageState();
}

class _PizzaBuilderPageState extends State<PizzaBuilderPage> {
  static const _noEdgeId = '__no_edge__';
  late final PizzaBuilderController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        PizzaBuilderController(
          ApiClient(),
          widget.options,
          widget.accessToken,
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
              secondary: Text(_formatPrice(size.price)),
            ),
          ),
          _sectionTitle(context, '2. Escolha os sabores'),
          Text(_flavorLimitText),
          const SizedBox(height: 8),
          ...widget.options.flavors.map(
            (flavor) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _controller.selectedFlavorIds.contains(flavor.id),
              onChanged: (_) => _controller.toggleFlavor(flavor.id),
              title: Text(flavor.name),
              subtitle:
                  flavor.description == null ? null : Text(flavor.description!),
            ),
          ),
          if (_controller.selectedFlavorIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_selectedFlavorsText,
                style: Theme.of(context).textTheme.labelLarge),
          ],
          if (widget.options.edges.isNotEmpty) ...[
            _sectionTitle(context, '3. Escolha a borda'),
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
            _sectionTitle(context, '4. Adicionais'),
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
          _sectionTitle(context, '5. Quantidade'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _controller.isQuoting
                  ? const Text('Atualizando preço...')
                  : Text(
                      _controller.quoteTotal == null
                          ? 'Selecione os sabores'
                          : _formatPrice(_controller.quoteTotal!),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: canAdd ? _addToCart : null,
                child: const Text('Adicionar'),
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

  String get _flavorLimitText {
    final maxFlavors = _controller.selectedSize?.maxFlavors ?? 0;
    return 'Selecione até $maxFlavors ${maxFlavors == 1 ? 'sabor' : 'sabores'}.';
  }

  String get _selectedFlavorsText {
    final names = widget.options.flavors
        .where((flavor) => _controller.selectedFlavorIds.contains(flavor.id))
        .map((flavor) => flavor.name)
        .toList();
    if (names.length == 1) return names.first;
    return names
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}/${names.length} ${entry.value}')
        .join(' · ');
  }

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

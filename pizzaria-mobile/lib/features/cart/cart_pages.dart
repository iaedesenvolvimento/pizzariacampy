import 'package:flutter/material.dart';

import 'cart_controller.dart';
import 'cart_models.dart';
import '../checkout/checkout_pages.dart';

class CartPage extends StatelessWidget {
  const CartPage({required this.controller, required this.accessToken, super.key});

  final CartController controller;
  final String? accessToken;

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
                  : _CartContents(controller: controller),
          bottomNavigationBar: controller.isEmpty
              ? null
              : _CartSummary(
                  controller: controller,
                  accessToken: accessToken,
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Limpar')),
        ],
      ),
    );
    if (shouldClear == true) await controller.clear();
  }
}

class _CartContents extends StatelessWidget {
  const _CartContents({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: controller.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CartItemTile(controller: controller, item: controller.items[index]),
    );
  }
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
                Expanded(child: Text(item.productName, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: () => controller.remove(item.id),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(item.sizeName),
            if (flavorText.isNotEmpty) Text(flavorText),
            if (item.edgeName != null) Text('Borda: ${item.edgeName}'),
            if (item.extras.isNotEmpty) Text('Adicionais: ${item.extras.map((extra) => extra.name).join(', ')}'),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () => controller.updateQuantity(item.id, item.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: () => controller.updateQuantity(item.id, item.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(_formatPrice(item.totalPrice), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.controller, required this.accessToken});

  final CartController controller;
  final String? accessToken;

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
            Text(_formatPrice(controller.subtotal), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CheckoutPage(
                    cartController: controller,
                    accessToken: accessToken,
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
            const Icon(Icons.shopping_bag_outlined, size: 64),
            const SizedBox(height: 16),
            Text('Seu carrinho está vazio.', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Escolha um produto no cardápio para começar.'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onBrowse, child: const Text('Voltar ao cardápio')),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(double price) => 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

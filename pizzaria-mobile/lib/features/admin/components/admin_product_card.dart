import 'package:flutter/material.dart';

import '../core/admin_spacing.dart';

class AdminProductCard extends StatelessWidget {
  const AdminProductCard({
    required this.item,
    required this.categoryName,
    required this.onEdit,
    required this.onToggle,
    required this.onPrices,
    required this.onDelete,
    super.key,
  });

  final Map<String, dynamic> item;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onPrices;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = item['is_active'] == true;
    final imageUrl = item['image_url']?.toString();
    final type = _typeLabel(item['product_type']?.toString());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(url: imageUrl),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name']?.toString() ?? '',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AdminSpacing.xs),
                  Text('$type · $categoryName'),
                  const SizedBox(height: AdminSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        isActive
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: AdminSpacing.xs),
                      Text(isActive ? 'Ativo' : 'Inativo'),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.xs),
                  Text('Preços gerenciados em tamanhos e variações',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ações do produto',
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'prices':
                    onPrices();
                  case 'toggle':
                    onToggle();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar produto'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'prices',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.price_change_outlined),
                    title: Text('Tamanhos e preços'),
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline),
                    title: Text(isActive ? 'Pausar produto' : 'Ativar produto'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Excluir definitivamente'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String? value) => switch (value?.toUpperCase()) {
        'BEVERAGE' || 'DRINK' => 'Bebida',
        'DESSERT' => 'Sobremesa',
        'COMBO' => 'Combo',
        'ESFIHA' => 'Esfiha',
        _ => 'Pizza',
      };
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }
    return Image.network(
      url!,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(icon: Icons.image_outlined),
    );
  }

  Widget _placeholder({IconData icon = Icons.fastfood_outlined}) => Container(
        width: 72,
        height: 72,
        color: Colors.black12,
        alignment: Alignment.center,
        child: Icon(icon),
      );
}

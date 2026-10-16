import 'package:flutter/material.dart';

import '../core/admin_spacing.dart';

class AdminCustomerCard extends StatelessWidget {
  const AdminCustomerCard({required this.customer, super.key});

  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final name = customer['name']?.toString().trim() ?? '';
    final email = customer['email']?.toString().trim() ?? '';
    final isActive = customer['is_active'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(_initials(name)),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Cliente sem nome' : name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AdminSpacing.xs),
                  SelectableText(email),
                  const SizedBox(height: AdminSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: AdminSpacing.xs),
                      Text(isActive ? 'Ativo' : 'Inativo'),
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

  String _initials(String name) {
    final words =
        name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }
}

import 'package:flutter/material.dart';

import '../core/admin_radius.dart';
import '../core/admin_spacing.dart';

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard(
      {required this.child, this.title, this.action, super.key});

  final Widget child;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AdminRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || action != null)
              Row(
                children: [
                  if (title != null)
                    Expanded(
                        child: Text(title!,
                            style: Theme.of(context).textTheme.titleMedium)),
                  if (action != null) action!,
                ],
              ),
            if (title != null || action != null)
              const SizedBox(height: AdminSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/admin_spacing.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    required this.title,
    this.subtitle,
    this.actions,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.xl),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AdminSpacing.lg,
        runSpacing: AdminSpacing.md,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AdminSpacing.sm),
                  Text(subtitle!),
                ],
              ],
            ),
          ),
          if (actions != null)
            Wrap(spacing: AdminSpacing.sm, children: actions!),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/admin_spacing.dart';

class AdminActionMenuItem {
  const AdminActionMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.enabled = true,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool enabled;
}

class AdminActionMenu extends StatelessWidget {
  const AdminActionMenu({
    required this.items,
    required this.onSelected,
    this.tooltip = 'Mais ações',
    super.key,
  });

  final List<AdminActionMenuItem> items;
  final ValueChanged<String> onSelected;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              enabled: item.enabled,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon),
                  const SizedBox(width: AdminSpacing.md),
                  Flexible(child: Text(item.label)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

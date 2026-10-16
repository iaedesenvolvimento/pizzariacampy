import 'package:flutter/material.dart';

import '../core/admin_spacing.dart';

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: AdminSpacing.sm),
            children[index],
          ],
        ],
      ),
    );
  }
}

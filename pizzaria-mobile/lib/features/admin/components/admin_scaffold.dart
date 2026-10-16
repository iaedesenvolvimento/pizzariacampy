import 'package:flutter/material.dart';

import '../core/admin_breakpoints.dart';
import '../core/admin_navigation.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.activeDestination,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final AdminDestinationId? activeDestination;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final layout = AdminBreakpoints.of(context);
    final isCompact = layout == AdminLayoutSize.compact;
    return Scaffold(
      drawer: isCompact ? _buildDrawer(context) : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: isCompact
          ? body
          : Row(
              children: [
                _buildNavigationRail(context, layout),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, AdminLayoutSize layout) {
    final selectedIndex =
        AdminDestinations.main.indexWhere(_isDestinationActive);
    return NavigationRail(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      labelType: layout == AdminLayoutSize.expanded
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.selected,
      onDestinationSelected: (index) {
        final destination = AdminDestinations.main[index];
        if (destination.id != activeDestination) {
          Navigator.of(context).pushReplacementNamed(destination.route);
        }
      },
      destinations: [
        for (final destination in AdminDestinations.main)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }

  bool _isDestinationActive(AdminDestination destination) {
    return destination.id == activeDestination ||
        destination.children.any((child) => child.id == activeDestination);
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Administração',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final destination in AdminDestinations.main)
              if (destination.children.isEmpty)
                _drawerItem(context, destination)
              else
                ExpansionTile(
                  initiallyExpanded: activeDestination == destination.id,
                  leading: Icon(destination.icon),
                  title: Text(destination.label),
                  children: [
                    for (final child in destination.children)
                      _drawerItem(context, child, indent: true),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, AdminDestination destination,
      {bool indent = false}) {
    final selected = destination.id == activeDestination;
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent ? 32 : 16, right: 16),
      selected: selected,
      leading: Icon(destination.icon),
      title: Text(destination.label),
      onTap: () {
        Navigator.pop(context);
        if (!selected) {
          Navigator.of(context).pushReplacementNamed(destination.route);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

enum AdminDestinationId {
  dashboard,
  orders,
  menu,
  products,
  categories,
  sizes,
  flavors,
  edges,
  extras,
  customers,
  coupons,
  delivery,
  hours,
  settings,
}

class AdminDestination {
  const AdminDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.children = const [],
  });

  final AdminDestinationId id;
  final String label;
  final IconData icon;
  final String route;
  final List<AdminDestination> children;
}

abstract final class AdminDestinations {
  static const dashboard = AdminDestination(
    id: AdminDestinationId.dashboard,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/admin',
  );
  static const orders = AdminDestination(
    id: AdminDestinationId.orders,
    label: 'Pedidos',
    icon: Icons.receipt_long_outlined,
    route: '/admin/orders',
  );
  static const menu = AdminDestination(
    id: AdminDestinationId.menu,
    label: 'Cardápio',
    icon: Icons.fastfood_outlined,
    route: '/admin/catalog/products',
    children: [
      AdminDestination(
        id: AdminDestinationId.products,
        label: 'Produtos',
        icon: Icons.fastfood_outlined,
        route: '/admin/catalog/products',
      ),
      AdminDestination(
        id: AdminDestinationId.categories,
        label: 'Categorias',
        icon: Icons.category_outlined,
        route: '/admin/catalog/categories',
      ),
      AdminDestination(
        id: AdminDestinationId.sizes,
        label: 'Tamanhos e preços',
        icon: Icons.straighten_outlined,
        route: '/admin/catalog/products',
      ),
      AdminDestination(
        id: AdminDestinationId.flavors,
        label: 'Sabores',
        icon: Icons.local_pizza_outlined,
        route: '/admin/catalog/flavors',
      ),
      AdminDestination(
        id: AdminDestinationId.edges,
        label: 'Bordas',
        icon: Icons.radio_button_checked,
        route: '/admin/catalog/edges',
      ),
      AdminDestination(
        id: AdminDestinationId.extras,
        label: 'Adicionais',
        icon: Icons.add_circle_outline,
        route: '/admin/catalog/extras',
      ),
    ],
  );
  static const customers = AdminDestination(
    id: AdminDestinationId.customers,
    label: 'Clientes',
    icon: Icons.people_outline,
    route: '/admin/customers',
  );
  static const coupons = AdminDestination(
    id: AdminDestinationId.coupons,
    label: 'Cupons',
    icon: Icons.confirmation_number_outlined,
    route: '/admin/coupons',
  );
  static const delivery = AdminDestination(
    id: AdminDestinationId.delivery,
    label: 'Entregas',
    icon: Icons.delivery_dining_outlined,
    route: '/admin/delivery',
  );
  static const hours = AdminDestination(
    id: AdminDestinationId.hours,
    label: 'Horários',
    icon: Icons.schedule,
    route: '/admin/hours',
  );
  static const settings = AdminDestination(
    id: AdminDestinationId.settings,
    label: 'Configurações',
    icon: Icons.settings_outlined,
    route: '/admin/settings',
  );

  static const main = [
    dashboard,
    orders,
    menu,
    customers,
    coupons,
    delivery,
    hours,
    settings,
  ];

  static bool isAdminRoute(String? route) =>
      route?.startsWith('/admin') == true;
}

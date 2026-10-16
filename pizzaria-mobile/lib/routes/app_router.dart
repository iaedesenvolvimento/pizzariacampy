import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../features/cart/cart_controller.dart';
import '../core/settings/app_settings_controller.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/menu/presentation/menu_pages.dart';
import '../features/admin/admin_catalog_page.dart';
import '../features/admin/admin_coupons_page.dart';
import '../features/admin/admin_customers_page.dart';
import '../features/admin/admin_dashboard_page.dart';
import '../features/admin/admin_delivery_zones_page.dart';
import '../features/admin/admin_hours_page.dart';
import '../features/admin/admin_options_page.dart';
import '../features/admin/admin_orders_page.dart';
import '../features/admin/admin_settings_page.dart';
import '../features/admin/core/admin_navigation.dart';

class AppRouter {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const recovery = '/recovery';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AuthController controller,
    CartController cartController,
    AppSettingsController settingsController,
  ) {
    if (AdminDestinations.isAdminRoute(settings.name)) {
      final role = controller.user?.role.toUpperCase();
      if (role != 'ADMIN' && role != 'MANAGER') {
        return MaterialPageRoute<void>(
          builder: (_) => AuthGate(
            controller: controller,
            cartController: cartController,
            settingsController: settingsController,
          ),
          settings: settings,
        );
      }
    }

    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => MenuHomePage(
            authController: controller,
            cartController: cartController,
            settingsController: settingsController,
          ),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => LoginPage(
            controller: controller,
            settingsController: settingsController,
          ),
          settings: settings,
        );
      case register:
        return MaterialPageRoute<void>(
          builder: (_) => RegisterPage(
            controller: controller,
            settingsController: settingsController,
          ),
          settings: settings,
        );
      case recovery:
        return MaterialPageRoute<void>(
          builder: (_) => RecoveryPage(controller: controller),
          settings: settings,
        );
      case '/admin':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminDashboardPage(),
          settings: settings,
        );
      case '/admin/orders':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminOrdersPage(),
          settings: settings,
        );
      case '/admin/catalog/products':
        return MaterialPageRoute<void>(
          builder: (_) =>
              const AdminCatalogPage(mode: AdminCatalogMode.products),
          settings: settings,
        );
      case '/admin/catalog/categories':
        return MaterialPageRoute<void>(
          builder: (_) =>
              const AdminCatalogPage(mode: AdminCatalogMode.categories),
          settings: settings,
        );
      case '/admin/catalog/flavors':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminOptionsPage(mode: AdminOptionMode.flavors),
          settings: settings,
        );
      case '/admin/catalog/edges':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminOptionsPage(mode: AdminOptionMode.edges),
          settings: settings,
        );
      case '/admin/catalog/extras':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminOptionsPage(mode: AdminOptionMode.extras),
          settings: settings,
        );
      case '/admin/customers':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminCustomersPage(),
          settings: settings,
        );
      case '/admin/coupons':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminCouponsPage(),
          settings: settings,
        );
      case '/admin/delivery':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminDeliveryZonesPage(),
          settings: settings,
        );
      case '/admin/hours':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminHoursPage(),
          settings: settings,
        );
      case '/admin/settings':
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSettingsPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => AuthGate(
            controller: controller,
            cartController: cartController,
            settingsController: settingsController,
          ),
          settings: settings,
        );
    }
  }
}

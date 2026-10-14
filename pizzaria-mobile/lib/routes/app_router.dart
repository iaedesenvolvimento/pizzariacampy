import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../features/cart/cart_controller.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/menu/presentation/menu_pages.dart';

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
  ) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => MenuHomePage(authController: controller, cartController: cartController),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => LoginPage(controller: controller),
          settings: settings,
        );
      case register:
        return MaterialPageRoute<void>(
          builder: (_) => RegisterPage(controller: controller),
          settings: settings,
        );
      case recovery:
        return MaterialPageRoute<void>(
          builder: (_) => RecoveryPage(controller: controller),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => AuthGate(controller: controller, cartController: cartController),
          settings: settings,
        );
    }
  }
}

import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/auth_service.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_storage.dart';
import 'features/cart/cart_controller.dart';
import 'features/auth/presentation/auth_pages.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class PizzariaApp extends StatefulWidget {
  const PizzariaApp({super.key});

  @override
  State<PizzariaApp> createState() => _PizzariaAppState();
}

class _PizzariaAppState extends State<PizzariaApp> {
  AuthController? _authController;
  CartController? _cartController;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final storage = await AppStorage.create();
    _cartController = CartController(storage)..initialize();
    _authController = AuthController(
      AuthService(apiClient: ApiClient(config: AppConfig.fromEnvironment()), storage: storage),
    )..initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _authController;
    final cartController = _cartController;
    return MaterialApp(
      title: 'Pizzaria Campy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: controller == null || cartController == null
          ? const _StartupPage()
          : AuthGate(controller: controller, cartController: cartController),
      onGenerateRoute: (settings) {
        if (controller == null || cartController == null) {
          return MaterialPageRoute<void>(
            builder: (_) => const _StartupPage(),
            settings: settings,
          );
        }
        return AppRouter.onGenerateRoute(settings, controller, cartController);
      },
    );
  }

  @override
  void dispose() {
    _authController?.dispose();
    _cartController?.dispose();
    super.dispose();
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/auth_service.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_storage.dart';
import 'core/settings/app_settings_controller.dart';
import 'features/cart/cart_controller.dart';
import 'features/auth/presentation/auth_pages.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class PizzariaApp extends StatefulWidget {
  const PizzariaApp({super.key});

  @override
  State<PizzariaApp> createState() => _PizzariaAppState();
}

class _PizzariaAppState extends State<PizzariaApp> with WidgetsBindingObserver {
  AuthController? _authController;
  CartController? _cartController;
  AppSettingsController? _settingsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _authController?.refreshSession();
    }
  }

  Future<void> _initializeAuth() async {
    final storage = await AppStorage.create();
    _cartController = CartController(storage)..initialize();
    _settingsController = AppSettingsController(storage)..initialize();
    _authController = AuthController(
      AuthService(
          apiClient: ApiClient(config: AppConfig.fromEnvironment()),
          storage: storage),
    )..initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _authController;
    final cartController = _cartController;
    final settingsController = _settingsController;
    if (settingsController == null) {
      return const MaterialApp(home: _StartupPage());
    }
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) => MaterialApp(
        title: 'Pizzaria Campy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settingsController.themeMode,
        home: controller == null || cartController == null
            ? const _StartupPage()
            : AuthGate(
                controller: controller,
                cartController: cartController,
                settingsController: settingsController,
              ),
        onGenerateRoute: (settings) {
          if (controller == null || cartController == null) {
            return MaterialPageRoute<void>(
              builder: (_) => const _StartupPage(),
              settings: settings,
            );
          }
          return AppRouter.onGenerateRoute(
              settings, controller, cartController, settingsController);
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authController?.dispose();
    _cartController?.dispose();
    _settingsController?.dispose();
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

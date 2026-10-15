import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/auth_service.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_storage.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/notifications/realtime_notification_service.dart';
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
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
    )..addListener(_syncRealtime);
    realtimeNotificationService.events.listen(_showRealtimeNotification);
    await _authController!.initialize();
    _syncRealtime();
    if (mounted) setState(() {});
  }

  void _syncRealtime() {
    final auth = _authController;
    final service = realtimeNotificationService;
    if (auth == null) return;
    if (auth.isAuthenticated && auth.accessToken != null) {
      service.connect(auth.accessToken!);
    } else {
      service.disconnect();
    }
  }

  void _showRealtimeNotification(RealtimeNotification notification) {
    final number = notification.orderNumber;
    final message = switch (notification.type) {
      'order.created' => 'Novo pedido recebido${number.isEmpty ? '' : ': $number'}',
      'order.status_changed' =>
        'Pedido ${number.isEmpty ? '' : '$number: '} ${_statusLabel(notification.status)}',
      _ => null,
    };
    if (message == null) return;
    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  String _statusLabel(String status) => switch (status) {
        'PENDING' => 'pedido recebido',
        'CONFIRMED' => 'pedido confirmado',
        'PREPARING' => 'pedido em preparo',
        'READY' => 'pedido pronto',
        'OUT_FOR_DELIVERY' => 'pedido saiu para entrega',
        'DELIVERED' => 'pedido entregue',
        'CANCELLED' => 'pedido cancelado',
        _ => 'status atualizado',
      };

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
        scaffoldMessengerKey: _scaffoldMessengerKey,
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
    realtimeNotificationService.disconnect();
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

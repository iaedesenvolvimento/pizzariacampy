import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import '../config/app_config.dart';

class RealtimeNotification {
  const RealtimeNotification({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;

  String get orderNumber => data['order_number']?.toString() ?? '';
  String get status => data['status']?.toString() ?? '';
}

class RealtimeNotificationService {
  RealtimeNotificationService({AppConfig? config})
      : _config = config ?? AppConfig.fromEnvironment();

  final AppConfig _config;
  final _events = StreamController<RealtimeNotification>.broadcast();
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String? _token;
  bool _shouldReconnect = false;

  Stream<RealtimeNotification> get events => _events.stream;

  void connect(String token) {
    if (_token == token && _channel != null) return;
    disconnect();
    _token = token;
    _shouldReconnect = true;
    _open();
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _token = null;
  }

  void dispose() {
    disconnect();
    _events.close();
  }

  void _open() {
    final token = _token;
    if (!_shouldReconnect || token == null) return;
    final base = Uri.parse(_config.apiBaseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final uri = base.replace(scheme: scheme, path: '${base.path}/ws/notifications');
    try {
      final channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        pingInterval: const Duration(seconds: 25),
      );
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _scheduleReconnect,
        onError: (_, __) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    dynamic decoded;
    try {
      decoded = message is String ? jsonDecode(message) : message;
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    final type = decoded['type']?.toString();
    if (type == null || type.isEmpty) return;
    _events.add(RealtimeNotification(
      type: type,
      data: Map<String, dynamic>.from(decoded),
    ));
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectTimer != null) return;
    _channel = null;
    _subscription = null;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      _open();
    });
  }
}

final realtimeNotificationService = RealtimeNotificationService();

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'realtime_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseNotificationService {
  static const _channelId = 'campy_orders';
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize({
    required void Function(RealtimeNotification) onMessage,
    void Function(String token)? onTokenRefresh,
  }) async {
    const androidSettings = AndroidInitializationSettings('@drawable/campy_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Pedidos',
          description: 'Atualizações de pedidos da Pizzaria Campy',
          importance: Importance.high,
          playSound: true,
        ));
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? 'Pizzaria Campy';
      final body = notification?.body ?? message.data['body'] ?? '';
      showLocalNotification(title: title, body: body);
      onMessage(RealtimeNotification(
        type: message.data['type']?.toString() ?? 'push.notification',
        data: {
          ...message.data,
          'title': title,
          'body': body,
        },
      ));
    });
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      onTokenRefresh?.call(token);
    });
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> showLocalNotification({required String title, required String body}) {
    return _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Pedidos',
          channelDescription: 'Atualizações de pedidos da Pizzaria Campy',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}

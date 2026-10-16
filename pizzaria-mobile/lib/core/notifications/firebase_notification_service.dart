import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'realtime_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseNotificationService {
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize({
    required void Function(RealtimeNotification) onMessage,
    void Function(String token)? onTokenRefresh,
  }) async {
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
      onMessage(RealtimeNotification(
        type: message.data['type']?.toString() ?? 'push.notification',
        data: {
          ...message.data,
          'title': notification?.title ?? message.data['title'] ?? 'Pizzaria Campy',
          'body': notification?.body ?? message.data['body'] ?? '',
        },
      ));
    });
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      onTokenRefresh?.call(token);
    });
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}

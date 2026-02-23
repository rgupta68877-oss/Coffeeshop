import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'order_updates',
    'Order Updates',
    description: 'Notifications for order status updates.',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static bool _localInitialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await initialize();
  }

  static Future<void> initializeForBackground() async {
    if (_localInitialized) return;
    _localInitialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await initializeForBackground();

    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _syncToken();
      }
    });

    await _syncToken();
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Order Update';
    final body = message.notification?.body ??
        (message.data['body']?.toString() ?? 'Your order status has changed.');
    await showLocalNotification(title: title, body: body);
  }

  static Future<void> _syncToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

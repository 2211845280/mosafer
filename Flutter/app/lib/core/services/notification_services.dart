import 'dart:io';
import 'package:app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // هنا تقدر تخزن الإشعار أو تحدث بيانات محلية
  // print('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

  Future<void> init() async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _setupFirebaseListeners();

    String? token;

    if (Platform.isIOS) {
      final apnsToken = await _waitForApnsToken();

      if (apnsToken != null) {
        token = await _messaging.getToken();
      } else {
        print('APNS token not ready yet');
      }
    } else {
      token = await _messaging.getToken();
    }

    print('FCM Token: $token');

    await _messingTokenRefresh();
  }

  Future<String?> _waitForApnsToken() async {
    String? apnsToken;

    for (int i = 0; i < 10; i++) {
      apnsToken = await _messaging.getAPNSToken();

      if (apnsToken != null) {
        return apnsToken;
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    return null;
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;

        if (payload != null) {
          // هنا تقدر تفتح صفحة معينة حسب payload
          // مثال: Get.toNamed('/challenge-details', arguments: payload);
        }
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _setupFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageClick(message);
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessageClick(initialMessage);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleMessageClick(RemoteMessage message) {
    final data = message.data;

    // مثال:
    // type = challenge
    // id = 15
    final type = data['type'];
    final id = data['id'];

    if (type == 'challenge') {
      // Get.toNamed('/challenge-details', arguments: id);
    } else if (type == 'subscription') {
      // Get.toNamed('/subscription');
    } else {
      // Get.toNamed('/notifications');
    }
  }

  Future<void> _messingTokenRefresh() async {
    _messaging.onTokenRefresh.listen((newToken) {
      // حدث التوكن في backend
      // await api.updateFcmToken(newToken);
    });
  }
}

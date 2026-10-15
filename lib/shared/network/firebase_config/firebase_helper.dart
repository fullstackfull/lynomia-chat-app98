import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../local/cache_helper.dart';
import '../../../shared/styles/lyn_palette.dart';

// ============================================
// Handler للخلفية (Background)
// ============================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print('📲 Background Message received!');
  print('Notification: ${message.notification?.title}');
  print('Data: ${message.data}');

  // ✅ عرض Heads-up Notification
  if (message.notification != null) {
    await FirebaseHelper.showHeadsUpNotification(
      title: message.notification!.title ?? 'رسالة جديدة',
      body: message.notification!.body ?? '',
      data: message.data,
    );
  } else if (message.data.isNotEmpty) {
    await FirebaseHelper.showHeadsUpNotification(
      title: message.data['title'] ?? 'رسالة جديدة',
      body: message.data['body'] ?? '',
      data: message.data,
    );
  }
}

// ============================================
// Firebase Helper
// ============================================
class FirebaseHelper {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// تهيئة كل شيء
  static Future<void> init() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initLocalNotifications();
    await _requestPermissions();
    await _createNotificationChannel();
    _listenToForegroundMessages();
    _listenToNotificationOpened();

    _initialized = true;
    print('✅ Firebase Helper Initialized');
  }

  /// تهيئة Local Notifications
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 Notification tapped: ${response.payload}');
      },
    );
  }

  /// طلب الإذن
  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// إنشاء قناة Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'chat_channel_id',
      'Chat Notifications',
      description: 'Notifications for chat messages',
      importance: Importance.max,  // ✅ أقصى أهمية
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// الاستماع للمقدمة (Foreground)
  static void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 FOREGROUND MESSAGE!');

      final title = message.notification?.title ?? message.data['title'] ?? 'رسالة جديدة';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      showHeadsUpNotification(title: title, body: body, data: message.data);
    });
  }

  /// الاستماع لفتح الإشعار
  static void _listenToNotificationOpened() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Opened from background');
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📲 Opened from terminated');
      }
    });
  }

  /// ✅ Heads-up Notification (منبثق مثل WhatsApp)
  static Future<void> showHeadsUpNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'chat_channel_id',
      'Chat Notifications',
      channelDescription: 'Notifications for chat messages',

      // ✅ إعدادات Heads-up:
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'New message',
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: true,
      fullScreenIntent: true,           // ✅ يظهر فوق كل شيء
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),

      // ✅ نص كبير:
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'New message',
      ),

      color: LynPalette.indigo,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: data.toString(),
    );

    print('✅ Heads-up notification shown');
  }

  /// الحصول على FCM Token
  static Future<String?> getFCMToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await CacheHelper.saveData(key: 'fcm_token', value: token);
    }
    return token;
  }

  static void listenToTokenRefresh(Function(String) onRefresh) {
    _messaging.onTokenRefresh.listen((newToken) {
      CacheHelper.saveData(key: 'fcm_token', value: newToken);
      onRefresh(newToken);
    });
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _isInitialized = false;

Future<void> requestSystemNotificationPermissionImpl() async {
  if (_isInitialized) return;

  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Request Android 13+ Notification Permission
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _isInitialized = true;
  } catch (e) {
    if (kDebugMode) print('Local notification init error: $e');
  }
}

Future<void> showSystemNotificationImpl({
  required String title,
  required String body,
}) async {
  if (!_isInitialized) {
    await requestSystemNotificationPermissionImpl();
  }

  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'duochat_messages_channel',
      'DuoChat Messages',
      channelDescription: 'Real-time 2-person text chat notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      ticker: 'DuoChat message received',
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  } catch (e) {
    if (kDebugMode) print('Local notification show error: $e');
  }
}

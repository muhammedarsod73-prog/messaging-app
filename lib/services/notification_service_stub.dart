import 'dart:typed_data';
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
    final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'duochat_high_importance_channel',
      'DuoChat Incoming Messages',
      channelDescription: 'Real-time text message alerts with sound & vibration',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      ticker: 'DuoChat message received',
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
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

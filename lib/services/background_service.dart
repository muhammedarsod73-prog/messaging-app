import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class BackgroundServiceHandler {
  static Future<void> initializeService() async {
    if (kIsWeb) return;

    try {
      // 1. Silent channel for background service indicator badge
      const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
        'duochat_foreground_service_channel',
        'DuoChat Background Service',
        description: 'DuoChat background connection indicator',
        importance: Importance.low,
      );

      // 2. High-Importance channel with vibration and sound for incoming text messages
      const AndroidNotificationChannel messageChannel = AndroidNotificationChannel(
        'duochat_high_importance_channel',
        'DuoChat Incoming Messages',
        description: 'Real-time text message alerts with sound & vibration',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(serviceChannel);
      await androidPlugin?.createNotificationChannel(messageChannel);

      // 3. Configure Foreground Service with serviceChannel
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStartBackgroundService,
          autoStart: true,
          autoStartOnBoot: true,
          isForegroundMode: true,
          notificationChannelId: 'duochat_foreground_service_channel',
          initialNotificationTitle: 'DuoChat Active',
          initialNotificationContent: 'Monitoring private messages...',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStartBackgroundService,
          onBackground: onIosBackground,
        ),
      );

      await service.startService();
    } catch (e) {
      if (kDebugMode) print('Background service config note: $e');
    }
  }
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStartBackgroundService(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  try {
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageService(prefs);

    await SupabaseService.init();

    if (SupabaseService.isConfigured) {
      final supabase = SupabaseService();
      final pairCode = storage.getPairCode();
      final currentUserId = storage.getCurrentUserId();

      supabase.subscribeToMessages(
        pairCode: pairCode,
        onNewMessage: (MessageModel msg) async {
          // Skip WebRTC call signaling payloads from text cache and text notifications
          if (msg.content.startsWith('[CALL_SIGNAL]:')) {
            return;
          }

          // 1. Save to local cache so main UI thread sees it immediately on resume
          final currentMsgs = storage.getCachedMessages();
          if (!currentMsgs.any((m) => m.id == msg.id)) {
            currentMsgs.add(msg);
            await storage.saveCachedMessages(currentMsgs);
          }

          // 2. Broadcast to main UI thread if active
          service.invoke('new_message_background', msg.toJson());

          // 3. Show System Notification
          if (msg.receiverId == currentUserId) {
            NotificationService.showSystemNotification(
              title: storage.getPartnerName(),
              body: msg.content,
            );
          }
        },
        onUpdateMessage: (_) {},
        onDeleteAllMessages: () async {
          // Clear local storage cache when partner clears chat from background
          await storage.saveCachedMessages([]);
        },
      );
    }
  } catch (e) {
    if (kDebugMode) print('Background service error: $e');
  }
}

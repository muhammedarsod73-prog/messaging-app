import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<void> requestSystemNotificationPermissionImpl() async {
  try {
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  } catch (e) {
    if (kDebugMode) print('Web Notification request error: $e');
  }
}

Future<void> showSystemNotificationImpl({
  required String title,
  required String body,
}) async {
  try {
    if (html.Notification.permission == 'granted') {
      // Use ServiceWorker showNotification so Android OS puts it in the pull-down status bar shade
      final swReg = html.window.navigator.serviceWorker;
      if (swReg != null) {
        final registration = await swReg.ready;
        if (registration != null) {
          registration.showNotification(
            title,
            {
              'body': body,
              'icon': 'icons/Icon-192.png',
              'badge': 'icons/Icon-192.png',
              'tag': 'duochat-msg',
              'renotify': true,
            },
          );
          return;
        }
      }

      // Fallback standard HTML notification
      html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png',
      );
    } else if (html.Notification.permission != 'denied') {
      final perm = await html.Notification.requestPermission();
      if (perm == 'granted') {
        html.Notification(
          title,
          body: body,
          icon: 'icons/Icon-192.png',
        );
      }
    }
  } catch (e) {
    if (kDebugMode) print('Web System Notification error: $e');
  }
}

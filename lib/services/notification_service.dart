import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';

class NotificationService {
  static Future<void> requestPermission() async {
    await requestSystemNotificationPermissionImpl();
  }

  static Future<void> showSystemNotification({
    required String title,
    required String body,
  }) async {
    await showSystemNotificationImpl(
      title: title,
      body: body,
    );
  }
}

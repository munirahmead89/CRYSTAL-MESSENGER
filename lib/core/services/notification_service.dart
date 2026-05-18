import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'permission_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // Request permissions
      await PermissionService.requestNotificationPermission();

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  Future<void> showMessage(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('chat', 'Chat'),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(0, title, body, details);
  }
}

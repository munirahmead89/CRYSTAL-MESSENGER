import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
  }

  Future<void> showMessage(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('chat', 'Chat'),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(0, title, body, details);
  }
}

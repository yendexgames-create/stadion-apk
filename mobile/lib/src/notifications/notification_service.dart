import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _plugin.initialize(init);

    _inited = true;
  }

  static Future<void> showPenalty({
    required String title,
    required String body,
  }) async {
    if (!_inited) await init();

    const androidDetails = AndroidNotificationDetails(
      'penalties',
      'Jarimalar',
      channelDescription: 'Yangi jarima bo‘lsa xabar beradi',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1, // bitta kanal uchun bitta id yetarli
      title,
      body,
      details,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/notifications/notification_service.dart';
import 'src/storage/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final shared = await SharedPreferences.getInstance();
  final prefs = Prefs(shared);
  runApp(App(prefs: prefs));
}

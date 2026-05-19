import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/storage/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final shared = await SharedPreferences.getInstance();
  final prefs = Prefs(shared);
  runApp(App(prefs: prefs));
}

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../settings/settings_screen.dart';
import 'admin_screen.dart';

/// Faqat admin bo‘lib kirilgan holat (user OTP bo‘lmasa ham).
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state: state))),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async => state.logoutAdmin(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AdminScreen(state: state),
    );
  }
}


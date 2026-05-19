import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../settings/settings_screen.dart';
import 'admin_schedule_screen.dart';
import 'admin_screen.dart';

/// Faqat admin bo‘lib kirilgan holat (user OTP bo‘lmasa ham).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.state});

  final AppState state;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminScheduleScreen(state: widget.state),
      AdminPenaltiesScreen(state: widget.state),
    ];

    final titles = ['Jadval', 'Jarimalar'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin • ${titles[_index]}'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state: widget.state))),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              await widget.state.logoutAdmin();
              if (!mounted) return;
              setState(() => _index = 0);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.table_chart), label: 'Jadval'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Jarimalar'),
        ],
      ),
    );
  }
}

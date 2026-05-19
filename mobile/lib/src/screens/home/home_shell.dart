import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../bookings/my_bookings_screen.dart';
import '../profile/profile_screen.dart';
import '../slots/slots_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.state,
    required this.settingsBuilder,
  });

  final AppState state;
  final Widget Function() settingsBuilder;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      SlotsScreen(state: widget.state),
      MyBookingsScreen(state: widget.state),
      ProfileScreen(state: widget.state),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stadion bron'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget.settingsBuilder()));
              if (!mounted) return;
              setState(() {});
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              await widget.state.logoutAdmin();
              await widget.state.logoutUser();
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
          NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'Slotlar'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Bronlarim'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

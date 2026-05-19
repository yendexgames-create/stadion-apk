import 'package:flutter/material.dart';

import 'screens/admin/admin_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/settings/settings_screen.dart';
import 'state/app_state.dart';
import 'storage/prefs.dart';

class App extends StatefulWidget {
  const App({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppState state;

  @override
  void initState() {
    super.initState();
    state = AppState(widget.prefs);
    state.init();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B8F3A), // "stadion green"
          brightness: Brightness.dark,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Stadion bron',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: const Color(0xFF06150B),
            appBarTheme: const AppBarTheme(centerTitle: false),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withOpacity(0.65),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: scheme.surfaceContainerHighest.withOpacity(0.55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: scheme.surface.withOpacity(0.35),
              indicatorColor: scheme.primary.withOpacity(0.22),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
          home: Builder(
            builder: (context) {
              if (!state.hasBaseUrl) return SettingsScreen(state: state);
              if (!state.isUserLoggedIn && state.isAdminLoggedIn) return AdminShell(state: state);
              if (!state.isUserLoggedIn) return AuthScreen(state: state);
              return HomeShell(
                state: state,
                adminBuilder: () => AdminScreen(state: state),
                settingsBuilder: () => SettingsScreen(state: state),
              );
            },
          ),
        );
      },
    );
  }
}

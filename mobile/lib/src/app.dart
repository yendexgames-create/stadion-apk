import 'package:flutter/material.dart';

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
  int _shownUpdateCode = 0;

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
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
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
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: scheme.surface.withValues(alpha: 0.35),
              indicatorColor: scheme.primary.withValues(alpha: 0.22),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
          home: Builder(
            builder: (context) {
              // Base URL endi default orqali avtomatik beriladi.
              // (Agar developer URL'ni o‘zgartirmoqchi bo‘lsa, Settings orqali qo‘lda saqlab qo‘yishi mumkin.)
              final u = state.update;
              if (u != null && u.versionCode != _shownUpdateCode) {
                _shownUpdateCode = u.versionCode;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Yangilanish bor'),
                        content: Text('Yangi versiya mavjud: v${u.versionName}'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keyinroq')),
                          FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await state.startUpdate();
                            },
                            child: const Text('Yangilash'),
                          ),
                        ],
                      );
                    },
                  );
                  state.dismissUpdate();
                });
              }
              if (!state.isUserLoggedIn && state.isAdminLoggedIn) return AdminShell(state: state);
              if (!state.isUserLoggedIn) return AuthScreen(state: state);
              return HomeShell(
                state: state,
                settingsBuilder: () => SettingsScreen(state: state),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final me = state.me;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telefon: ${me?.phone ?? ''}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Ism: ${me?.name ?? ''}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('GamesCount: ${me?.gamesCount ?? 0}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await state.refreshMe();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(state.prettyError(e))));
                }
              },
              child: const Text('Yangilash'),
            ),
          ),
        ],
      ),
    );
  }
}

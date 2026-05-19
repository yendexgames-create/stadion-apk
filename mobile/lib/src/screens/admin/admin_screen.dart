import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../state/app_state.dart';

/// Admin: Jarimalar ro‘yxati (login AuthScreen’da qilinadi).
class AdminPenaltiesScreen extends StatefulWidget {
  const AdminPenaltiesScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AdminPenaltiesScreen> createState() => _AdminPenaltiesScreenState();
}

class _AdminPenaltiesScreenState extends State<AdminPenaltiesScreen> {
  Future<List<PenaltyItem>>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.getPenalties();
  }

  void _load() {
    _future = widget.state.getPenalties();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return Center(
        child: FilledButton(
          onPressed: _load,
          child: const Text('Jarimalarni yuklash'),
        ),
      );
    }

    return FutureBuilder<List<PenaltyItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(widget.state.prettyError(snap.error!)));
        }
        final items = snap.data ?? const [];
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.separated(
            itemCount: items.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == 0) {
                return ListTile(
                  title: const Text('Jarimalar'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                    ],
                  ),
                );
              }
              final p = items[i - 1];
              final u = p.user;
              return ListTile(
                title: Text('${p.amount} so‘m • ${p.date} ${p.startTime}'),
                subtitle: Text(u == null ? '' : '${u.name} ${u.phone}'),
              );
            },
          ),
        );
      },
    );
  }
}

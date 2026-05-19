import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../state/app_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  Future<List<PenaltyItem>>? _future;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Siz bergan admin telefonni default qilib qo‘yamiz (xohlasangiz o‘zgartirasiz).
    _phone.text = '+998970986226';
    if (widget.state.isAdminLoggedIn) {
      _future = widget.state.getPenalties();
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _load() {
    _future = widget.state.getPenalties();
    setState(() {});
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.state.adminLogin(phone: _phone.text.trim(), password: _password.text);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = widget.state.prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.isAdminLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Admin telefon', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Parol', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _loading ? null : _login, child: const Text('Kirish')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      );
    }
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
                      IconButton(
                        onPressed: () async {
                          await widget.state.logoutAdmin();
                          if (!mounted) return;
                          setState(() {
                            _future = null;
                            _error = null;
                          });
                        },
                        icon: const Icon(Icons.logout),
                      ),
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

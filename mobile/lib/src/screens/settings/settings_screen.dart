import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../state/app_state.dart';
import 'changelog_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _baseUrl;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _baseUrl = TextEditingController(text: widget.state.baseUrl ?? '');
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    super.dispose();
  }

  String _normalizeBaseUrl(String v) {
    var s = v.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _testResult = null;
    });
    try {
      await widget.state.setBaseUrl(_normalizeBaseUrl(_baseUrl.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlandi')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    final base = _normalizeBaseUrl(_baseUrl.text);
    if (base.isEmpty) {
      setState(() => _testResult = 'Base URL bo‘sh');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final u = Uri.parse('$base/health');
      final r = await http.get(u).timeout(const Duration(seconds: 6));
      setState(() => _testResult = 'health: ${r.statusCode} ${r.body}');
    } catch (e) {
      setState(() => _testResult = 'Xato: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backend manzili (baseUrl)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrl,
                    decoration: const InputDecoration(
                      labelText: 'Masalan: http://10.0.2.2:8080',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Saqlash'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testing ? null : _test,
                          icon: const Icon(Icons.health_and_safety),
                          label: const Text('Test'),
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Text(_testResult!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.new_releases),
                  title: const Text('Yangilanishlar'),
                  subtitle: const Text('Oxirgi o‘zgartirishlar ro‘yxati'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangelogScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


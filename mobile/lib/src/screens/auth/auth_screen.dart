import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import '../settings/settings_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  bool _adminMode = false;
  bool _requested = false;
  bool _loading = false;
  String? _error;

  Future<void> _openTelegramBot() async {
    const username = 'stadiontop_bot';
    final tg = Uri.parse('tg://resolve?domain=$username');
    final web = Uri.parse('https://t.me/$username');
    try {
      // Avval Telegram app'ni ochishga harakat qilamiz.
      final ok = await launchUrl(tg, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch {
      // ignore
    }
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.state.requestOtp(name: _name.text.trim(), phone: _phone.text.trim());
      if (!mounted) return;
      setState(() => _requested = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = widget.state.prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _adminLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.state.adminLogin(phone: _phone.text.trim(), password: _name.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = widget.state.prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.state.verifyOtp(phone: _phone.text.trim(), code: _code.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = widget.state.prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneOk = _phone.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirish'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state: widget.state))),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF062B14), Color(0xFF06150B)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sports_soccer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stadion bron',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _phone,
                        decoration: const InputDecoration(labelText: 'Telefon (+998...)', prefixIcon: Icon(Icons.phone)),
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (!_adminMode && !_requested && phoneOk) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _openTelegramBot,
                            icon: const Icon(Icons.send),
                            label: const Text('@stadiontop_bot ga o‘tish (kontakt yuborish)'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Eslatma: OTP uchun botga kirib kontakt yuborilgan bo‘lishi kerak.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: _adminMode,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Admin rejimi'),
                        subtitle: const Text('Admin bo‘lib kirish (parol bilan)'),
                        onChanged: _loading
                            ? null
                            : (v) {
                                setState(() {
                                  _adminMode = v;
                                  _requested = false;
                                  _code.clear();
                                  _error = null;
                                });
                              },
                      ),
                      const SizedBox(height: 6),
                      if (!_requested || _adminMode) ...[
                        TextField(
                          controller: _name,
                          decoration: InputDecoration(labelText: _adminMode ? 'Admin parol' : 'Ism'),
                          obscureText: _adminMode,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : (_adminMode ? _adminLogin : _request),
                            child: Text(_adminMode ? 'Admin kirish' : 'Kod so‘rash'),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _code,
                          decoration: const InputDecoration(
                            labelText: 'SMS/Telegram kod (6 xonali)',
                            prefixIcon: Icon(Icons.password),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _openTelegramBot,
                            icon: const Icon(Icons.send),
                            label: const Text('Kod botda (ochish)'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _verify,
                            child: const Text('Tasdiqlash'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _requested = false;
                                      _code.clear();
                                    });
                                  },
                            child: const Text('Boshidan'),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_adminMode && !_requested)
                Text(
                  'Qadamlar: 1) Botga o‘ting va kontakt yuboring  2) Ilovada “Kod so‘rash”  3) Botdan kelgan kodni kiriting.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

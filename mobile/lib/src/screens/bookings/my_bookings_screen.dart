import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../state/app_state.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  Future<MyBookingsResponse>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.state.getMyBookings();
    setState(() {});
  }

  Future<void> _cancelDaily(MyDailyBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kunlik bron'),
        content: Text('${b.date} ${b.startTime}\nBekor qilinsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo‘q')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ha')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.state.cancelDaily(b.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.prettyError(e))));
    }
  }

  Future<void> _cancelSeries(MyWeeklySeries s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haftalik bron'),
        content: Text('${s.startDate} → ${s.endDate} ${s.startTime}\nBekor qilinsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo‘q')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ha')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.state.cancelWeeklySeries(s.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.prettyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyBookingsResponse>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(widget.state.prettyError(snap.error!)));
        }
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            children: [
              ListTile(
                title: const Text('Kunlik bronlar'),
                trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ),
              if (data.daily.isEmpty) const ListTile(title: Text('Yo‘q')),
              for (final b in data.daily)
                ListTile(
                  title: Text('${b.date} ${b.startTime}-${b.endTime}'),
                  trailing: OutlinedButton(onPressed: () => _cancelDaily(b), child: const Text('Bekor')),
                ),
              const Divider(),
              const ListTile(title: Text('Haftalik bronlar (seriya)')),
              if (data.weekly.isEmpty) const ListTile(title: Text('Yo‘q')),
              for (final s in data.weekly)
                ListTile(
                  title: Text('${s.startDate} → ${s.endDate}'),
                  subtitle: Text('${s.startTime}-${s.endTime}'),
                  trailing: OutlinedButton(onPressed: () => _cancelSeries(s), child: const Text('Bekor')),
                ),
            ],
          ),
        );
      },
    );
  }
}


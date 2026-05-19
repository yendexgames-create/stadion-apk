import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../state/app_state.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  late DateTime _date;
  Future<SlotsResponse>? _future;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _load();
  }

  String get _ymd {
    final y = _date.year.toString().padLeft(4, '0');
    final m = _date.month.toString().padLeft(2, '0');
    final d = _date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _load() {
    _future = widget.state.getSlots(_ymd);
    setState(() {});
  }

  void _addDays(int days) {
    _date = _date.add(Duration(days: days));
    _load();
  }

  Future<void> _book(SlotItem s) async {
    final kind = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.startTime),
        content: const Text('Qaysi tur?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.of(context).pop('daily'), child: const Text('Kunlik')),
          FilledButton(onPressed: () => Navigator.of(context).pop('weekly'), child: const Text('Haftalik')),
        ],
      ),
    );
    if (kind == null) return;

    try {
      if (kind == 'daily') {
        await widget.state.createDaily(dateYmd: _ymd, startTime: s.startTime);
      } else {
        await widget.state.createWeekly(startDateYmd: _ymd, startTime: s.startTime);
      }
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bron qilindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.prettyError(e))));
    }
  }

  Future<void> _cancelDaily(SlotItem s) async {
    final id = s.bookingId;
    if (id == null || id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bekor qilinsinmi?'),
        content: const Text('Bugungi bron bo‘lsa jarima yozilishi mumkin.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo‘q')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ha')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.state.cancelDaily(id);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bekor qilindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.prettyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(onPressed: () => _addDays(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(child: Center(child: Text(_ymd, style: Theme.of(context).textTheme.titleMedium))),
              IconButton(onPressed: () => _addDays(1), icon: const Icon(Icons.chevron_right)),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<SlotsResponse>(
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
                child: ListView.separated(
                  itemCount: data.slots.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = data.slots[i];
                    final isFree = s.status == 'free';
                    final isMine = s.mine;
                    final subtitle = isFree
                        ? 'Bo‘sh'
                        : isMine
                            ? 'Mening bronim'
                            : 'Band';
                    return ListTile(
                      title: Text('${s.startTime} - ${s.endTime}'),
                      subtitle: Text(subtitle),
                      trailing: isFree
                          ? FilledButton(onPressed: () => _book(s), child: const Text('Bron'))
                          : (isMine && (s.bookingType == 'daily'))
                              ? OutlinedButton(onPressed: () => _cancelDaily(s), child: const Text('Bekor'))
                              : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

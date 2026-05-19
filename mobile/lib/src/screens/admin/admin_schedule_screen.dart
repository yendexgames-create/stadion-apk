import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../state/app_state.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  late DateTime _weekStart;
  Future<AdminScheduleResponse>? _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Dushanba = 1
    _weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _load();
  }

  String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  void _load() {
    _future = widget.state.getAdminSchedule(_ymd(_weekStart));
    setState(() {});
  }

  void _shiftWeek(int weeks) {
    _weekStart = _weekStart.add(Duration(days: 7 * weeks));
    _load();
  }

  String _weekdayUz(int weekday) {
    // DateTime: 1..7 (Mon..Sun)
    const names = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              IconButton(onPressed: () => _shiftWeek(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Center(
                  child: Text(
                    'Hafta: ${_ymd(_weekStart)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(onPressed: () => _shiftWeek(1), icon: const Icon(Icons.chevron_right)),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<AdminScheduleResponse>(
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

              final days = data.days;
              final times = days.isEmpty ? <AdminScheduleSlot>[] : days.first.slots;

              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Soat')),
                        for (int i = 0; i < days.length; i++)
                          DataColumn(
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_weekdayUz(_weekStart.add(Duration(days: i)).weekday)),
                                Text(days[i].date, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                      ],
                      rows: [
                        for (int r = 0; r < times.length; r++)
                          DataRow(
                            cells: [
                              DataCell(Text('${times[r].startTime}\n${times[r].endTime}', style: Theme.of(context).textTheme.bodySmall)),
                              for (int c = 0; c < days.length; c++)
                                _cell(context, days[c].slots[r]),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  DataCell _cell(BuildContext context, AdminScheduleSlot s) {
    if (s.status == 'free') {
      return DataCell(Text('Bo‘sh', style: Theme.of(context).textTheme.bodySmall));
    }
    final u = s.user;
    final who = u == null ? '' : '${u.name}\n${u.phone}';
    final type = s.bookingType == null ? '' : (s.bookingType == 'weekly' ? 'Haftalik' : 'Kunlik');
    return DataCell(
      Text(
        'Band\n$type\n$who',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}


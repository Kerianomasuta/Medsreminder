import 'package:flutter/material.dart';

import '../../controllers/medication_logs_controller.dart';
import '../../models/medication_log.dart';
import '../../widgets/widgets.dart';

class MedicationLogTimelinePage extends StatefulWidget {
  const MedicationLogTimelinePage({super.key, this.controller, this.patientId});

  final MedicationLogsController? controller;
  final String? patientId;

  @override
  State<MedicationLogTimelinePage> createState() =>
      _MedicationLogTimelinePageState();
}

class _MedicationLogTimelinePageState extends State<MedicationLogTimelinePage> {
  late final MedicationLogsController _controller =
      widget.controller ?? MedicationLogsController();
  late final bool _ownsController = widget.controller == null;
  int _selectedDay = DateTime.now().weekday;

  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() =>
      _controller.loadRange(_weekStart, _weekEnd, patientId: widget.patientId);

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  bool _isSelectedDate(DateTime date) {
    final selected = _weekStart.add(Duration(days: _selectedDay - 1));
    return date.year == selected.year &&
        date.month == selected.month &&
        date.day == selected.day;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final dayLogs = _controller.logs
          .where((item) => _isSelectedDate(item.scheduledAt))
          .toList();
      final counts = <int, int>{
        for (var weekday = 1; weekday <= 7; weekday++)
          weekday: _controller.logs.where((item) {
            final date = _weekStart.add(Duration(days: weekday - 1));
            return item.scheduledAt.year == date.year &&
                item.scheduledAt.month == date.month &&
                item.scheduledAt.day == date.day;
          }).length,
      };
      final selectedDate = _weekStart.add(Duration(days: _selectedDay - 1));

      return AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PageIntro(
                  'Lịch uống thuốc',
                  'Trạng thái các cữ trong tuần',
                ),
                IconButton(
                  onPressed: _controller.loading ? null : _load,
                  tooltip: 'Làm mới',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF5167F2),
                  ),
                ),
              ],
            ),
            DayStrip(
              selectedDay: _selectedDay,
              badgeCounts: counts,
              onDaySelected: (value) => setState(() => _selectedDay = value),
            ),
            const SizedBox(height: 18),
            Text(
              'Ngày ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (_controller.loading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.loadError != null)
              Glass(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      _controller.loadError!,
                      style: const TextStyle(color: Color(0xFFD65D4A)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else if (dayLogs.isEmpty)
              const Glass(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Không có cữ thuốc trong ngày này.')),
              )
            else
              ...dayLogs.map((log) => _TimelineLogCard(log: log)),
          ],
        ),
      );
    },
  );
}

class _TimelineLogCard extends StatelessWidget {
  const _TimelineLogCard({required this.log});

  final MedicationLog log;

  @override
  Widget build(BuildContext context) {
    final color = switch (log.status) {
      DoseStatus.scheduled => const Color(0xFF5065F2),
      DoseStatus.snoozed => const Color(0xFFF0A042),
      DoseStatus.taken => const Color(0xFF239E77),
      DoseStatus.skipped => const Color(0xFF8B6BC4),
      DoseStatus.missed => const Color(0xFFD65D4A),
    };
    final amount = log.dosagePerTime;
    final time = log.effectiveReminderAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              width: 7,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.medicine?.name ?? 'Thuốc',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${amount == null ? '' : '${amount == amount.roundToDouble() ? amount.toInt() : amount} ${log.medicine?.unit ?? ''}'}'
                    '${log.instructions == null ? '' : ' · ${log.instructions}'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(log.status.label, color),
          ],
        ),
      ),
    );
  }
}

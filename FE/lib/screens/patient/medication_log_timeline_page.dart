import 'package:flutter/material.dart';

import '../../controllers/medication_logs_controller.dart';
import '../../models/medication_log.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_api.dart';
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

  Future<void> _load() async {
    await _controller.loadRange(_weekStart, _weekEnd, patientId: widget.patientId);
    try {
      await NotificationService.instance.refreshUpcomingMedicationLogs();
    } catch (_) {}
  }

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

  void _openScheduleDetails(MedicationLog log) {
    if (log.scheduleRuleId.isEmpty) return;
    showScheduleDetailsModal(
      context,
      scheduleId: log.scheduleRuleId,
      onUpdated: _load,
    );
  }

  Future<void> _openScheduleEdit(MedicationLog log) async {
    if (log.scheduleRuleId.isEmpty) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5065F2)),
        ),
      );
      final rule = await ScheduleApi().getById(log.scheduleRuleId);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      showScheduleEditModal(
        context,
        rule: rule,
        onUpdated: _load,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin cữ thuốc: $e')),
        );
      }
    }
  }

  Future<void> _openAddScheduleFor(MedicationLog log) async {
    if (log.scheduleRuleId.isEmpty) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5065F2)),
        ),
      );
      final rule = await ScheduleApi().getById(log.scheduleRuleId);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      showAddScheduleModal(
        context,
        prescriptionItemId: rule.prescriptionItemId,
        medicineName: rule.medicine.name,
        prescriptionTitle: rule.prescription.title,
        onCreated: _load,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin thuốc: $e')),
        );
      }
    }
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
              ...dayLogs.map(
                (log) => _TimelineLogCard(
                  log: log,
                  onOpenDetails: () => _openScheduleDetails(log),
                  onAddSchedule: () => _openAddScheduleFor(log),
                  onEditSchedule: () => _openScheduleEdit(log),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _TimelineLogCard extends StatelessWidget {
  const _TimelineLogCard({
    required this.log,
    required this.onOpenDetails,
    required this.onAddSchedule,
    required this.onEditSchedule,
  });

  final MedicationLog log;
  final VoidCallback onOpenDetails;
  final VoidCallback onAddSchedule;
  final VoidCallback onEditSchedule;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpenDetails,
          child: Glass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(log.status.label, color),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Thêm cữ thuốc',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: onAddSchedule,
                          icon: const Icon(
                            Icons.alarm_add_rounded,
                            color: Color(0xFF5065F2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Chỉnh sửa lịch uống',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: onEditSchedule,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF526DB1),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

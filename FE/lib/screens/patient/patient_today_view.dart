import 'package:flutter/material.dart';

import '../../models/schedule_rule.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_api.dart';
import '../../widgets/widgets.dart';

enum _TodayScheduleFilter { all, active, inactive }

class PatientTodayView extends StatefulWidget {
  const PatientTodayView({super.key, this.api, this.patientId});

  final ScheduleApi? api;
  final String? patientId;

  @override
  State<PatientTodayView> createState() => _PatientTodayViewState();
}

class _PatientTodayViewState extends State<PatientTodayView> {
  late final ScheduleApi _api = widget.api ?? ScheduleApi();
  List<ScheduleRule> _schedules = const [];
  bool _loading = true;
  String? _error;
  _TodayScheduleFilter _filter = _TodayScheduleFilter.active;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final schedules = await _api.list(patientId: widget.patientId);
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _loading = false;
      });
      await NotificationService.instance.refreshUpcomingMedicationLogs();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  bool _isInPrescriptionRange(ScheduleRule rule) {
    final start = DateTime.tryParse(rule.prescription.startDate ?? '');
    final end = DateTime.tryParse(rule.prescription.endDate ?? '');
    if (start != null &&
        _today.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    if (end != null && _today.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }
    return rule.prescription.isActive;
  }

  bool _matchesFilter(ScheduleRule rule) => switch (_filter) {
    _TodayScheduleFilter.all => true,
    _TodayScheduleFilter.active => rule.isActive,
    _TodayScheduleFilter.inactive => !rule.isActive,
  };

  DateTime _plannedAt(ScheduleRule rule) {
    final parts = rule.reminderTime.split(':');
    return DateTime(
      _today.year,
      _today.month,
      _today.day,
      int.tryParse(parts.first) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  void _openDetails(ScheduleRule rule) {
    showScheduleDetailsModal(
      context,
      scheduleId: rule.id,
      initialRule: rule,
      selectedDate: _today,
      onUpdated: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allToday = _schedules
        .where((rule) => rule.daysOfWeek.contains(_today.weekday))
        .where(_isInPrescriptionRange)
        .toList();
    final visible = allToday.where(_matchesFilter).toList()
      ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    final now = DateTime.now();
    final upcoming =
        allToday
            .where((rule) => rule.isActive && _plannedAt(rule).isAfter(now))
            .toList()
          ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    final next = upcoming.isEmpty ? null : upcoming.first;

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PageIntro(
                'Lịch uống hôm nay',
                'Thời gian luôn được cập nhật từ lịch uống thuốc',
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                tooltip: 'Làm mới',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF5167F2),
                ),
              ),
            ],
          ),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF5368F4), Color(0xFF8068DD)],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_today.day} tháng ${_today.month}, ${_today.year}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _loading
                            ? 'Đang cập nhật...'
                            : '${allToday.where((item) => item.isActive).length} cữ đang bật',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _filterBar(),
          const SizedBox(height: 20),
          const Text(
            'Cữ thuốc tiếp theo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_loading && _schedules.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_error != null && _schedules.isEmpty)
            _ErrorCard(message: _error!, onRetry: _load)
          else if (next != null)
            _ScheduleCard(
              rule: next,
              emphasized: true,
              onTap: () => _openDetails(next),
            )
          else
            const Glass(
              padding: EdgeInsets.all(18),
              child: Center(
                child: Text('Không còn cữ đang bật trong hôm nay.'),
              ),
            ),
          const SizedBox(height: 22),
          Text(
            'Các lịch uống hôm nay (${visible.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (!_loading && visible.isEmpty && _error == null)
            const Glass(
              padding: EdgeInsets.all(18),
              child: Center(child: Text('Không có lịch phù hợp bộ lọc.')),
            )
          else
            ...visible.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScheduleCard(
                  rule: rule,
                  onTap: () => _openDetails(rule),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _filterBar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _filterChip(_TodayScheduleFilter.all, 'Tất cả'),
        const SizedBox(width: 8),
        _filterChip(_TodayScheduleFilter.active, 'Đang bật'),
        const SizedBox(width: 8),
        _filterChip(_TodayScheduleFilter.inactive, 'Đã tắt'),
      ],
    ),
  );

  Widget _filterChip(_TodayScheduleFilter value, String label) => FilterChip(
    key: ValueKey('today-status-${value.name}'),
    label: Text(label),
    selected: _filter == value,
    onSelected: (_) => setState(() => _filter = value),
    selectedColor: const Color(0xFFE7E9FF),
    checkmarkColor: const Color(0xFF3F51C7),
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.rule,
    required this.onTap,
    this.emphasized = false,
  });

  final ScheduleRule rule;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = rule.isActive
        ? const Color(0xFF5065F2)
        : const Color(0xFF94A3B8);
    final amount = rule.dosagePerTime == rule.dosagePerTime.roundToDouble()
        ? rule.dosagePerTime.toInt().toString()
        : rule.dosagePerTime.toString();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Glass(
        padding: EdgeInsets.all(emphasized ? 18 : 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_rounded, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.medicine.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${rule.displayTime} · $amount ${rule.medicine.unit}'
                    '${rule.instructions == null ? '' : ' · ${rule.instructions}'}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            StatusChip(rule.isActive ? 'Đang bật' : 'Đã tắt', color),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(message, style: const TextStyle(color: Color(0xFFD65D4A))),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_api.dart';
import '../../widgets/widgets.dart';

enum ScheduleStatusFilter { all, active, inactive }

class ScheduleTimelinePage extends StatefulWidget {
  const ScheduleTimelinePage({super.key, this.patientId, this.api});

  final String? patientId;
  final ScheduleApi? api;

  @override
  State<ScheduleTimelinePage> createState() => _ScheduleTimelinePageState();
}

class _ScheduleTimelinePageState extends State<ScheduleTimelinePage> {
  late final _api = widget.api ?? ScheduleApi();
  List<ScheduleRule> _schedules = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedDay = DateTime.now().weekday; // 1 = T2, 2 = T3, ..., 7 = CN
  ScheduleStatusFilter _statusFilter = ScheduleStatusFilter.all;

  Iterable<ScheduleRule> get _statusFilteredSchedules => _schedules.where(
    (rule) => switch (_statusFilter) {
      ScheduleStatusFilter.all => true,
      ScheduleStatusFilter.active => rule.isActive,
      ScheduleStatusFilter.inactive => !rule.isActive,
    },
  );

  DateTime get _selectedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: _selectedDay - 1));
  }

  Map<int, int> get _countsByDay {
    final map = <int, int>{};
    for (var i = 1; i <= 7; i++) {
      map[i] = _statusFilteredSchedules
          .where((r) => r.daysOfWeek.contains(i))
          .length;
    }
    return map;
  }

  String get _selectedDayName {
    switch (_selectedDay) {
      case 1:
        return 'Thứ Hai (T2)';
      case 2:
        return 'Thứ Ba (T3)';
      case 3:
        return 'Thứ Tư (T4)';
      case 4:
        return 'Thứ Năm (T5)';
      case 5:
        return 'Thứ Sáu (T6)';
      case 6:
        return 'Thứ Bảy (T7)';
      case 7:
        return 'Chủ Nhật (CN)';
      default:
        return 'ngày đã chọn';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _api.list(patientId: widget.patientId);
      if (mounted) {
        setState(() {
          _schedules = items;
          _isLoading = false;
        });
        try {
          NotificationService.instance.refreshUpcomingMedicationLogs();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _periodColor(String period) {
    switch (period) {
      case 'Sáng':
        return const Color(0xFF5469F5);
      case 'Trưa':
        return const Color(0xFFF0A042);
      case 'Chiều':
        return const Color(0xFF259F78);
      case 'Tối':
      default:
        return const Color(0xFF9A72DB);
    }
  }

  /// Mở modal chi tiết lịch uống (Read-only)
  void _openScheduleDetails(ScheduleRule rule) {
    showScheduleDetailsModal(
      context,
      scheduleId: rule.id,
      initialRule: rule,
      selectedDate: _selectedDate,
      onUpdated: _loadSchedules,
    );
  }

  /// Mở modal chỉnh sửa lịch uống (gọi PATCH)
  void _openScheduleEdit(ScheduleRule rule) {
    showScheduleEditModal(context, rule: rule, onUpdated: _loadSchedules);
  }

  /// Mở modal thêm cữ uống cho thuốc (gọi POST)
  void _openAddScheduleFor(ScheduleRule rule) {
    showAddScheduleModal(
      context,
      prescriptionItemId: rule.prescriptionItemId,
      medicineName: rule.medicine.name,
      prescriptionTitle: rule.prescription.title,
      onCreated: _loadSchedules,
    );
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Hàng ngày (T2 - CN)';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'T2 - T6';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Cuối tuần (T7, CN)';
    }
    return 'Thứ: ${days.join(", ")}';
  }

  @override
  Widget build(BuildContext context) {
    final daySchedules =
        _statusFilteredSchedules
            .where((rule) => rule.daysOfWeek.contains(_selectedDay))
            .toList()
          ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PageIntro(
                'Lịch uống thuốc',
                'Theo dõi và chỉnh sửa cữ uống',
              ),
              IconButton(
                onPressed: _loadSchedules,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF5167F2),
                ),
                tooltip: 'Làm mới lịch uống',
              ),
            ],
          ),
          DayStrip(
            selectedDay: _selectedDay,
            onDaySelected: (day) {
              setState(() {
                _selectedDay = day;
              });
            },
            badgeCounts: _countsByDay,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip(
                  ScheduleStatusFilter.all,
                  'Tất cả',
                  Icons.filter_list_rounded,
                ),
                const SizedBox(width: 8),
                _statusChip(
                  ScheduleStatusFilter.active,
                  'Đang bật',
                  Icons.notifications_active_rounded,
                ),
                const SizedBox(width: 8),
                _statusChip(
                  ScheduleStatusFilter.inactive,
                  'Đã tắt',
                  Icons.notifications_off_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5167F2)),
              ),
            )
          else if (_errorMessage != null)
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFD32F2F),
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadSchedules,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (_schedules.isEmpty)
            const Glass(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF6B7492),
                      size: 36,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Chưa có lịch uống thuốc nào được cài đặt',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (daySchedules.isEmpty)
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5167F2).withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Color(0xFF5167F2),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không có cữ uống nào vào $_selectedDayName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Các thuốc được lên lịch vào những ngày khác trong tuần.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
              child: Row(
                children: [
                  Text(
                    'Lịch uống $_selectedDayName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5167F2).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${daySchedules.length} cữ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5167F2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...daySchedules.map((rule) {
              final color = _periodColor(rule.period);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _openScheduleDetails(rule),
                  borderRadius: BorderRadius.circular(16),
                  child: Glass(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.displayTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rule.period,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 8,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rule.medicine.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${rule.dosagePerTime.toInt()} ${rule.medicine.unit} · ${rule.instructions ?? "Sau ăn"}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_repeat_rounded,
                                    size: 13,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDays(rule.daysOfWeek),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusChip(
                              rule.isActive ? 'Đang bật' : 'Đã tắt',
                              rule.isActive ? color : const Color(0xFF94A3B8),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Thêm cữ thuốc',
                                  onPressed: () => _openAddScheduleFor(rule),
                                  icon: const Icon(
                                    Icons.alarm_add_rounded,
                                    color: Color(0xFF5065F2),
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Chỉnh sửa lịch uống',
                                  onPressed: () => _openScheduleEdit(rule),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF526DB1),
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
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(ScheduleStatusFilter value, String label, IconData icon) {
    final selected = _statusFilter == value;
    return FilterChip(
      key: ValueKey('schedule-status-${value.name}'),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? const Color(0xFF3F51C7) : const Color(0xFF64748B),
      ),
      label: Text(label),
      selectedColor: const Color(0xFFE7E9FF),
      checkmarkColor: const Color(0xFF3F51C7),
      side: BorderSide(
        color: selected ? const Color(0xFF6979EC) : const Color(0xFFD7DEEA),
      ),
    );
  }
}

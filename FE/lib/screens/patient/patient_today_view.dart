import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/schedule_api.dart';
import '../../widgets/widgets.dart';

class PatientTodayView extends StatefulWidget {
  const PatientTodayView({
    super.key,
    this.patientId = '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    required this.doseTaken,
    required this.doseMissed,
    required this.onTaken,
  });

  final String patientId;
  final bool doseTaken, doseMissed;
  final VoidCallback onTaken;

  @override
  State<PatientTodayView> createState() => _PatientTodayViewState();
}

class _PatientTodayViewState extends State<PatientTodayView> {
  final _api = ScheduleApi();
  List<ScheduleRule> _schedules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodaySchedules();
  }

  /// Gọi API GET /api/v1/schedule-rules?patientId=...
  Future<void> _loadTodaySchedules() async {
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

  /// Mở chi tiết cữ thuốc bằng cách gọi API GET /api/v1/schedule-rules/:id
  void _openScheduleDetails(ScheduleRule rule) {
    showScheduleDetailsModal(
      context,
      scheduleId: rule.id,
      initialRule: rule,
      onUpdated: _loadTodaySchedules,
    );
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${now.day} tháng ${now.month}, ${now.year}';
    final totalCount = _schedules.length;

    // Tìm cữ gần nhất (mặc định lấy cữ đầu tiên nếu có)
    final upcomingDose = _schedules.isNotEmpty ? _schedules.first : null;

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PageIntro(
                'Chào buổi sáng, cô Lan',
                'Hôm nay là một ngày tuyệt vời',
              ),
              IconButton(
                onPressed: _loadTodaySchedules,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5167F2)),
                tooltip: 'Làm mới lịch hôm nay',
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
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFFFE39A),
                  size: 35,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateString,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _isLoading
                            ? 'Đang cập nhật lịch uống...'
                            : 'Hôm nay có $totalCount liều thuốc',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (widget.doseMissed) const EmergencyPatientCard(),

          // Phần cữ thuốc cần uống gần nhất
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.doseTaken
                    ? 'Tuyệt vời, cô đã hoàn thành!'
                    : 'Cữ thuốc cần uống',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (upcomingDose != null)
                TextButton.icon(
                  onPressed: () => _openScheduleDetails(upcomingDose),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Xem chi tiết'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF5065F2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (upcomingDose != null)
            InkWell(
              onTap: () => _openScheduleDetails(upcomingDose),
              borderRadius: BorderRadius.circular(20),
              child: Glass(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5E8FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            color: Color(0xFF5167F2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${upcomingDose.period} · ${upcomingDose.medicine.name}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${upcomingDose.displayTime} · ${upcomingDose.instructions ?? "Sau khi ăn"}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7492),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          widget.doseTaken
                              ? 'Đã uống'
                              : widget.doseMissed
                                  ? 'Đã trễ'
                                  : 'Đến giờ',
                          widget.doseTaken
                              ? const Color(0xFF239E77)
                              : widget.doseMissed
                                  ? const Color(0xFFD65D4A)
                                  : const Color(0xFF5065F2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Liều lượng: ${upcomingDose.dosagePerTime.toInt()} ${upcomingDose.medicine.unit} (${upcomingDose.prescription.title})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: widget.onTaken,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        widget.doseTaken
                            ? 'Cô đã uống cữ này'
                            : 'Tôi đã uống đủ thuốc',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.doseTaken
                            ? const Color(0xFF249D76)
                            : const Color(0xFF5065F2),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            DoseCard(
              taken: widget.doseTaken,
              missed: widget.doseMissed,
              onTaken: widget.onTaken,
            ),

          const SizedBox(height: 20),

          // Danh sách tất cả cữ thuốc trong ngày từ API
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch các cữ thuốc hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Bấm để xem chi tiết',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5065F2)),
              ),
            )
          else if (_errorMessage != null)
            Glass(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Không thể tải lịch hôm nay: $_errorMessage',
                style: const TextStyle(color: Color(0xFFD32F2F)),
              ),
            )
          else if (_schedules.isEmpty)
            const Glass(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Không có cữ thuốc nào trong ngày hôm nay.'),
              ),
            )
          else
            ..._schedules.map((rule) {
              final color = _periodColor(rule.period);
              return InkWell(
                onTap: () => _openScheduleDetails(rule),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Glass(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Text(
                          rule.displayTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rule.medicine.name} (${rule.dosagePerTime.toInt()} ${rule.medicine.unit})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${rule.period} · ${rule.prescription.title} · ${rule.instructions ?? "Sau ăn"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          rule.isActive ? 'Đang bật' : 'Tắt',
                          rule.isActive ? color : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),
          const Text(
            'Tiến độ hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: totalCount > 0
                            ? (widget.doseTaken ? 1.0 / totalCount : 0.0)
                            : 0.0,
                        strokeWidth: 7,
                        backgroundColor: const Color(0xFFE6E8F8),
                        color: const Color(0xFF5065F2),
                      ),
                      Text(
                        widget.doseTaken
                            ? '1/$totalCount'
                            : '0/$totalCount',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chăm sóc sức khoẻ mỗi ngày',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        totalCount > 0
                            ? 'Có $totalCount cữ thuốc cần uống trong ngày'
                            : 'Chưa có cữ thuốc nào hôm nay',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

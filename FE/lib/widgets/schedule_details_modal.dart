import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/medication_logs_api.dart';
import '../services/notification_service.dart';
import '../services/schedule_api.dart';

/// Hiển thị modal Xem chi tiết lịch uống thuốc
void showScheduleDetailsModal(
  BuildContext context, {
  required String scheduleId,
  ScheduleRule? initialRule,
  DateTime? selectedDate,
  VoidCallback? onUpdated,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ScheduleDetailsModalSheet(
      scheduleId: scheduleId,
      initialRule: initialRule,
      selectedDate: selectedDate,
      onUpdated: onUpdated,
    ),
  );
}

/// Hiển thị modal Chỉnh sửa lịch uống thuốc (gọi PATCH)
void showScheduleEditModal(
  BuildContext context, {
  required ScheduleRule rule,
  VoidCallback? onUpdated,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ScheduleEditModalSheet(rule: rule, onUpdated: onUpdated),
  );
}

/// Hiển thị modal Tạo thêm cữ uống cho thuốc (gọi POST)
void showAddScheduleModal(
  BuildContext context, {
  required String prescriptionItemId,
  String? medicineName,
  String? prescriptionTitle,
  VoidCallback? onCreated,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddScheduleModalSheet(
      prescriptionItemId: prescriptionItemId,
      medicineName: medicineName,
      prescriptionTitle: prescriptionTitle,
      onCreated: onCreated,
    ),
  );
}

/// ============================================================================
/// 1. MODAL XEM CHI TIẾT LỊCH UỐNG THUỐC (Read-only)
/// ============================================================================
class ScheduleDetailsModalSheet extends StatefulWidget {
  const ScheduleDetailsModalSheet({
    super.key,
    required this.scheduleId,
    this.initialRule,
    this.selectedDate,
    this.onUpdated,
    this.scheduleApi,
    this.medicationLogsApi,
  });

  final String scheduleId;
  final ScheduleRule? initialRule;
  final DateTime? selectedDate;
  final VoidCallback? onUpdated;
  final ScheduleApi? scheduleApi;
  final MedicationLogsApi? medicationLogsApi;

  @override
  State<ScheduleDetailsModalSheet> createState() =>
      _ScheduleDetailsModalSheetState();
}

class _ScheduleDetailsModalSheetState extends State<ScheduleDetailsModalSheet> {
  late final ScheduleApi _api;
  late final MedicationLogsApi _medicationLogsApi;
  ScheduleRule? _rule;
  List<ScheduleRule> _allDoses = [];
  List<MedicationLog> _doseLogs = [];
  bool _isLoading = true;
  bool _logsLoading = true;
  String? _errorMessage;
  String? _logsError;

  DateTime get _selectedDate {
    final value = widget.selectedDate ?? DateTime.now();
    return DateTime(value.year, value.month, value.day);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.scheduleApi ?? ScheduleApi();
    _medicationLogsApi = widget.medicationLogsApi ?? MedicationLogsApi();
    if (widget.initialRule != null) {
      _rule = widget.initialRule;
      _allDoses = [widget.initialRule!];
    }
    _fetchById();
  }

  /// Gọi API GET /api/v1/schedule-rules/:id và lấy toàn bộ các cữ của thuốc này
  Future<void> _fetchById() async {
    try {
      final detailed = await _api.getById(widget.scheduleId);
      List<ScheduleRule> sameMedicineRules = [detailed];
      List<MedicationLog> doseLogs = const [];
      String? logsError;
      final allRulesRequest = _api.list(patientId: detailed.patientId);
      final logsRequest = _medicationLogsApi.list(
        from: _selectedDate,
        to: _selectedDate,
        patientId: detailed.patientId,
      );
      try {
        final allRules = await allRulesRequest;
        final matches = allRules
            .where((r) => r.prescriptionItemId == detailed.prescriptionItemId)
            .toList();
        if (matches.isNotEmpty) {
          matches.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
          sameMedicineRules = matches;
        }
      } catch (_) {}
      try {
        final logs = await logsRequest;
        doseLogs =
            logs.where((log) => log.scheduleRuleId == detailed.id).toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      } catch (error) {
        logsError = error.toString();
      }

      if (mounted) {
        setState(() {
          _rule = detailed;
          _allDoses = sameMedicineRules;
          _doseLogs = doseLogs;
          _logsError = logsError;
          _logsLoading = false;
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

  @override
  void dispose() {
    if (widget.scheduleApi == null) _api.close();
    if (widget.medicationLogsApi == null) _medicationLogsApi.close();
    super.dispose();
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Hàng ngày (T2 ➔ Chủ Nhật)';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Thứ 2 đến Thứ 6';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Cuối tuần (Thứ 7 & Chủ Nhật)';
    }
    return 'Thứ: ${days.join(", ")}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết cữ uống',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading && _rule == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5065F2)),
                ),
              )
            else if (_errorMessage != null && _rule == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Lỗi tải thông tin: $_errorMessage',
                    style: const TextStyle(color: Color(0xFFD32F2F)),
                  ),
                ),
              )
            else ...[
              // Header thuốc
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFFE8EDFF),
                      child:
                          (_rule!.medicine.imageUrl != null &&
                              _rule!.medicine.imageUrl!.trim().isNotEmpty &&
                              _rule!.medicine.imageUrl!.startsWith('http'))
                          ? Image.network(
                              _rule!.medicine.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.medication_rounded,
                                color: Color(0xFF5065F2),
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.medication_rounded,
                              color: Color(0xFF5065F2),
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _rule!.medicine.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF5065F2),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đơn thuốc: ${_rule!.prescription.title}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5065F2),
                          ),
                        ),
                        if (_rule!.prescription.startDate != null)
                          Text(
                            'Thời hạn: ${_rule!.prescription.startDate} ➔ ${_rule!.prescription.endDate ?? "Dài hạn"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Danh sách tất cả cữ uống trong ngày của thuốc này
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 18,
                              color: Color(0xFF5065F2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Các cữ uống (${_allDoses.length} cữ/ngày)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_allDoses.length} lần/ngày',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._allDoses.map((dose) {
                      final isSelectedDose = dose.id == _rule!.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelectedDose
                              ? const Color(0xFFEEF2FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelectedDose
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFE2E8F0),
                            width: isSelectedDose ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dose.isActive
                                    ? const Color(0xFF5065F2)
                                    : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              dose.displayTime,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '· ${dose.period}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${dose.dosagePerTime.toInt()} ${_rule!.medicine.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: dose.isActive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dose.isActive ? 'Đang bật' : 'Tắt',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: dose.isActive
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.scale_rounded,
                'Liều lượng mỗi lần',
                '${_rule!.dosagePerTime.toInt()} ${_rule!.medicine.unit}',
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.menu_book_rounded,
                'Hướng dẫn sử dụng',
                _rule!.instructions ?? 'Không có ghi chú thêm',
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.event_repeat_rounded,
                'Lịch lặp lại',
                _formatDays(_rule!.daysOfWeek),
              ),
              const SizedBox(height: 12),
              _detailRow(
                _rule!.isActive
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                'Trạng thái nhắc nhở',
                _rule!.isActive ? 'Đang bật nhắc nhở' : 'Đã tắt nhắc nhở',
                color: _rule!.isActive
                    ? const Color(0xFF239E77)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              _buildDoseResult(),
              const SizedBox(height: 12),
              _detailRow(
                Icons.verified_rounded,
                'Trạng thái toa thuốc',
                _rule!.prescription.isActive
                    ? 'Đang điều trị'
                    : 'Đã ngưng điều trị',
              ),
              const SizedBox(height: 16),

              // Thông tin hệ thống
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THÔNG TIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _codeRow('Schedule ID', _rule!.id),
                    _codeRow('Item ID', _rule!.prescriptionItemId),
                    _codeRow('Patient ID', _rule!.patientId),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showScheduleEditModal(
                          context,
                          rule: _rule!,
                          onUpdated: widget.onUpdated,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh sửa'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: const Color(0xFF5065F2),
                        side: const BorderSide(color: Color(0xFF5065F2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showAddScheduleModal(
                          context,
                          prescriptionItemId: _rule!.prescriptionItemId,
                          medicineName: _rule!.medicine.name,
                          prescriptionTitle: _rule!.prescription.title,
                          onCreated: widget.onUpdated,
                        );
                      },
                      icon: const Icon(Icons.alarm_add_rounded, size: 18),
                      label: const Text('Thêm cữ'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5065F2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Đóng'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF082452),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _codeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 20,
                color: Color(0xFF5065F2),
              ),
              const SizedBox(width: 8),
              Text(
                'Kết quả ngày ${_dateLabel(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_logsLoading)
            const LinearProgressIndicator()
          else if (_logsError != null)
            Text(
              'Không tải được kết quả cữ thuốc: $_logsError',
              style: const TextStyle(color: Color(0xFFD65D4A)),
            )
          else if (_doseLogs.isEmpty)
            const Text(
              'Chưa có dữ liệu ghi nhận cho cữ thuốc này.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ..._doseLogs.map(_doseLogTile),
        ],
      ),
    );
  }

  Widget _doseLogTile(MedicationLog log) {
    final presentation = _logPresentation(log);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: presentation.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: presentation.color,
                  ),
                ),
                if (presentation.detail != null)
                  Text(
                    presentation.detail!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                if (log.status == DoseStatus.skipped &&
                    (log.skipReason?.trim().isNotEmpty ?? false))
                  Text(
                    'Lý do: ${log.skipReason}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _DoseLogPresentation _logPresentation(MedicationLog log) {
    if (log.status == DoseStatus.taken && log.actualTakenAt != null) {
      final planned = _plannedAt(_rule!, _selectedDate);
      final late = log.actualTakenAt!.isAfter(planned);
      final lateMinutes = log.actualTakenAt!.difference(planned).inMinutes;
      return _DoseLogPresentation(
        label: late ? 'Uống trễ' : 'Đã uống',
        detail: late
            ? 'Đã uống lúc ${_clock(log.actualTakenAt!)} · trễ ${lateMinutes < 1 ? 1 : lateMinutes} phút'
            : 'Đã uống lúc ${_clock(log.actualTakenAt!)}',
        color: late ? const Color(0xFFF0A042) : const Color(0xFF239E77),
      );
    }
    return switch (log.status) {
      DoseStatus.scheduled => const _DoseLogPresentation(
        label: 'Chưa uống',
        color: Color(0xFF5065F2),
      ),
      DoseStatus.snoozed => _DoseLogPresentation(
        label: 'Đã hoãn',
        detail: log.snoozeUntil == null
            ? null
            : 'Nhắc lại lúc ${_clock(log.snoozeUntil!)}',
        color: const Color(0xFFF0A042),
      ),
      DoseStatus.taken => const _DoseLogPresentation(
        label: 'Đã uống',
        color: Color(0xFF239E77),
      ),
      DoseStatus.skipped => const _DoseLogPresentation(
        label: 'Đã bỏ qua',
        color: Color(0xFF8B6BC4),
      ),
      DoseStatus.missed => const _DoseLogPresentation(
        label: 'Đã bỏ lỡ',
        color: Color(0xFFD65D4A),
      ),
    };
  }

  DateTime _plannedAt(ScheduleRule rule, DateTime date) {
    final parts = rule.reminderTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts.first) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? const Color(0xFF5065F2)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoseLogPresentation {
  const _DoseLogPresentation({
    required this.label,
    required this.color,
    this.detail,
  });

  final String label;
  final String? detail;
  final Color color;
}

/// ============================================================================
/// 2. MODAL CHỈNH SỬA LỊCH UỐNG THUỐC (GỌI PATCH API)
/// ============================================================================
class ScheduleEditModalSheet extends StatefulWidget {
  const ScheduleEditModalSheet({super.key, required this.rule, this.onUpdated});

  final ScheduleRule rule;
  final VoidCallback? onUpdated;

  @override
  State<ScheduleEditModalSheet> createState() => _ScheduleEditModalSheetState();
}

class _ScheduleEditModalSheetState extends State<ScheduleEditModalSheet> {
  final _api = ScheduleApi();
  late String _reminderTime;
  late bool _isActive;
  late List<int> _daysOfWeek;
  bool _isSaving = false;

  static const List<Map<String, dynamic>> _dayItems = [
    {'day': 1, 'label': 'T2'},
    {'day': 2, 'label': 'T3'},
    {'day': 3, 'label': 'T4'},
    {'day': 4, 'label': 'T5'},
    {'day': 5, 'label': 'T6'},
    {'day': 6, 'label': 'T7'},
    {'day': 7, 'label': 'CN'},
  ];

  @override
  void initState() {
    super.initState();
    _reminderTime = widget.rule.displayTime;
    _isActive = widget.rule.isActive;
    _daysOfWeek = List<int>.from(widget.rule.daysOfWeek);
  }

  void _toggleDay(int day) {
    setState(() {
      if (_daysOfWeek.contains(day)) {
        if (_daysOfWeek.length > 1) {
          _daysOfWeek.remove(day);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phải có ít nhất 1 ngày uống thuốc trong tuần'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        _daysOfWeek.add(day);
      }
      _daysOfWeek.sort();
    });
  }

  Future<void> _pickTime() async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _reminderTime = '$hour:$minute';
      });
    }
  }

  /// Gọi API PATCH http://localhost:3000/api/v1/schedule-rules/:id
  Future<void> _save() async {
    if (_daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ngày uống thuốc trong tuần'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sortedDays = List<int>.from(_daysOfWeek)..sort();
      await _api.update(
        widget.rule.id,
        reminderTime: _reminderTime,
        daysOfWeek: sortedDays,
        isActive: _isActive,
      );
      await NotificationService.instance.refreshUpcomingMedicationLogs(
        force: true,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật lịch uống thành công!'),
            backgroundColor: Color(0xFF239E77),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onUpdated?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Chỉnh sửa
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF5065F2),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉnh sửa lịch uống',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${widget.rule.medicine.name} (${widget.rule.prescription.title})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 24),

            // Phần chọn giờ nhắc (reminderTime)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    size: 24,
                    color: Color(0xFF5065F2),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giờ nhắc uống',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        _reminderTime,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _isSaving ? null : _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: const Text('Đổi giờ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8EDFF),
                      foregroundColor: const Color(0xFF5065F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phần chọn ngày uống trong tuần (daysOfWeek)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: Color(0xFF5065F2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ngày uống trong tuần',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 7 chip ngày T2 -> CN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _dayItems.map((item) {
                      final dayNum = item['day'] as int;
                      final label = item['label'] as String;
                      final isSelected = _daysOfWeek.contains(dayNum);

                      return InkWell(
                        onTap: _isSaving ? null : () => _toggleDay(dayNum),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5065F2)
                                : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B4EDB)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phần bật/tắt nhắc nhở (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isActive
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 22,
                        color: _isActive
                            ? const Color(0xFF239E77)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trạng thái nhắc nhở',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _isActive ? 'Đang bật nhắc nhở' : 'Tắt nhắc nhở',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _isActive
                                  ? const Color(0xFF239E77)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isActive,
                    activeThumbColor: const Color(0xFF5065F2),
                    onChanged: _isSaving
                        ? null
                        : (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nút Lưu cập nhật (PATCH) & Hủy
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF5065F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// 3. MODAL TẠO THÊM CỮ UỐNG MỚI (GỌI POST /api/v1/prescription-items/:id/schedules)
/// ============================================================================
class AddScheduleModalSheet extends StatefulWidget {
  const AddScheduleModalSheet({
    super.key,
    required this.prescriptionItemId,
    this.medicineName,
    this.prescriptionTitle,
    this.onCreated,
  });

  final String prescriptionItemId;
  final String? medicineName;
  final String? prescriptionTitle;
  final VoidCallback? onCreated;

  @override
  State<AddScheduleModalSheet> createState() => _AddScheduleModalSheetState();
}

class _AddScheduleModalSheetState extends State<AddScheduleModalSheet> {
  final _api = ScheduleApi();
  String _reminderTime = '12:00';
  bool _isCreating = false;

  Future<void> _pickTime() async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 12,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _reminderTime = '$hour:$minute';
      });
    }
  }

  /// Gọi POST http://localhost:3000/api/v1/prescription-items/:id/schedules
  Future<void> _submitCreate() async {
    setState(() => _isCreating = true);
    try {
      final newSchedule = await _api.create(
        widget.prescriptionItemId,
        reminderTime: _reminderTime,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      );

      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo thêm cữ uống lúc ${newSchedule.displayTime} cho thuốc thành công!',
            ),
            backgroundColor: const Color(0xFF239E77),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onCreated?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo cữ uống: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm_add_rounded,
                    color: Color(0xFF5065F2),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thêm cữ uống mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${widget.medicineName ?? "Thuốc"} · ${widget.prescriptionTitle ?? "Đơn thuốc"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 24),

            // Chọn giờ nhắc uống
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 24,
                        color: Color(0xFF5065F2),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giờ nhắc cữ uống mới',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _reminderTime,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _isCreating ? null : _pickTime,
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: const Text('Đổi giờ'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE8EDFF),
                          foregroundColor: const Color(0xFF5065F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút Thêm cữ uống (POST) & Hủy
            FilledButton.icon(
              onPressed: _isCreating ? null : _submitCreate,
              icon: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_task_rounded),
              label: Text(
                _isCreating ? 'Đang tạo...' : 'Tạo cữ uống',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF5065F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }
}

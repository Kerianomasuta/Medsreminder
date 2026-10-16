import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_api.dart';
import '../../widgets/pressable.dart';

class AdminMedicationTab extends StatefulWidget {
  const AdminMedicationTab({super.key, required this.adminApi});
  final AdminApi adminApi;

  @override
  State<AdminMedicationTab> createState() => _AdminMedicationTabState();
}

class _AdminMedicationTabState extends State<AdminMedicationTab> {
  int _subTab = 0; // 0: Đơn thuốc, 1: Nhật ký uống thuốc

  // Prescriptions state
  final _rxSearchController = TextEditingController();
  bool? _rxActiveFilter;
  bool _rxLoading = false;
  String? _rxError;
  int _rxPage = 1;
  AdminPagedResponse? _rxResponse;

  // Logs state
  final _logSearchController = TextEditingController();
  String? _logStatusFilter;
  bool _logLoading = false;
  String? _logError;
  int _logPage = 1;
  AdminPagedResponse? _logResponse;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
    _loadLogs();
  }

  @override
  void dispose() {
    _rxSearchController.dispose();
    _logSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _rxLoading = true;
      _rxError = null;
    });
    try {
      final res = await widget.adminApi.searchPrescriptions(
        q: _rxSearchController.text.trim().isEmpty
            ? null
            : _rxSearchController.text.trim(),
        isActive: _rxActiveFilter,
        page: _rxPage,
      );
      if (!mounted) return;
      setState(() {
        _rxResponse = res;
        _rxLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rxError = e.toString();
        _rxLoading = false;
      });
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _logLoading = true;
      _logError = null;
    });
    try {
      final query = _logSearchController.text.trim();
      final isMongoId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(query);
      final res = await widget.adminApi.searchMedicationLogs(
        patientId: isMongoId ? query : null,
        status: _logStatusFilter,
        page: _logPage,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _logResponse = res;
        _logLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logError = e.toString();
        _logLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Sub-tabs switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  title: 'Đơn thuốc',
                  icon: Icons.receipt_long_rounded,
                  active: _subTab == 0,
                  count: _rxResponse?.total,
                  onTap: () => setState(() => _subTab = 0),
                ),
              ),
              Expanded(
                child: _SegmentButton(
                  title: 'Nhật ký uống thuốc',
                  icon: Icons.fact_check_rounded,
                  active: _subTab == 1,
                  count: _logResponse?.total,
                  onTap: () => setState(() => _subTab = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_subTab == 0) _buildPrescriptionsView() else _buildLogsView(),
      ],
    );
  }

  Widget _buildPrescriptionsView() {
    final items = _rxResponse?.items ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _rxSearchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên đơn, bác sĩ...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _rxSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _rxSearchController.clear();
                              _rxPage = 1;
                              _loadPrescriptions();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    _rxPage = 1;
                    _loadPrescriptions();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _rxLoading
                  ? null
                  : () {
                      _rxPage = 1;
                      _loadPrescriptions();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: const Text('Tìm'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter chips: Active / Inactive
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tất cả trạng thái',
                selected: _rxActiveFilter == null,
                onSelected: () {
                  setState(() {
                    _rxActiveFilter = null;
                    _rxPage = 1;
                  });
                  _loadPrescriptions();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đang hoạt động',
                icon: Icons.check_circle_outline_rounded,
                selected: _rxActiveFilter == true,
                onSelected: () {
                  setState(() {
                    _rxActiveFilter = true;
                    _rxPage = 1;
                  });
                  _loadPrescriptions();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Tạm dừng',
                icon: Icons.pause_circle_outline_rounded,
                selected: _rxActiveFilter == false,
                onSelected: () {
                  setState(() {
                    _rxActiveFilter = false;
                    _rxPage = 1;
                  });
                  _loadPrescriptions();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_rxLoading) const LinearProgressIndicator(),
        if (_rxError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Lỗi: $_rxError',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),

        if (_rxResponse != null) ...[
          Text(
            'Tìm thấy ${_rxResponse!.total} đơn thuốc · Trang $_rxPage',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty && !_rxLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy đơn thuốc nào.'),
              ),
            ),
          for (final row in items) ...[
            _PrescriptionCard(
              data: row,
              onTap: () => _showPrescriptionDetail(row),
            ),
            const SizedBox(height: 10),
          ],
          _PaginationRow(
            page: _rxPage,
            total: _rxResponse!.total,
            limit: _rxResponse!.limit,
            onPrev: _rxPage > 1
                ? () {
                    setState(() => _rxPage--);
                    _loadPrescriptions();
                  }
                : null,
            onNext: (_rxResponse!.items.length >= _rxResponse!.limit)
                ? () {
                    setState(() => _rxPage++);
                    _loadPrescriptions();
                  }
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildLogsView() {
    final rawItems = _logResponse?.items ?? const [];
    final query = _logSearchController.text.trim();
    final isMongoId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(query);
    final qLower = query.toLowerCase();

    // Client-side fallback filter by medicine name, patient ID, or status if free text
    final items = (query.isEmpty || isMongoId)
        ? rawItems
        : rawItems.where((r) {
            final medName = (r['medicineName'] ?? r['title'] ?? '')
                .toString()
                .toLowerCase();
            final pid = (r['patientId'] ?? '').toString().toLowerCase();
            final status = (r['status'] ?? '').toString().toLowerCase();
            return medName.contains(qLower) ||
                pid.contains(qLower) ||
                status.contains(qLower);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _logSearchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên thuốc, mã bệnh nhân...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _logSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _logSearchController.clear();
                              _logPage = 1;
                              _loadLogs();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    _logPage = 1;
                    _loadLogs();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _logLoading
                  ? null
                  : () {
                      _logPage = 1;
                      _loadLogs();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: const Text('Tìm'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tất cả log',
                selected: _logStatusFilter == null,
                onSelected: () {
                  setState(() {
                    _logStatusFilter = null;
                    _logPage = 1;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đã uống (TAKEN)',
                color: const Color(0xFF10B981),
                selected: _logStatusFilter == 'TAKEN',
                onSelected: () {
                  setState(() {
                    _logStatusFilter = 'TAKEN';
                    _logPage = 1;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Bỏ lỡ (MISSED)',
                color: const Color(0xFFEF4444),
                selected: _logStatusFilter == 'MISSED',
                onSelected: () {
                  setState(() {
                    _logStatusFilter = 'MISSED';
                    _logPage = 1;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đã hoãn (SNOOZED)',
                color: const Color(0xFFF59E0B),
                selected: _logStatusFilter == 'SNOOZED',
                onSelected: () {
                  setState(() {
                    _logStatusFilter = 'SNOOZED';
                    _logPage = 1;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Lên lịch (SCHEDULED)',
                color: const Color(0xFF3B82F6),
                selected: _logStatusFilter == 'SCHEDULED',
                onSelected: () {
                  setState(() {
                    _logStatusFilter = 'SCHEDULED';
                    _logPage = 1;
                  });
                  _loadLogs();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_logLoading) const LinearProgressIndicator(),
        if (_logError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Lỗi: $_logError',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),

        if (_logResponse != null) ...[
          Text(
            query.isNotEmpty && !isMongoId
                ? 'Tìm thấy ${items.length} kết quả (trên tổng ${_logResponse!.total}) · Trang $_logPage'
                : 'Tìm thấy ${_logResponse!.total} lượt ghi nhận · Trang $_logPage',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty && !_logLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy nhật ký uống thuốc phù hợp.'),
              ),
            ),
          for (final row in items) ...[
            _MedicationLogCard(
              data: row,
              onTap: () => _showMedicationLogDetail(row),
            ),
            const SizedBox(height: 10),
          ],
          _PaginationRow(
            page: _logPage,
            total: _logResponse!.total,
            limit: _logResponse!.limit,
            onPrev: _logPage > 1
                ? () {
                    setState(() => _logPage--);
                    _loadLogs();
                  }
                : null,
            onNext: (_logResponse!.items.length >= _logResponse!.limit)
                ? () {
                    setState(() => _logPage++);
                    _loadLogs();
                  }
                : null,
          ),
        ],
      ],
    );
  }

  void _showMedicationLogDetail(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MedicationLogDetailSheet(data: row),
    );
  }

  void _showPrescriptionDetail(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PrescriptionDetailSheet(
        adminApi: widget.adminApi,
        initialData: row,
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Đơn thuốc không tên';
    final doctor = data['doctorName']?.toString();
    final patientId = data['patientId']?.toString() ?? '';
    final code = data['prescriptionCode']?.toString();
    final isActive = data['isActive'] != false;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFF4F46E5),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            if (code != null && code.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Mã đơn: $code',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            if (doctor != null && doctor.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.person_pin_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'BS. $doctor',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            Text(
              'Bệnh nhân: ${patientId.length > 8 ? patientId.substring(0, 8) : patientId}...',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFF64748B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Đang dùng' : 'Tạm ngưng',
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF059669)
                      : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
        onTap: onTap,
      ),
    ),
  );
}
}

class _MedicationLogCard extends StatelessWidget {
  const _MedicationLogCard({required this.data, this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'TAKEN':
        return const Color(0xFF10B981);
      case 'MISSED':
        return const Color(0xFFEF4444);
      case 'SNOOZED':
        return const Color(0xFFF59E0B);
      case 'SKIPPED':
        return const Color(0xFF8B5CF6);
      case 'SCHEDULED':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'TAKEN':
        return 'Đã uống';
      case 'MISSED':
        return 'Bỏ lỡ';
      case 'SNOOZED':
        return 'Đã hoãn';
      case 'SKIPPED':
        return 'Đã bỏ qua';
      case 'SCHEDULED':
        return 'Đã lên lịch';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = data['id']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'SCHEDULED';
    final color = _statusColor(status);
    final medName = data['medicineName']?.toString() ??
        data['title']?.toString() ??
        'Liều dùng thuốc';
    final scheduledRaw = data['scheduledAt'] ?? data['scheduledTime'];
    final scheduledFormatted =
        scheduledRaw != null ? _formatDateTime(scheduledRaw) : '';
    final patientId = data['patientId']?.toString() ?? '';
    final scheduleRuleId = data['scheduleRuleId']?.toString() ?? '';
    final actualTakenAt = data['actualTakenAt'];
    final snoozeUntil = data['snoozeUntil'];
    final escalationLevel = data['escalationLevel'] ?? 0;
    final skipReason = data['skipReason']?.toString();
    final createdAt = data['createdAt'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Icon, Name, Status Badge, Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.alarm_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (id.isNotEmpty)
                          Text(
                            'Log ID: ${id.length > 8 ? id.substring(0, 8) : id}...',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Details grid / rows
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (scheduledFormatted.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lên lịch: $scheduledFormatted',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  if (actualTakenAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Đã uống: ${_formatDateTime(actualTakenAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  if (snoozeUntil != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.snooze_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hoãn đến: ${_formatDateTime(snoozeUntil)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  if (patientId.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bệnh nhân: ${patientId.length > 8 ? patientId.substring(0, 8) : patientId}...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  if (escalationLevel != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cảnh báo: Level $escalationLevel',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  if (skipReason != null && skipReason.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lý do: $skipReason',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  if (createdAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tạo lúc: ${_formatDateTime(createdAt)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
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
  }
}

class _MedicationLogDetailSheet extends StatelessWidget {
  const _MedicationLogDetailSheet({required this.data});
  final Map<String, dynamic> data;

  Color _statusColor(String status) {
    switch (status) {
      case 'TAKEN':
        return const Color(0xFF10B981);
      case 'MISSED':
        return const Color(0xFFEF4444);
      case 'SNOOZED':
        return const Color(0xFFF59E0B);
      case 'SKIPPED':
        return const Color(0xFF8B5CF6);
      case 'SCHEDULED':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'TAKEN':
        return 'Đã uống (TAKEN)';
      case 'MISSED':
        return 'Bỏ lỡ (MISSED)';
      case 'SNOOZED':
        return 'Đã hoãn (SNOOZED)';
      case 'SKIPPED':
        return 'Đã bỏ qua (SKIPPED)';
      case 'SCHEDULED':
        return 'Đã lên lịch (SCHEDULED)';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = data['id']?.toString() ?? '';
    final patientId = data['patientId']?.toString() ?? '';
    final scheduleRuleId = data['scheduleRuleId']?.toString() ?? '';
    final medName = data['medicineName']?.toString() ??
        data['title']?.toString() ??
        'Liều dùng thuốc';
    final scheduledAt = data['scheduledAt'] ?? data['scheduledTime'];
    final actualTakenAt = data['actualTakenAt'];
    final status = data['status']?.toString() ?? 'SCHEDULED';
    final snoozeUntil = data['snoozeUntil'];
    final escalationLevel = data['escalationLevel'] ?? 0;
    final skipReason = data['skipReason']?.toString();
    final createdAt = data['createdAt'];

    final color = _statusColor(status);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.alarm_rounded,
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  medName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Chi tiết nhật ký uống thuốc',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THÔNG TIN CHI TIẾT NHẬT KÝ UỐNG THUỐC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        label: 'Mã log (ID):',
                        value: id,
                        canCopy: id.isNotEmpty,
                        isBold: true,
                        valueColor: const Color(0xFF4F46E5),
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Tên thuốc:',
                        value: medName,
                        isBold: true,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Mã bệnh nhân:',
                        value: patientId,
                        canCopy: patientId.isNotEmpty,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Mã quy tắc nhắc:',
                        value: scheduleRuleId,
                        canCopy: scheduleRuleId.isNotEmpty,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Lên lịch uống lúc:',
                        value: scheduledAt != null
                            ? _formatDateTime(scheduledAt)
                            : 'Chưa có',
                        isBold: true,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Thực tế đã uống lúc:',
                        value: actualTakenAt != null
                            ? _formatDateTime(actualTakenAt)
                            : 'Chưa ghi nhận',
                        valueColor: actualTakenAt != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                        isBold: actualTakenAt != null,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Hoãn đến lúc:',
                        value: snoozeUntil != null
                            ? _formatDateTime(snoozeUntil)
                            : 'Không hoãn',
                        valueColor: snoozeUntil != null
                            ? const Color(0xFFF59E0B)
                            : null,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Mức độ cảnh báo:',
                        value:
                            'Level $escalationLevel (${escalationLevel == 0 ? 'Bình thường' : escalationLevel == 1 ? 'Nhắc Caregiver' : 'Báo động khẩn'})',
                        valueColor: escalationLevel != 0
                            ? const Color(0xFFDC2626)
                            : null,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(
                        context,
                        label: 'Lý do bỏ qua:',
                        value: skipReason != null && skipReason.isNotEmpty
                            ? skipReason
                            : 'Không có',
                        valueColor: skipReason != null && skipReason.isNotEmpty
                            ? const Color(0xFFDC2626)
                            : null,
                      ),
                      if (createdAt != null) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(
                          context,
                          label: 'Thời gian tạo log:',
                          value: _formatDateTime(createdAt),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool canCopy = false,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (canCopy &&
                  value.isNotEmpty &&
                  value != 'Chưa ghi nhận' &&
                  value != 'Không có')
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép $label $value'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrescriptionDetailSheet extends StatefulWidget {
  const _PrescriptionDetailSheet({
    required this.adminApi,
    required this.initialData,
  });

  final AdminApi adminApi;
  final Map<String, dynamic> initialData;

  @override
  State<_PrescriptionDetailSheet> createState() =>
      _PrescriptionDetailSheetState();
}

class _PrescriptionDetailSheetState extends State<_PrescriptionDetailSheet> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final id = widget.initialData['id']?.toString() ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.adminApi.getPrescriptionDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = (_detail?['prescription'] as Map<String, dynamic>?) ??
        widget.initialData;
    final items = (_detail?['items'] as List<dynamic>?) ?? const [];

    final id = p['id']?.toString() ?? '';
    final title = p['title']?.toString() ?? 'Chi tiết đơn thuốc';
    final code = p['prescriptionCode']?.toString();
    final doctor = p['doctorName']?.toString();
    final patientId = p['patientId']?.toString() ?? '';
    final createdByCgId = p['createdByCgId']?.toString() ?? '';
    final startDate = p['startDate']?.toString();
    final endDate = p['endDate']?.toString();
    final isActive = p['isActive'] != false;
    final imageUrl = p['imagePrescriptionUrl']?.toString();
    final createdAt = p['createdAt']?.toString();
    final updatedAt = p['updatedAt']?.toString();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFFEF4444)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'Đang hoạt động' : 'Tạm dừng',
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            doctor != null && doctor.isNotEmpty
                                ? 'Bác sĩ: $doctor'
                                : 'Chưa cập nhật bác sĩ',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // General Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THÔNG TIN CHUNG ĐƠN THUỐC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldRow(
                        context,
                        label: 'Mã đơn thuốc:',
                        value: code != null && code.isNotEmpty
                            ? code
                            : 'Chưa thiết lập',
                        canCopy: code != null && code.isNotEmpty,
                        isBold: true,
                        valueColor: const Color(0xFF4F46E5),
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'ID đơn thuốc:',
                        value: id,
                        canCopy: id.isNotEmpty,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Mã bệnh nhân:',
                        value: patientId,
                        canCopy: patientId.isNotEmpty,
                      ),
                      if (createdByCgId.isNotEmpty) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Người chăm sóc:',
                          value: createdByCgId,
                          canCopy: true,
                        ),
                      ],
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Bác sĩ kê đơn:',
                        value: doctor != null && doctor.isNotEmpty
                            ? doctor
                            : 'Chưa cập nhật',
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Thời gian áp dụng:',
                        value:
                            '${_formatDate(startDate)} → ${endDate != null && endDate.isNotEmpty ? _formatDate(endDate) : 'Dài hạn / Không xác định'}',
                      ),
                      if (createdAt != null) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Ngày tạo đơn:',
                          value: _formatDateTime(createdAt),
                        ),
                      ],
                      if (updatedAt != null) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Cập nhật lần cuối:',
                          value: _formatDateTime(updatedAt),
                        ),
                      ],
                    ],
                  ),
                ),

                // Prescription Image (if available)
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                            Icon(Icons.image_outlined,
                                size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Text(
                              'Ảnh chụp đơn thuốc:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: const Color(0xFFE2E8F0),
                              alignment: Alignment.center,
                              child: const Text(
                                'Không tải được ảnh đơn thuốc',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Medication Items Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DANH SÁCH THUỐC TRONG ĐƠN (${items.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_loading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          'Không thể tải chi tiết danh sách thuốc: $_error',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchDetail,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else if (items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Đơn thuốc này chưa có chi tiết thành phần thuốc.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  for (final item in items) ...[
                    _buildMedicationItemCard(context, item),
                    const SizedBox(height: 10),
                  ],

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationItemCard(
      BuildContext context, Map<String, dynamic> item) {
    final name =
        item['name'] ?? item['medicineName'] ?? 'Thuốc không rõ tên';
    final generic = item['genericName']?.toString();
    final unit = item['unit']?.toString() ?? 'đơn vị';
    final dosage = item['dosagePerTime'] ?? item['dosage'];
    final stock = item['currentStock'];
    final threshold = item['reorderThreshold'];
    final instructions = item['instructions']?.toString();
    final schedules = (item['schedules'] as List<dynamic>?) ?? const [];

    final isLowStock = stock != null &&
        threshold != null &&
        (num.tryParse(stock.toString()) ?? 0) <=
            (num.tryParse(threshold.toString()) ?? 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isLowStock ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item title and stock badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (generic != null && generic.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Hoạt chất: $generic',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (stock != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLowStock
                        ? '⚠️ Còn $stock (Ngưỡng: $threshold)'
                        : 'Còn: $stock $unit',
                    style: TextStyle(
                      color: isLowStock
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Dosage & unit row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.scale_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Text(
                  'Liều dùng: ${dosage != null ? '$dosage ' : ''}$unit / lần',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),

          // Instructions row (if present)
          if (instructions != null && instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hướng dẫn: $instructions',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reminder schedules
          if (schedules.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Lịch nhắc uống thuốc:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in schedules)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alarm_rounded,
                          size: 13,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${s['reminderTime'] != null && s['reminderTime'].toString().length >= 5 ? s['reminderTime'].toString().substring(0, 5) : (s['reminderTime'] ?? '')} (${_formatDaysOfWeek(s['daysOfWeek'])})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                        if (s['isActive'] == false) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '[Tắt]',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldRow(
    BuildContext context, {
    required String label,
    required String value,
    bool canCopy = false,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (canCopy &&
                  value.isNotEmpty &&
                  value != 'Chưa cập nhật' &&
                  value != 'Chưa thiết lập')
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép $label $value'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return 'Chưa cập nhật';
  try {
    final dt = DateTime.parse(value.toString());
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return value.toString();
  }
}

String _formatDateTime(dynamic value) {
  if (value == null || value.toString().isEmpty) return 'Chưa cập nhật';
  try {
    final dt = DateTime.parse(value.toString()).toLocal();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hr = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$hr:$mn · $d/$m/$y';
  } catch (_) {
    return value.toString();
  }
}

String _formatDaysOfWeek(dynamic days) {
  if (days == null) return 'Hàng ngày';
  if (days is List) {
    if (days.isEmpty || days.length == 7) return 'Hàng ngày';
    final sorted = List<int>.from(days.whereType<int>())..sort();
    final names = sorted.map((d) {
      switch (d) {
        case 1:
          return 'T2';
        case 2:
          return 'T3';
        case 3:
          return 'T4';
        case 4:
          return 'T5';
        case 5:
          return 'T6';
        case 6:
          return 'T7';
        case 7:
          return 'CN';
        default:
          return 'T$d';
      }
    }).toList();
    return names.join(', ');
  }
  return days.toString();
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.title,
    required this.icon,
    required this.active,
    this.count,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool active;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              count != null ? '$title ($count)' : title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF4F46E5);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? activeColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? activeColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.page,
    required this.total,
    required this.limit,
    this.onPrev,
    this.onNext,
  });

  final int page;
  final int total;
  final int limit;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang $page (${(page - 1) * limit + 1} - ${page * limit > total ? total : page * limit} / $total)',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Row(
            children: [
              IconButton.outlined(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

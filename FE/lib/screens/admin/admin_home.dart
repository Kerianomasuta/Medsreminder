import 'package:flutter/material.dart';

import '../../services/admin_api.dart';
import '../../widgets/animated_aurora_background.dart';
import '../../widgets/glass.dart';
import '../../widgets/pressable.dart';
import 'admin_medication_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_pharmacy_tab.dart';
import 'admin_users_tab.dart';

/// Màn hình Admin Dashboard (Trung tâm điều hành quản trị)
class AdminHome extends StatefulWidget {
  const AdminHome({
    super.key,
    this.adminName = 'Quản trị viên',
    this.tab = 0,
    this.standalone,
    this.adminApi,
  });

  final String adminName;
  final int tab;
  final bool? standalone;
  final AdminApi? adminApi;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _auroraController;
  late final AdminApi _adminApi = widget.adminApi ?? AdminApi();

  late int _currentTab = widget.tab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.tab;
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AdminHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      setState(() => _currentTab = widget.tab);
    }
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStandalone =
        widget.standalone ?? (Scaffold.maybeOf(context) == null);

    Widget content;
    switch (_currentTab) {
      case 1:
        content = AdminUsersTab(adminApi: _adminApi);
        break;
      case 2:
        content = AdminMedicationTab(adminApi: _adminApi);
        break;
      case 3:
        content = AdminPharmacyTab(adminApi: _adminApi);
        break;
      case 4:
        content = AdminPaymentsTab(adminApi: _adminApi);
        break;
      case 0:
      default:
        content = _AdminOverviewTab(
          adminApi: _adminApi,
          adminName: widget.adminName,
        );
        break;
    }

    if (!isStandalone) {
      return content;
    }

    return AnimatedAuroraBackground(
      animation: _auroraController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _AdminHeader(adminName: widget.adminName),
                  Expanded(child: content),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _AdminBottomNavBar(
                  currentIndex: _currentTab,
                  onTap: (index) => setState(() => _currentTab = index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





// ==========================================
// TAB 0: TỔNG QUAN (OVERVIEW & 4 STAT CARDS)
// ==========================================
class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab({required this.adminApi, required this.adminName});

  final AdminApi adminApi;
  final String adminName;

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  bool _loading = true;
  String? _error;

  AdminSummary? _summary;
  AdminPaymentsSummary? _paymentsSummary;
  AdminPharmacySummary? _pharmacySummary;
  AdminMedicationSummary? _medicationSummary;

  @override
  void initState() {
    super.initState();
    _loadAllSummaries();
  }

  Future<void> _loadAllSummaries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.adminApi.getSummary(),
        widget.adminApi.getPaymentsSummary(),
        widget.adminApi.getPharmacySummary(),
        widget.adminApi.getMedicationSummary(),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as AdminSummary;
        _paymentsSummary = results[1] as AdminPaymentsSummary;
        _pharmacySummary = results[2] as AdminPharmacySummary;
        _medicationSummary = results[3] as AdminMedicationSummary;
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

  String _formatCurrency(double amount) {
    final integer = amount.toInt();
    final s = integer.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang tải số liệu hệ thống từ máy chủ...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Lỗi nạp số liệu: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1E284A)),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loadAllSummaries,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final totalRevenue =
        (_paymentsSummary?.totalAmount ?? 0.0) +
        (_pharmacySummary?.ordersCompletedAmount ?? 0.0);
    final newUsersCount = _summary?.registeredLast7Days ?? 0;
    final activePrescriptions = _medicationSummary?.prescriptionsActive ?? 0;
    final totalPharmacies = _pharmacySummary?.pharmacyTotal ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAllSummaries,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Nút làm mới
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trung tâm điều hành',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Dữ liệu thống kê thời gian thực từ máy chủ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _loadAllSummaries,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Làm mới toàn bộ số liệu',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4 THẺ SỐ LIỆU NỔI BẬT THEO YÊU CẦU
            Row(
              children: [
                Expanded(
                  child: _AdminStatCard(
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF10B981),
                    number: _formatCurrency(totalRevenue),
                    label: 'Tổng doanh thu',
                    subText:
                        'VIP: ${_formatCurrency(_paymentsSummary?.totalAmount ?? 0)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminStatCard(
                    icon: Icons.person_add_alt_1_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    number: '+$newUsersCount',
                    label: 'Người dùng mới',
                    subText: 'Tổng: ${_summary?.totalUsers ?? 0} tài khoản',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminStatCard(
                    icon: Icons.medical_services_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    number: '$activePrescriptions',
                    label: 'Đơn thuốc đang dùng',
                    subText:
                        'Tổng: ${_medicationSummary?.prescriptionsTotal ?? 0} đơn',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminStatCard(
                    icon: Icons.local_pharmacy_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    number: '$totalPharmacies',
                    label: 'Nhà thuốc hoạt động',
                    subText:
                        '+${_pharmacySummary?.pharmacyCreatedLast7Days ?? 0} trong 7 ngày',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Khối 1: Thống kê chi tiết tài khoản (/admin/summary)
            const Text(
              'Cơ cấu người dùng theo vai trò',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Glass(
              radius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _RoleProgressLine(
                    label: 'Bệnh nhân (PATIENT)',
                    count: _summary?.patientCount ?? 0,
                    total: _summary?.totalUsers ?? 1,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _RoleProgressLine(
                    label: 'Người chăm sóc (CARE_GIVER)',
                    count: _summary?.caregiverCount ?? 0,
                    total: _summary?.totalUsers ?? 1,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  _RoleProgressLine(
                    label: 'Dược sĩ nhà thuốc (PHARMACIST)',
                    count: _summary?.pharmacistCount ?? 0,
                    total: _summary?.totalUsers ?? 1,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  _RoleProgressLine(
                    label: 'Thành viên VIP (PREMIUM)',
                    count: _summary?.premiumCount ?? 0,
                    total: _summary?.totalUsers ?? 1,
                    color: const Color(0xFFEAB308),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Khối 2: Doanh thu VIP & Đơn thuốc
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Glass(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Gói VIP PayOS',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '7 ngày qua: ${_formatCurrency(_paymentsSummary?.paidLast7DaysAmount ?? 0)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '30 ngày qua: ${_formatCurrency(_paymentsSummary?.paidLast30DaysAmount ?? 0)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Glass(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Nhật ký & Liều',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tổng liều ghi nhận: ${_medicationSummary?.doseLogsTotal ?? 0}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lịch nhắc đang chạy: ${_medicationSummary?.schedulesActive ?? 0}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Khối 3: Thống kê Giao dịch VIP & Doanh thu
            _VipFinancialDashboard(
              summary: _paymentsSummary,
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 18),

            // Khối 4: Thống kê Đơn thuốc & Tuân thủ uống thuốc
            _MedicationAdherenceDashboard(
              summary: _medicationSummary,
            ),
            const SizedBox(height: 18),

            // Khối 5: Thống kê Nhà thuốc & Đơn đặt hàng
            _PharmacyOrdersDashboard(
              summary: _pharmacySummary,
              formatCurrency: _formatCurrency,
            ),
          ],
        ),
      ),
    );
  }
}

class _VipFinancialDashboard extends StatelessWidget {
  const _VipFinancialDashboard({
    required this.summary,
    required this.formatCurrency,
  });

  final AdminPaymentsSummary? summary;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Doanh thu & Giao dịch VIP',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s?.total ?? 0} giao dịch',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBadge(
                  label: 'Đã thanh toán',
                  value: '${s?.paid ?? 0} lệnh',
                  subValue: formatCurrency(s?.paidAmount ?? 0),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBadge(
                  label: 'Đang chờ xử lý',
                  value: '${s?.pending ?? 0} lệnh',
                  subValue: formatCurrency(s?.pendingAmount ?? 0),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBadge(
                  label: 'Thất bại',
                  value: '${s?.failed ?? 0} lệnh',
                  subValue: '0 đ',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TextPair(
                  title: 'Gói Tháng (MONTH)',
                  content:
                      '${s?.month.paid ?? 0} lượt · ${formatCurrency(s?.month.paidAmount ?? 0)}',
                ),
                Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                _TextPair(
                  title: 'Gói Năm (YEAR)',
                  content:
                      '${s?.year.paid ?? 0} lượt · ${formatCurrency(s?.year.paidAmount ?? 0)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationAdherenceDashboard extends StatelessWidget {
  const _MedicationAdherenceDashboard({required this.summary});
  final AdminMedicationSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.medication_rounded, color: Color(0xFF6366F1), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Đơn thuốc & Giám sát tuân thủ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s?.prescriptionsTotal ?? 0} đơn thuốc',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBadge(
                  label: 'Đang hoạt động',
                  value: '${s?.prescriptionsActive ?? 0} đơn',
                  subValue: 'Đơn đang dùng',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBadge(
                  label: 'Tạm dừng',
                  value: '${s?.prescriptionsInactive ?? 0} đơn',
                  subValue: 'Đã ngưng đơn',
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBadge(
                  label: 'Mới 7 ngày',
                  value: '+${s?.prescriptionsCreatedLast7Days ?? 0} đơn',
                  subValue: 'Đơn mới tạo',
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Nhật ký uống thuốc (Adherence Dose Logs):',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusPill(
                  label: 'Đã uống (TAKEN)',
                  count: s?.logsTaken ?? 0,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Bỏ lỡ (MISSED)',
                  count: s?.logsMissed ?? 0,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Đã hoãn (SNOOZED)',
                  count: s?.logsSnoozed ?? 0,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Lên lịch (SCHEDULED)',
                  count: s?.logsScheduled ?? 0,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Bỏ qua (SKIPPED)',
                  count: s?.logsSkipped ?? 0,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyOrdersDashboard extends StatelessWidget {
  const _PharmacyOrdersDashboard({
    required this.summary,
    required this.formatCurrency,
  });

  final AdminPharmacySummary? summary;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.local_pharmacy_rounded, color: Color(0xFF0284C7), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Nhà thuốc & Đơn đặt hàng',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s?.pharmacyTotal ?? 0} nhà thuốc',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBadge(
                  label: 'Tổng đơn hàng',
                  value: '${s?.ordersTotal ?? 0} đơn',
                  subValue: '+${s?.ordersCreatedLast7Days ?? 0} mới 7 ngày',
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBadge(
                  label: 'Đã hoàn tất',
                  value: '${s?.ordersCompleted ?? 0} đơn',
                  subValue: formatCurrency(s?.ordersCompletedAmount ?? 0),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBadge(
                  label: 'Đã hủy',
                  value: '${s?.ordersCancelled ?? 0} đơn',
                  subValue: 'Khách/tiệm hủy',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Trạng thái đơn hàng:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusPill(
                  label: 'Chờ duyệt',
                  count: s?.ordersPendingReview ?? 0,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Chuẩn bị',
                  count: s?.ordersPreparing ?? 0,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Chờ lấy',
                  count: s?.ordersReadyForPickup ?? 0,
                  color: const Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Đang giao',
                  count: s?.ordersShipped ?? 0,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Hoàn tất',
                  count: s?.ordersCompleted ?? 0,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  final String label;
  final String value;
  final String subValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPair extends StatelessWidget {
  const _TextPair({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}


// ==========================================
// CÁC THÀNH PHẦN PHỤ TRỢ (STAT CARD, HEADER, NAV)
// ==========================================
class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.label,
    this.subText,
  });

  final IconData icon;
  final Color iconColor;
  final String number;
  final String label;
  final String? subText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          if (subText != null) ...[
            const SizedBox(height: 4),
            Text(
              subText!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleProgressLine extends StatelessWidget {
  const _RoleProgressLine({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double percent = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.adminName});
  final String adminName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFDC2626),
            child: Icon(Icons.security_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Quyền quản trị cấp cao',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBottomNavBar extends StatelessWidget {
  const _AdminBottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItemData> _items = [
    _NavItemData(Icons.insights_rounded, 'Tổng quan'),
    _NavItemData(Icons.people_alt_rounded, 'Người dùng'),
    _NavItemData(Icons.medication_rounded, 'Đơn thuốc'),
    _NavItemData(Icons.local_pharmacy_rounded, 'Nhà thuốc'),
    _NavItemData(Icons.payments_rounded, 'VIP'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Glass(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            final item = _items[i];
            return Expanded(
              child: Pressable(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: active
                        ? const LinearGradient(
                            colors: [Color(0xFFEAF0FF), Color(0xFFC9D3FF)],
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: active
                            ? const Color(0xFF586FF3)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          color: active
                              ? const Color(0xFF1E284A)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.label);
  final IconData icon;
  final String label;
}

import 'package:flutter/material.dart';

import '../../services/admin_api.dart';
import '../../widgets/glass.dart';

class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({super.key, required this.adminApi});
  final AdminApi adminApi;

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  final _searchController = TextEditingController();

  AdminPaymentsSummary? _summary;
  bool _summaryLoading = false;

  String? _statusFilter;
  String? _planFilter;
  bool _loading = false;
  String? _error;
  int _page = 1;
  AdminPagedResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final summary = await widget.adminApi.getPaymentsSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = _searchController.text.trim();
      final res = await widget.adminApi.searchPayments(
        q: text.isEmpty ? null : text,
        status: _statusFilter,
        plan: _planFilter,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _response = res;
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

  String _formatCurrency(num amount) {
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
    final items = _response?.items ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Financial KPI Cards
        if (_summary != null) ...[
          Row(
            children: [
              Expanded(
                child: _FinanceKpiCard(
                  title: 'Doanh thu thực tế',
                  amount: _formatCurrency(_summary!.paidAmount),
                  subText: '${_summary!.paid} giao dịch thành công',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FinanceKpiCard(
                  title: 'Đang chờ xử lý',
                  amount: _formatCurrency(_summary!.pendingAmount),
                  subText: '${_summary!.pending} lệnh đang thanh toán',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.hourglass_top_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniMetric(
                  label: 'Gói tháng',
                  value:
                      '${_summary!.month.paid} lượt · ${_formatCurrency(_summary!.month.paidAmount)}',
                  icon: Icons.calendar_view_month_rounded,
                  iconColor: const Color(0xFF6366F1),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                _MiniMetric(
                  label: 'Gói năm',
                  value:
                      '${_summary!.year.paid} lượt · ${_formatCurrency(_summary!.year.paidAmount)}',
                  icon: Icons.military_tech_rounded,
                  iconColor: const Color(0xFFD97706),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Search Bar
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã txnRef, mã giao dịch cổng...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              _page = 1;
                              _loadPayments();
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
                    _page = 1;
                    _loadPayments();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () {
                      _page = 1;
                      _loadPayments();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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

        // Status & Plan filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tất cả trạng thái',
                selected: _statusFilter == null,
                onSelected: () {
                  setState(() {
                    _statusFilter = null;
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đã thanh toán (PAID)',
                color: const Color(0xFF10B981),
                selected: _statusFilter == 'PAID',
                onSelected: () {
                  setState(() {
                    _statusFilter = 'PAID';
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đang chờ (PENDING)',
                color: const Color(0xFFF59E0B),
                selected: _statusFilter == 'PENDING',
                onSelected: () {
                  setState(() {
                    _statusFilter = 'PENDING';
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Thất bại (FAILED)',
                color: const Color(0xFFEF4444),
                selected: _statusFilter == 'FAILED',
                onSelected: () {
                  setState(() {
                    _statusFilter = 'FAILED';
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
              const SizedBox(width: 14),
              Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 14),
              _FilterChip(
                label: 'Tất cả gói',
                selected: _planFilter == null,
                onSelected: () {
                  setState(() {
                    _planFilter = null;
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'VIP Tháng',
                color: const Color(0xFF6366F1),
                selected: _planFilter == 'MONTH',
                onSelected: () {
                  setState(() {
                    _planFilter = 'MONTH';
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'VIP Năm',
                color: const Color(0xFFD97706),
                selected: _planFilter == 'YEAR',
                onSelected: () {
                  setState(() {
                    _planFilter = 'YEAR';
                    _page = 1;
                  });
                  _loadPayments();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Lỗi: $_error',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),

        if (_response != null) ...[
          Text(
            'Tìm thấy ${_response!.total} giao dịch · Trang $_page',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty && !_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy giao dịch nào.'),
              ),
            ),
          for (final row in items) ...[
            _PaymentTransactionCard(
              data: row,
              formatCurrency: _formatCurrency,
              onTap: () => _showPaymentDetail(row),
            ),
            const SizedBox(height: 10),
          ],
          _PaginationRow(
            page: _page,
            total: _response!.total,
            limit: _response!.limit,
            onPrev: _page > 1
                ? () {
                    setState(() => _page--);
                    _loadPayments();
                  }
                : null,
            onNext: (_response!.items.length >= _response!.limit)
                ? () {
                    setState(() => _page++);
                    _loadPayments();
                  }
                : null,
          ),
        ],
      ],
    );
  }

  void _showPaymentDetail(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    Map<String, dynamic>? detail;
    try {
      detail = await widget.adminApi.getPaymentDetail(id);
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final payment = detail?['payment'] is Map<String, dynamic>
            ? detail!['payment'] as Map<String, dynamic>
            : row;
        final user = payment['user'] is Map<String, dynamic>
            ? payment['user'] as Map<String, dynamic>
            : null;
        final amount = (payment['amount'] as num?) ?? 0;
        final status = payment['status']?.toString() ?? 'PENDING';
        final plan = payment['plan']?.toString() ?? 'MONTH';
        final txnRef = payment['txnRef']?.toString() ?? id;
        final orderCode = payment['orderCode']?.toString();
        final paidAt = payment['paidAt']?.toString() ?? payment['createdAt']?.toString();

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chi tiết thanh toán VIP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _DetailRow('Mã tham chiếu PayOS', txnRef),
                    if (orderCode != null) ...[
                      const Divider(height: 16),
                      _DetailRow('Order code', orderCode),
                    ],
                    const Divider(height: 16),
                    _DetailRow('Gói VIP', plan == 'YEAR' ? 'VIP 1 Năm' : 'VIP 1 Tháng'),
                    const Divider(height: 16),
                    _DetailRow('Trạng thái', status),
                    if (user != null) ...[
                      const Divider(height: 16),
                      _DetailRow('Khách hàng', user['fullName'] ?? '-'),
                      const Divider(height: 16),
                      _DetailRow('Email', user['email'] ?? '-'),
                    ],
                    if (paidAt != null) ...[
                      const Divider(height: 16),
                      _DetailRow('Thời gian', paidAt),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FinanceKpiCard extends StatelessWidget {
  const _FinanceKpiCard({
    required this.title,
    required this.amount,
    required this.subText,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final String subText;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentTransactionCard extends StatelessWidget {
  const _PaymentTransactionCard({
    required this.data,
    required this.formatCurrency,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final String Function(num) formatCurrency;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFF10B981);
      case 'FAILED':
        return const Color(0xFFEF4444);
      case 'PENDING':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Thành công';
      case 'FAILED':
        return 'Thất bại';
      case 'PENDING':
      default:
        return 'Đang chờ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'PENDING';
    final plan = data['plan']?.toString() ?? 'MONTH';
    final amount = (data['amount'] as num?) ?? 0;
    final txnRef = data['txnRef']?.toString() ?? data['id']?.toString() ?? '';
    final color = _statusColor(status);

    // Extract user info cleanly without raw json string
    String userName = 'Khách hàng';
    String userEmail = '';
    if (data['user'] is Map) {
      final u = data['user'] as Map;
      userName = u['fullName']?.toString() ?? userName;
      userEmail = u['email']?.toString() ?? '';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_rounded, color: color),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatCurrency(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: color,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: plan == 'YEAR'
                          ? const Color(0xFFD97706).withValues(alpha: 0.1)
                          : const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      plan == 'YEAR' ? 'VIP NĂM' : 'VIP THÁNG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: plan == 'YEAR'
                            ? const Color(0xFFD97706)
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mã: ${txnRef.length > 12 ? txnRef.substring(0, 12) : txnRef}...',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF10B981);

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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? activeColor : const Color(0xFF475569),
          ),
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

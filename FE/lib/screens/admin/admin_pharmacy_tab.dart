import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_api.dart';
import '../../widgets/pressable.dart';

class AdminPharmacyTab extends StatefulWidget {
  const AdminPharmacyTab({super.key, required this.adminApi});
  final AdminApi adminApi;

  @override
  State<AdminPharmacyTab> createState() => _AdminPharmacyTabState();
}

class _AdminPharmacyTabState extends State<AdminPharmacyTab> {
  int _subTab = 0; // 0: Nhà thuốc, 1: Đơn đặt hàng

  // Pharmacy state
  final _pharmacySearchController = TextEditingController();
  bool _pharmacyLoading = false;
  String? _pharmacyError;
  int _pharmacyPage = 1;
  AdminPagedResponse? _pharmacyResponse;

  // Orders state
  final _orderSearchController = TextEditingController();
  String? _orderStatusFilter;
  bool _orderLoading = false;
  String? _orderError;
  int _orderPage = 1;
  AdminPagedResponse? _orderResponse;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _loadOrders();
  }

  @override
  void dispose() {
    _pharmacySearchController.dispose();
    _orderSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _pharmacyLoading = true;
      _pharmacyError = null;
    });
    try {
      final res = await widget.adminApi.searchPharmacies(
        q: _pharmacySearchController.text.trim().isEmpty
            ? null
            : _pharmacySearchController.text.trim(),
        page: _pharmacyPage,
      );
      if (!mounted) return;
      setState(() {
        _pharmacyResponse = res;
        _pharmacyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pharmacyError = e.toString();
        _pharmacyLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _orderLoading = true;
      _orderError = null;
    });
    try {
      final res = await widget.adminApi.searchOrders(
        q: _orderSearchController.text.trim().isEmpty
            ? null
            : _orderSearchController.text.trim(),
        status: _orderStatusFilter,
        page: _orderPage,
      );
      if (!mounted) return;
      setState(() {
        _orderResponse = res;
        _orderLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orderError = e.toString();
        _orderLoading = false;
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
                  title: 'Nhà thuốc',
                  icon: Icons.local_pharmacy_rounded,
                  active: _subTab == 0,
                  count: _pharmacyResponse?.total,
                  onTap: () => setState(() => _subTab = 0),
                ),
              ),
              Expanded(
                child: _SegmentButton(
                  title: 'Đơn đặt hàng',
                  icon: Icons.shopping_bag_rounded,
                  active: _subTab == 1,
                  count: _orderResponse?.total,
                  onTap: () => setState(() => _subTab = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_subTab == 0) _buildPharmaciesView() else _buildOrdersView(),
      ],
    );
  }

  Widget _buildPharmaciesView() {
    final items = _pharmacyResponse?.items ?? const [];

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
                  controller: _pharmacySearchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên nhà thuốc, SĐT, địa chỉ...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _pharmacySearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _pharmacySearchController.clear();
                              _pharmacyPage = 1;
                              _loadPharmacies();
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
                    _pharmacyPage = 1;
                    _loadPharmacies();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _pharmacyLoading
                  ? null
                  : () {
                      _pharmacyPage = 1;
                      _loadPharmacies();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
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
        const SizedBox(height: 14),

        if (_pharmacyLoading) const LinearProgressIndicator(),
        if (_pharmacyError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Lỗi: $_pharmacyError',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),

        if (_pharmacyResponse != null) ...[
          Text(
            'Tìm thấy ${_pharmacyResponse!.total} nhà thuốc · Trang $_pharmacyPage',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty && !_pharmacyLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy nhà thuốc nào.'),
              ),
            ),
          for (final row in items) ...[
            _PharmacyCard(
              data: row,
              onTap: () => _showPharmacyDetail(row),
            ),
            const SizedBox(height: 10),
          ],
          _PaginationRow(
            page: _pharmacyPage,
            total: _pharmacyResponse!.total,
            limit: _pharmacyResponse!.limit,
            onPrev: _pharmacyPage > 1
                ? () {
                    setState(() => _pharmacyPage--);
                    _loadPharmacies();
                  }
                : null,
            onNext: (_pharmacyResponse!.items.length >=
                    _pharmacyResponse!.limit)
                ? () {
                    setState(() => _pharmacyPage++);
                    _loadPharmacies();
                  }
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildOrdersView() {
    final items = _orderResponse?.items ?? const [];

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
                  controller: _orderSearchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã đơn hàng (orderCode)...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _orderSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _orderSearchController.clear();
                              _orderPage = 1;
                              _loadOrders();
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
                    _orderPage = 1;
                    _loadOrders();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _orderLoading
                  ? null
                  : () {
                      _orderPage = 1;
                      _loadOrders();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
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

        // Status chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tất cả đơn',
                selected: _orderStatusFilter == null,
                onSelected: () {
                  setState(() {
                    _orderStatusFilter = null;
                    _orderPage = 1;
                  });
                  _loadOrders();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Chờ duyệt',
                color: const Color(0xFFF59E0B),
                selected: _orderStatusFilter == 'PENDING_REVIEW',
                onSelected: () {
                  setState(() {
                    _orderStatusFilter = 'PENDING_REVIEW';
                    _orderPage = 1;
                  });
                  _loadOrders();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đang chuẩn bị',
                color: const Color(0xFF8B5CF6),
                selected: _orderStatusFilter == 'PREPARING',
                onSelected: () {
                  setState(() {
                    _orderStatusFilter = 'PREPARING';
                    _orderPage = 1;
                  });
                  _loadOrders();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đang giao',
                color: const Color(0xFF3B82F6),
                selected: _orderStatusFilter == 'SHIPPED',
                onSelected: () {
                  setState(() {
                    _orderStatusFilter = 'SHIPPED';
                    _orderPage = 1;
                  });
                  _loadOrders();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Hoàn tất',
                color: const Color(0xFF10B981),
                selected: _orderStatusFilter == 'COMPLETED',
                onSelected: () {
                  setState(() {
                    _orderStatusFilter = 'COMPLETED';
                    _orderPage = 1;
                  });
                  _loadOrders();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đã hủy',
                color: const Color(0xFFEF4444),
                selected: _orderStatusFilter == 'CANCELLED',
                onSelected: () {
                  setState(() {
                    _orderStatusFilter = 'CANCELLED';
                    _orderPage = 1;
                  });
                  _loadOrders();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_orderLoading) const LinearProgressIndicator(),
        if (_orderError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Lỗi: $_orderError',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),

        if (_orderResponse != null) ...[
          Text(
            'Tìm thấy ${_orderResponse!.total} đơn hàng · Trang $_orderPage',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty && !_orderLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy đơn đặt hàng nào.'),
              ),
            ),
          for (final row in items) ...[
            _OrderCard(
              data: row,
              formatCurrency: _formatCurrency,
              onTap: () => _showOrderDetail(row),
            ),
            const SizedBox(height: 10),
          ],
          _PaginationRow(
            page: _orderPage,
            total: _orderResponse!.total,
            limit: _orderResponse!.limit,
            onPrev: _orderPage > 1
                ? () {
                    setState(() => _orderPage--);
                    _loadOrders();
                  }
                : null,
            onNext: (_orderResponse!.items.length >= _orderResponse!.limit)
                ? () {
                    setState(() => _orderPage++);
                    _loadOrders();
                  }
                : null,
          ),
        ],
      ],
    );
  }

  void _showPharmacyDetail(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PharmacyDetailSheet(
        adminApi: widget.adminApi,
        initialData: row,
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailSheet(
        adminApi: widget.adminApi,
        initialData: row,
        formatCurrency: _formatCurrency,
      ),
    );
  }
}

class _PharmacyDetailSheet extends StatefulWidget {
  const _PharmacyDetailSheet({
    required this.adminApi,
    required this.initialData,
  });

  final AdminApi adminApi;
  final Map<String, dynamic> initialData;

  @override
  State<_PharmacyDetailSheet> createState() => _PharmacyDetailSheetState();
}

class _PharmacyDetailSheetState extends State<_PharmacyDetailSheet> {
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
      final res = await widget.adminApi.getPharmacyDetail(id);
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
    final p = (_detail?['pharmacy'] as Map<String, dynamic>?) ??
        widget.initialData;
    final orders =
        (_detail?['orders'] as Map<String, dynamic>?) ?? const {};
    final byStatus =
        (orders['byStatus'] as Map<String, dynamic>?) ?? const {};

    final id = p['id']?.toString() ?? '';
    final pharmacistId = p['pharmacistId']?.toString() ?? '';
    final name = p['name']?.toString() ?? 'Nhà thuốc';
    final phone = p['phoneNumber']?.toString() ?? '';
    final address = p['addressText']?.toString() ?? 'Chưa cập nhật địa chỉ';
    final lat = p['latitude'];
    final lng = p['longitude'];
    final createdAt = p['createdAt']?.toString();
    final updatedAt = p['updatedAt']?.toString();
    final totalOrders = orders['total'] ?? 0;

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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            phone.isNotEmpty
                                ? 'Hotline: $phone'
                                : 'Chưa có số điện thoại',
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

                // General info box
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
                        'THÔNG TIN CHUNG NHÀ THUỐC',
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
                        label: 'Mã ID nhà thuốc:',
                        value: id,
                        canCopy: id.isNotEmpty,
                        isBold: true,
                        valueColor: const Color(0xFF0284C7),
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Tên nhà thuốc:',
                        value: name,
                        isBold: true,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Mã Dược sĩ phụ trách:',
                        value: pharmacistId,
                        canCopy: pharmacistId.isNotEmpty,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Số điện thoại:',
                        value: phone.isNotEmpty ? phone : 'Chưa cập nhật',
                        canCopy: phone.isNotEmpty,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Địa chỉ hoạt động:',
                        value: address,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Tọa độ vị trí (GPS):',
                        value: lat != null && lng != null
                            ? 'Vĩ độ: $lat, Kinh độ: $lng'
                            : 'Chưa xác định tọa độ',
                      ),
                      if (createdAt != null) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Ngày tham gia:',
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
                const SizedBox(height: 20),

                // Orders Statistics section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'THỐNG KÊ ĐƠN HÀNG (TỔNG: $totalOrders ĐƠN)',
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

                // Grid of status counters
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildStatusCountCard(
                      'Chờ duyệt (PENDING_REVIEW)',
                      byStatus['PENDING_REVIEW'] ?? 0,
                      const Color(0xFFF59E0B),
                      Icons.hourglass_empty_rounded,
                    ),
                    _buildStatusCountCard(
                      'Đang chuẩn bị (PREPARING)',
                      byStatus['PREPARING'] ?? 0,
                      const Color(0xFF3B82F6),
                      Icons.inventory_2_rounded,
                    ),
                    _buildStatusCountCard(
                      'Sẵn sàng lấy (READY_FOR_PICKUP)',
                      byStatus['READY_FOR_PICKUP'] ?? 0,
                      const Color(0xFF6366F1),
                      Icons.storefront_rounded,
                    ),
                    _buildStatusCountCard(
                      'Đang giao (SHIPPED)',
                      byStatus['SHIPPED'] ?? 0,
                      const Color(0xFF06B6D4),
                      Icons.local_shipping_rounded,
                    ),
                    _buildStatusCountCard(
                      'Hoàn thành (COMPLETED)',
                      byStatus['COMPLETED'] ?? 0,
                      const Color(0xFF10B981),
                      Icons.check_circle_rounded,
                    ),
                    _buildStatusCountCard(
                      'Đã hủy (CANCELLED)',
                      byStatus['CANCELLED'] ?? 0,
                      const Color(0xFFEF4444),
                      Icons.cancel_rounded,
                    ),
                  ],
                ),
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

  Widget _buildStatusCountCard(
      String label, dynamic count, Color color, IconData icon) {
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  const _OrderDetailSheet({
    required this.adminApi,
    required this.initialData,
    required this.formatCurrency,
  });

  final AdminApi adminApi;
  final Map<String, dynamic> initialData;
  final String Function(num) formatCurrency;

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
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
      final res = await widget.adminApi.getOrderDetail(id);
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

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      case 'SHIPPED':
        return const Color(0xFF06B6D4);
      case 'READY_FOR_PICKUP':
        return const Color(0xFF6366F1);
      case 'PREPARING':
        return const Color(0xFF3B82F6);
      case 'PENDING_REVIEW':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'SHIPPED':
        return 'Đang giao hàng';
      case 'READY_FOR_PICKUP':
        return 'Sẵn sàng lấy hàng';
      case 'PREPARING':
        return 'Đang chuẩn bị';
      case 'PENDING_REVIEW':
        return 'Chờ duyệt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = (_detail?['order'] as Map<String, dynamic>?) ??
        widget.initialData;
    final items = (_detail?['items'] as List<dynamic>?) ??
        (order['items'] as List<dynamic>?) ??
        const [];

    final id = order['id']?.toString() ?? '';
    final code = order['orderCode']?.toString() ??
        (id.length > 8 ? id.substring(0, 8) : id);
    final patientId = order['patientId']?.toString() ?? '';
    final caregiverId = order['caregiverId']?.toString() ?? '';
    final pharmacyId = order['pharmacyId']?.toString() ?? '';
    final pharmacyName = order['pharmacyName']?.toString();
    final prescriptionId = order['prescriptionId']?.toString();
    final status = order['status']?.toString() ?? 'PENDING_REVIEW';
    final fulfillmentType = order['fulfillmentType']?.toString() ?? 'PICKUP';
    final totalAmount = (order['totalAmount'] as num?) ?? 0;
    final recipientName = order['recipientName']?.toString();
    final recipientPhone = order['recipientPhone']?.toString();
    final deliveryAddress = order['deliveryAddress']?.toString();
    final patientNote = order['patientNote']?.toString();
    final shipperName = order['shipperName']?.toString();
    final shipperPhone = order['shipperPhone']?.toString();
    final rejectionReason = order['rejectionReason']?.toString();
    final createdAt = order['createdAt']?.toString();
    final updatedAt = order['updatedAt']?.toString();

    final statusColor = _statusColor(status);

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

                // Modal Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: statusColor,
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
                                  'Đơn hàng #$code',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
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
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.formatCurrency(totalAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
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

                // Order General Info Section
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
                        'THÔNG TIN ĐƠN ĐẶT HÀNG',
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
                        label: 'Mã đặt hàng (Code):',
                        value: code,
                        canCopy: true,
                        isBold: true,
                        valueColor: const Color(0xFF4F46E5),
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Mã ID đơn hàng:',
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
                      if (caregiverId.isNotEmpty) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Mã người chăm sóc:',
                          value: caregiverId,
                          canCopy: true,
                        ),
                      ],
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Nhà thuốc phục vụ:',
                        value: pharmacyName != null && pharmacyName.isNotEmpty
                            ? '$pharmacyName ($pharmacyId)'
                            : pharmacyId,
                        canCopy: pharmacyId.isNotEmpty,
                      ),
                      if (prescriptionId != null &&
                          prescriptionId.isNotEmpty) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Mã đơn thuốc kèm:',
                          value: prescriptionId,
                          canCopy: true,
                        ),
                      ],
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Hình thức nhận hàng:',
                        value: fulfillmentType == 'PICKUP'
                            ? 'Nhận tại quầy (Tự lấy)'
                            : (fulfillmentType == 'DELIVERY'
                                ? 'Giao hàng tận nơi'
                                : fulfillmentType),
                        isBold: true,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Tổng tiền thanh toán:',
                        value: widget.formatCurrency(totalAmount),
                        isBold: true,
                        valueColor: const Color(0xFF10B981),
                      ),
                      if (createdAt != null) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Thời gian đặt hàng:',
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
                const SizedBox(height: 14),

                // Recipient & Delivery Information Box
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
                        'THÔNG TIN GIAO NHẬN & NGƯỜI NHẬN',
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
                        label: 'Tên người nhận:',
                        value: recipientName != null && recipientName.isNotEmpty
                            ? recipientName
                            : 'Chưa cập nhật',
                        isBold: true,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Số điện thoại:',
                        value: recipientPhone != null &&
                                recipientPhone.isNotEmpty
                            ? recipientPhone
                            : 'Chưa cập nhật',
                        canCopy: recipientPhone != null &&
                            recipientPhone.isNotEmpty,
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _buildFieldRow(
                        context,
                        label: 'Địa chỉ nhận hàng:',
                        value: deliveryAddress != null &&
                                deliveryAddress.isNotEmpty
                            ? deliveryAddress
                            : 'Nhận tại quầy nhà thuốc',
                      ),
                      if (shipperName != null && shipperName.isNotEmpty) ...[
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          context,
                          label: 'Người giao (Shipper):',
                          value: '$shipperName - ${shipperPhone ?? ''}',
                        ),
                      ],
                      if (patientNote != null && patientNote.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.note_alt_outlined,
                                size: 15,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ghi chú người đặt: $patientNote',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (rejectionReason != null &&
                          rejectionReason.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Lý do từ chối / hủy đơn: $rejectionReason',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Items list section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DANH SÁCH SẢN PHẨM / THUỐC (${items.length})',
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
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
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
                      'Đơn hàng không có danh mục sản phẩm cụ thể.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  for (final item in items) ...[
                    _buildOrderItemCard(context, item),
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

  Widget _buildOrderItemCard(BuildContext context, dynamic rawItem) {
    final item = rawItem is Map<String, dynamic>
        ? rawItem
        : <String, dynamic>{};
    final name = item['name'] ?? item['medicineName'] ?? 'Sản phẩm';
    final itemId = item['id']?.toString() ?? '';
    final rxItemId = item['prescriptionItemId']?.toString();
    final unit = item['unit']?.toString() ?? '';
    final quantity = (item['quantity'] as num?) ?? 1;
    final unitPrice = (item['unitPrice'] as num?);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$name',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x$quantity $unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (itemId.isNotEmpty)
            Text(
              'Mã item: $itemId',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          if (rxItemId != null && rxItemId.isNotEmpty)
            Text(
              'Đơn thuốc item: $rxItemId',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          if (unitPrice != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn giá: ${widget.formatCurrency(unitPrice)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Thành tiền: ${widget.formatCurrency(quantity * unitPrice)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
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
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
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

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? 'Nhà thuốc';
    final phone = data['phoneNumber']?.toString();
    final address = data['addressText']?.toString() ?? 'Địa chỉ chưa cập nhật';

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
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Color(0xFF0284C7),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              if (phone != null && phone.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFCBD5E1),
            size: 20,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.data,
    required this.formatCurrency,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final String Function(num) formatCurrency;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      case 'SHIPPED':
        return const Color(0xFF3B82F6);
      case 'PREPARING':
        return const Color(0xFF8B5CF6);
      case 'PENDING_REVIEW':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'SHIPPED':
        return 'Đang giao';
      case 'PREPARING':
        return 'Đang chuẩn bị';
      case 'READY_FOR_PICKUP':
        return 'Chờ lấy';
      case 'PENDING_REVIEW':
        return 'Chờ duyệt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'PENDING_REVIEW';
    final totalAmount = (data['totalAmount'] as num?) ?? 0;
    final id = data['id']?.toString() ?? '';
    final code =
        data['orderCode']?.toString() ??
        (id.length > 8 ? id.substring(0, 8) : id);
    final color = _statusColor(status);

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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: color),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$code',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                formatCurrency(totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đơn đặt thuốc',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
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
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFCBD5E1),
            size: 18,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
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
              color: active ? const Color(0xFF0284C7) : const Color(0xFF64748B),
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
    final activeColor = color ?? const Color(0xFF0284C7);

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
          Flexible(
            child: Text(
              'Trang $page (${(page - 1) * limit + 1} - ${page * limit > total ? total : page * limit} / $total)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

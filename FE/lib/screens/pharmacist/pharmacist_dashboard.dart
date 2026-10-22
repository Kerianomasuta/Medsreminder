import 'package:flutter/material.dart';

import '../../controllers/pharmacist_dashboard_controller.dart';
import '../../models/pharmacist_dashboard.dart';
import '../../widgets/app_components.dart';
import '../../widgets/glass.dart';

/// Danh sách đơn hàng theo tab trạng thái cho Dược sĩ
class PharmacistDashboard extends StatefulWidget {
  const PharmacistDashboard({
    super.key,
    required this.controller,
    this.title = 'Xử lý đơn thuốc',
    this.subtitle = 'Quản lý danh sách đơn hàng theo trạng thái',
    this.onViewDetail,
  });

  final PharmacistDashboardController controller;
  final String title;
  final String subtitle;
  final ValueChanged<PharmacyOrder>? onViewDetail;

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  static const List<({String label, String? status})> _tabs = [
    (label: 'Tất cả', status: null),
    (label: 'Chờ duyệt', status: 'PENDING_REVIEW'),
    (label: 'Đang chuẩn bị', status: 'PREPARING'),
    (label: 'Chờ nhận/Giao', status: 'READY/DELIVERING'),
    (label: 'Hoàn tất', status: 'COMPLETED'),
    (label: 'Đã hủy', status: 'REJECTED'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: _DashboardContent(
        controller: widget.controller,
        tabs: _tabs,
        title: widget.title,
        subtitle: widget.subtitle,
        onViewDetail: widget.onViewDetail,
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.controller,
    required this.tabs,
    required this.title,
    required this.subtitle,
    this.onViewDetail,
  });

  final PharmacistDashboardController controller;
  final List<({String label, String? status})> tabs;
  final String title;
  final String subtitle;
  final ValueChanged<PharmacyOrder>? onViewDetail;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  TabController? _tabController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    // Gọi tải danh sách đơn hàng ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.fetchOrdersByStatus(widget.tabs[0].status);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (_tabController != newController) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = newController;
      _tabController?.addListener(_handleTabChange);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    final tabController = _tabController;
    if (tabController == null) return;
    final index = tabController.index;
    if (index != _lastIndex && !tabController.indexIsChanging) {
      _lastIndex = index;
      widget.controller.fetchOrdersByStatus(widget.tabs[index].status);
    }
  }

  void _onTabTapped(int index) {
    if (index != _lastIndex) {
      _lastIndex = index;
      widget.controller.fetchOrdersByStatus(widget.tabs[index].status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E284A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF687195),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Làm mới danh sách',
                onPressed: widget.controller.loading
                    ? null
                    : widget.controller.refreshOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: _onTabTapped,
          indicatorColor: const Color(0xFF556AF4),
          indicatorWeight: 3,
          labelColor: const Color(0xFF556AF4),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            for (final tab in widget.tabs)
              Tab(text: tab.label),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              for (final _ in widget.tabs)
                _OrdersListTab(
                  controller: widget.controller,
                  onViewDetail: widget.onViewDetail,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersListTab extends StatelessWidget {
  const _OrdersListTab({
    required this.controller,
    this.onViewDetail,
  });

  final PharmacistDashboardController controller;
  final ValueChanged<PharmacyOrder>? onViewDetail;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading && controller.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null && controller.orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFD75F4D),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD75F4D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: controller.refreshOrders,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Text(
                    'Không có đơn hàng nào ở trạng thái này',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF717D96),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshOrders,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: controller.orders.length,
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrderCard(
                  order: order,
                  onTapDetail: () {
                    if (onViewDetail != null) {
                      onViewDetail!(order);
                    } else {
                      _showDetailPopup(context, order, controller);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDetailPopup(
    BuildContext context,
    PharmacyOrder order,
    PharmacistDashboardController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailBottomSheet(
        order: order,
        controller: controller,
      ),
    );
  }
}

/// Thẻ đơn hàng (Order Card) với hiệu ứng kính mờ Glassmorphism
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onTapDetail,
  });

  final PharmacyOrder order;
  final VoidCallback? onTapDetail;

  Color get statusColor => switch (order.status) {
    PharmacyOrderStatus.pendingReview => const Color(0xFFE88C44),
    PharmacyOrderStatus.preparing => const Color(0xFF556AF4),
    PharmacyOrderStatus.readyForPickup => const Color(0xFF8B5CF6),
    PharmacyOrderStatus.shipped => const Color(0xFF0E9F8A),
    PharmacyOrderStatus.completed => const Color(0xFF269E77),
    PharmacyOrderStatus.cancelled => const Color(0xFFD75F4D),
  };

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Không rõ';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$hour:$minute · $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final orderCode =
        order.orderCode.isNotEmpty ? order.orderCode : '#MR-${order.id}';

    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  orderCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E284A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(order.status.label, statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: Color(0xFF717D96),
              ),
              const SizedBox(width: 6),
              Text(
                'Thời gian đặt: ${_formatDateTime(order.createdAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF717D96),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onTapDetail,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: Color(0xFF556AF4),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF556AF4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailBottomSheet extends StatelessWidget {
  const _OrderDetailBottomSheet({
    required this.order,
    required this.controller,
  });

  final PharmacyOrder order;
  final PharmacistDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đơn hàng ${order.orderCode}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              if (order.items.isNotEmpty) ...[
                const Text(
                  'Danh sách thuốc:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${item.quantity} ${item.unit}'),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              if (order.recipientName?.isNotEmpty == true)
                Text('Người nhận: ${order.recipientName}'),
              if (order.recipientPhone?.isNotEmpty == true)
                Text('Số điện thoại: ${order.recipientPhone}'),
              if (order.deliveryAddress?.isNotEmpty == true)
                Text('Địa chỉ: ${order.deliveryAddress}'),
              if (order.patientNote?.isNotEmpty == true)
                Text('Ghi chú: ${order.patientNote}'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

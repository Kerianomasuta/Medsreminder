import 'package:flutter/material.dart';

import '../../controllers/pharmacist_dashboard_controller.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class PharmacistHome extends StatelessWidget {
  const PharmacistHome({
    super.key,
    required this.tab,
    required this.controller,
  });

  final int tab;
  final PharmacistDashboardController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.loading && controller.orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return switch (tab) {
        0 => _OrdersPage(controller: controller, history: false),
        _ => _OrdersPage(controller: controller, history: true),
      };
    },
  );
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.controller,
    required this.title,
    required this.subtitle,
  });

  final PharmacistDashboardController controller;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: PageIntro(title, subtitle)),
          IconButton.filledTonal(
            tooltip: 'Làm mới dữ liệu',
            onPressed: controller.loading
                ? null
                : () => controller.initialize(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      if (controller.error != null) ...[
        const SizedBox(height: 10),
        _ErrorBanner(message: controller.error!),
      ],
      const SizedBox(height: 14),
    ],
  );
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.controller, required this.history});

  final PharmacistDashboardController controller;
  final bool history;

  @override
  Widget build(BuildContext context) {
    final orders = history ? controller.historyOrders : controller.activeOrders;
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(
            controller: controller,
            title: history ? 'Lịch sử đơn thuốc' : 'Xử lý đơn thuốc',
            subtitle: history
                ? '${orders.length} đơn đã hoàn tất hoặc huỷ'
                : '${orders.length} đơn đang cần nhà thuốc xử lý',
          ),
          if (orders.isEmpty)
            _EmptyCard(
              icon: history ? Icons.history_rounded : Icons.inbox_rounded,
              title: history ? 'Chưa có lịch sử đơn' : 'Không có đơn đang chờ',
              subtitle: 'Dữ liệu được lấy trực tiếp từ tài khoản dược sĩ đang đăng nhập.',
            )
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(order: order, controller: controller),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.controller});

  final PharmacyOrder order;
  final PharmacistDashboardController controller;

  Color get color => switch (order.status) {
    PharmacyOrderStatus.pendingReview => const Color(0xFFE88C44),
    PharmacyOrderStatus.preparing => const Color(0xFF556AF4),
    PharmacyOrderStatus.readyForPickup => const Color(0xFF8B5CF6),
    PharmacyOrderStatus.shipped => const Color(0xFF0E9F8A),
    PharmacyOrderStatus.completed => const Color(0xFF269E77),
    PharmacyOrderStatus.cancelled => const Color(0xFFD75F4D),
  };

  @override
  Widget build(BuildContext context) => Glass(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      shape: const RoundedRectangleBorder(),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(Icons.receipt_long_rounded, color: color),
      ),
      title: Text(
        order.orderCode,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${order.fulfillmentType.label} · ${order.items.length} loại thuốc',
      ),
      trailing: StatusChip(order.status.label, color),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Divider(),
        ...order.items.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.medication_rounded),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${item.quantity} ${item.unit}'),
          ),
        ),
        if (order.patientNote?.isNotEmpty == true)
          _InfoLine(label: 'Ghi chú', value: order.patientNote!),
        if (order.deliveryAddress?.isNotEmpty == true)
          _InfoLine(label: 'Địa chỉ', value: order.deliveryAddress!),
        if (order.rejectionReason?.isNotEmpty == true)
          _InfoLine(label: 'Lý do', value: order.rejectionReason!),
        const SizedBox(height: 10),
        _OrderActions(order: order, controller: controller),
      ],
    ),
  );
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order, required this.controller});

  final PharmacyOrder order;
  final PharmacistDashboardController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.saving || order.isHistory) return const SizedBox.shrink();
    final buttons = <Widget>[];
    if (order.status == PharmacyOrderStatus.pendingReview) {
      buttons.add(
        FilledButton.icon(
          onPressed: () =>
              _run(context, () => controller.acceptOrder(order.id)),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Nhận đơn'),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _reason(context, reject: true),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Từ chối'),
        ),
      );
    } else if (order.status == PharmacyOrderStatus.preparing) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => order.fulfillmentType == FulfillmentType.pickup
              ? _run(context, () => controller.markReady(order.id))
              : _ship(context),
          icon: Icon(
            order.fulfillmentType == FulfillmentType.pickup
                ? Icons.storefront_rounded
                : Icons.local_shipping_rounded,
          ),
          label: Text(
            order.fulfillmentType == FulfillmentType.pickup
                ? 'Sẵn sàng nhận'
                : 'Bàn giao shipper',
          ),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () => _reason(context, reject: false),
          child: const Text('Huỷ đơn'),
        ),
      );
    }
    return Wrap(spacing: 10, runSpacing: 8, children: buttons);
  }

  Future<void> _reason(BuildContext context, {required bool reject}) async {
    final reason = await _textDialog(
      context,
      title: reject ? 'Từ chối đơn' : 'Huỷ đơn',
      label: 'Lý do',
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => reject
          ? controller.rejectOrder(order.id, reason)
          : controller.cancelOrder(order.id, reason),
    );
  }

  Future<void> _ship(BuildContext context) async {
    final result = await _shipperDialog(context);
    if (result == null || !context.mounted) return;
    await _run(
      context,
      () => controller.shipOrder(
        order.id,
        shipperName: result.$1,
        shipperPhone: result.$2,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF66738A)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF66738A)),
          ),
        ],
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF66738A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9EC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF9B3340))),
  );
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật thành công.')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final value = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _ControllerOwner(
      controllers: [value],
      child: AlertDialog(
        title: Text(title),
        content: TextField(
          controller: value,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              if (value.text.trim().isNotEmpty) {
                Navigator.pop(context, value.text.trim());
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ),
  );
  return result;
}

Future<(String, String)?> _shipperDialog(BuildContext context) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => _ControllerOwner(
      controllers: [name, phone],
      child: AlertDialog(
        title: const Text('Bàn giao cho shipper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Tên shipper'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty && phone.text.trim().isNotEmpty) {
                Navigator.pop(context, (name.text.trim(), phone.text.trim()));
              }
            },
            child: const Text('Bàn giao'),
          ),
        ],
      ),
    ),
  );
  return result;
}

class _ControllerOwner extends StatefulWidget {
  const _ControllerOwner({required this.controllers, required this.child});

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_ControllerOwner> createState() => _ControllerOwnerState();
}

class _ControllerOwnerState extends State<_ControllerOwner> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

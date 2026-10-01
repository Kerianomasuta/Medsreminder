import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class ShipperHome extends StatelessWidget {
  const ShipperHome({
    super.key,
    required this.tab,
    required this.orderStage,
    required this.onOrderStageChanged,
  });

  final int tab;
  final OrderStage orderStage;
  final ValueChanged<OrderStage> onOrderStageChanged;

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro('Chào Huy!', 'Bạn có 2 chuyến giao hôm nay'),
        Glass(
          padding: const EdgeInsets.all(17),
          gradient: const LinearGradient(
            colors: [Color(0xFF5469F5), Color(0xFF739BEC)],
          ),
          child: const Row(
            children: [
              Icon(Icons.route_rounded, color: Colors.white, size: 35),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điểm giao tiếp theo',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Nhà cô Nguyễn Thị Lan',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '#MR-20260916-018',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  StatusChip(stageText(orderStage), stageColor(orderStage)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '12 Nguyễn Huệ, P. Bến Nghé, Q.1\nNgười nhận: Cô Lan / chị Minh Anh · 090 123 4567',
              ),
              const Divider(height: 25),
              const Row(
                children: [
                  Icon(Icons.medication_rounded, color: Color(0xFF5066F5)),
                  SizedBox(width: 9),
                  Text('3 loại thuốc · Thanh toán online'),
                ],
              ),
              const SizedBox(height: 15),
              if (orderStage == OrderStage.verified)
                FilledButton.icon(
                  onPressed: () => onOrderStageChanged(OrderStage.pickedUp),
                  icon: const Icon(Icons.inventory_rounded),
                  label: const Text('Xác nhận đã lấy đơn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(47),
                  ),
                ),
              if (orderStage == OrderStage.pickedUp)
                FilledButton.icon(
                  onPressed: () => onOrderStageChanged(OrderStage.delivering),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Bắt đầu giao hàng'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(47),
                  ),
                ),
              if (orderStage == OrderStage.delivering)
                FilledButton.icon(
                  onPressed: () => onOrderStageChanged(OrderStage.delivered),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Xác nhận đã giao thuốc'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(47),
                  ),
                ),
              if (orderStage == OrderStage.delivered)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Đơn đã giao thành công ✓',
                      style: TextStyle(
                        color: Color(0xFF21996E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

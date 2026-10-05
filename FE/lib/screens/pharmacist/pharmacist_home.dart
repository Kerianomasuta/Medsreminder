import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class PharmacistHome extends StatelessWidget {
  const PharmacistHome({
    super.key,
    required this.tab,
    required this.orderStage,
    required this.onOrderStageChanged,
  });

  final int tab;
  final OrderStage orderStage;
  final ValueChanged<OrderStage> onOrderStageChanged;

  @override
  Widget build(BuildContext context) {
    if (tab == 1) return const WarehousePage();
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro('Quầy dược An Tâm', 'Có 3 đơn cần xử lý hôm nay'),
          Glass(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFF5066F5),
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Đơn #MR-20260916-018\nNguyễn Thị Lan · Từ Trần Minh Anh',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusChip(stageText(orderStage), stageColor(orderStage)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kiểm tra đơn thuốc',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CheckLine('Đơn bác sĩ hợp lệ', true),
                const CheckLine('Không trùng hoạt chất', true),
                const CheckLine('Tương tác thuốc: thấp', true),
                const Divider(height: 25),
                const Text(
                  'Thuốc trong đơn',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const SmallDrug(
                  'Metformin 500mg',
                  '60 viên',
                  'Có sẵn · 42 hộp',
                ),
                const SmallDrug(
                  'Vitamin D3 1000IU',
                  '30 viên',
                  'Có sẵn · 18 hộp',
                ),
                const SmallDrug(
                  'Amlodipine 5mg',
                  '30 viên',
                  'Sắp hết · 5 hộp',
                ),
                const SizedBox(height: 12),
                if (orderStage == OrderStage.review)
                  FilledButton.icon(
                    onPressed: () {
                      onOrderStageChanged(OrderStage.verified);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đơn đã được duyệt và chuyển kho.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Duyệt & chuyển kho'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                if (orderStage == OrderStage.verified)
                  FilledButton.icon(
                    onPressed: () => onOrderStageChanged(OrderStage.pickedUp),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('Bàn giao cho shipper'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WarehousePage extends StatelessWidget {
  const WarehousePage({super.key});

  @override
  Widget build(BuildContext context) => const AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageIntro('Kho thuốc', 'Cập nhật lúc 08:15 hôm nay'),
        InventoryItem(
          'Metformin 500mg',
          '42 hộp',
          'Đủ hàng',
          .74,
          Color(0xFF269E77),
        ),
        InventoryItem(
          'Vitamin D3 1000IU',
          '18 hộp',
          'Đủ hàng',
          .43,
          Color(0xFF556AF4),
        ),
        InventoryItem(
          'Amlodipine 5mg',
          '5 hộp',
          'Sắp hết',
          .13,
          Color(0xFFE88C44),
        ),
        InventoryItem(
          'Atorvastatin 10mg',
          '0 hộp',
          'Hết hàng',
          0,
          Color(0xFFD75F4D),
        ),
      ],
    ),
  );
}

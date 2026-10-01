import 'package:flutter/material.dart';
import '../widgets/custom_components.dart';

/// Màn hình 4: Theo Dõi Trực Tiếp Lộ Trình Giao Thuốc (Live Tracking)
class CaregiverTrackingScreen extends StatelessWidget {
  final VoidCallback onReceiptConfirmed;

  const CaregiverTrackingScreen({
    super.key,
    required this.onReceiptConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // Header cổng theo dõi
          const CustomHeaderAppBar(
            subtitle: 'Trạng Thái Giao Hàng',
            title: 'Theo Dõi Trực Tiếp',
            roleBadge: '👤 Vai trò: Người chăm sóc',
            backgroundColor: Color(0xFF1A56DB),
          ),

          // Nửa trên: Bản đồ lộ trình y tế trực quan
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Bản đồ vẽ bằng CustomPaint
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: ClinicalMapPainter(),
                  ),
                ),

                // Huy hiệu ETA nổi phía trên bên trái
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Tài xế đến sau: 5 phút',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Huy hiệu Nhiệt độ chuỗi lạnh bên phải
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF34D399)),
                        SizedBox(width: 6),
                        Text(
                          'Thùng lạnh 3.8°C',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nửa dưới: Bảng thông tin vuốt lên (Bottom Sheet)
          Expanded(
            flex: 6,
            child: Container(
              transform: Matrix4.translationValues(0, -18, 0),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thanh kéo bo tròn
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hồ sơ tài xế giao hàng (James Rivera)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Center(
                                child: Text(
                                  'JR',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'James Rivera',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.check_circle, size: 14, color: Color(0xFF2563EB)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '★ 4.97 (840+ chuyến giao y tế)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // 2 Nút gọi điện & nhắn tin
                        Row(
                          children: [
                            _buildCircleIconButton(
                              icon: Icons.phone_rounded,
                              backgroundColor: const Color(0xFFF3F4F6),
                              iconColor: const Color(0xFF374151),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đang kết nối cuộc gọi đến tài xế James Rivera...')),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildCircleIconButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              backgroundColor: const Color(0xFFEFF6FF),
                              iconColor: const Color(0xFF2563EB),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đang mở hộp thoại tin nhắn với tài xế...')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFF3F4F6), height: 1),
                    ),

                    // Dòng thời gian tiến độ giao thuốc
                    _buildTimelineRow(
                      isPassed: true,
                      title: 'Đã thẩm định bởi Dược sĩ',
                      time: '14:20',
                    ),
                    const SizedBox(height: 10),
                    _buildTimelineRow(
                      isPassed: true,
                      title: 'Đã xuất kho P-Warehouse Cửa 4',
                      time: '14:35',
                    ),
                    const SizedBox(height: 10),
                    _buildTimelineRow(
                      isCurrent: true,
                      title: 'Đang giao hàng (Gần đường Sunrise Ave)',
                      time: 'Hiện tại',
                    ),
                    const SizedBox(height: 14),

                    // Khối xác nhận "Thuốc đã đến nơi"
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF059669)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Thuốc Đã Đến Nơi!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF064E3B),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Đang ở trước cửa',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vui lòng xác nhận bạn đã nhận đủ thuốc Aspirin 81mg từ tài xế James Rivera.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomPrimaryButton(
                            label: 'Xác Nhận Đã Nhận Thuốc',
                            icon: Icons.check,
                            backgroundColor: const Color(0xFF059669),
                            onPressed: () {
                              onReceiptConfirmed();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF059669),
                                  content: Text('✓ Đã xác nhận bàn giao thuốc thành công! Hoàn tất chu trình.'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  Widget _buildTimelineRow({
    bool isPassed = false,
    bool isCurrent = false,
    required String title,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isPassed
                ? const Color(0xFFD1FAE5)
                : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isPassed
                ? const Icon(Icons.check, size: 11, color: Color(0xFF047857))
                : (isCurrent
                ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            )
                : const SizedBox.shrink()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isPassed
                  ? const Color(0xFF6B7280)
                  : (isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF9CA3AF)),
              decoration: isPassed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/custom_components.dart';

/// Màn hình 2: Quy trình Xác minh & Phê duyệt của Dược sĩ (Pharmacist)
class PharmacistVerificationScreen extends StatelessWidget {
  final VoidCallback onApproveAndDispatch;

  const PharmacistVerificationScreen({
    super.key,
    required this.onApproveAndDispatch,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // Header cổng dược sĩ
          const CustomHeaderAppBar(
            subtitle: 'Hàng Đợi Cấp Phát',
            title: 'Cổng Dược Sĩ',
            roleBadge: '🩺 Vai trò: Dược sĩ',
            backgroundColor: Color(0xFF1A56DB),
          ),

          // Nội dung danh sách xác minh
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                // Thẻ thông tin kép: Yêu cầu của bệnh nhân & File đính kèm
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Phần trên: Thông tin bệnh nhân & Nhãn khẩn cấp
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YÊU CẦU BỆNH NHÂN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9CA3AF),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Margaret Chen, 72 tuổi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Đơn thuốc #9042-DS • Aspirin 81mg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFFDC2626)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Khẩn cấp',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),

                      // Phần dưới: Thông tin file đính kèm
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_outlined, size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text(
                                  'Rx_Chen_Aspirin.pdf',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Đã cấp phép 14:15',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Thẻ Danh sách Kiểm tra Xác minh (Verification Checklist)
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DANH MỤC KIỂM TRA XÁC MINH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mục 1: Đơn thuốc hợp lệ
                      _buildChecklistRow(
                        title: 'Đơn thuốc điện tử đã thẩm định',
                        subtitle: 'Chữ ký số mật mã xác thực bởi BS. Sarah Patel.',
                      ),
                      const SizedBox(height: 14),

                      // Mục 2: Kho còn hàng
                      _buildChecklistRow(
                        title: 'Kho P-Warehouse còn hàng',
                        subtitle: 'Ngăn A-14 • Lô #ASP-2024-91 (90 viên bao tan trong ruột).',
                      ),
                      const SizedBox(height: 14),

                      // Mục 3: Kiểm tra bảo hiểm y tế
                      _buildChecklistRow(
                        title: 'Kiểm tra bảo hiểm y tế',
                        subtitle: 'Bảo hiểm Medicare Part D hợp lệ • Đồng chi trả \$0.00 đã duyệt.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Huy hiệu chỉ định đơn vị vận chuyển
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text(
                            'Tài xế đã chỉ định: James Rivera',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Cửa nhận số 4',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Nút hành động cố định: Duyệt và điều phối
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: CustomPrimaryButton(
          label: '➔ Phê Duyệt & Điều Phối Giao Hàng',
          backgroundColor: const Color(0xFF1A56DB),
          onPressed: onApproveAndDispatch,
        ),
      ),
    );
  }

  Widget _buildChecklistRow({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 13,
            color: Color(0xFF047857),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

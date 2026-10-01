import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import 'medicine_catalog_page.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({
    super.key,
    required this.tab,
    required this.doseTaken,
    required this.doseMissed,
    required this.onTaken,
    this.prescriptionAdded = false,
    this.onPrescriptionAdded,
    this.isLinked = true,
    this.linkedPatientCode = 'PA-8899',
  });

  final int tab;
  final bool doseTaken, doseMissed, prescriptionAdded, isLinked;
  final String linkedPatientCode;
  final VoidCallback onTaken;
  final VoidCallback? onPrescriptionAdded;

  @override
  Widget build(BuildContext context) {
    if (tab == 1) return const MedicineCatalogPage();

    if (tab == 1) {
      return AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              'Uống thuốc theo đơn',
              'Chi tiết đơn thuốc và cữ uống của cô Lan',
            ),
            const Glass(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE7E9FF),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Color(0xFF5267F4),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Người chăm sóc: Trần Minh Anh (Con gái)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Đã liên kết · Đang đồng bộ đơn thuốc',
                          style: TextStyle(
                            color: Color(0xFF249D76),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, color: Color(0xFF249D76)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cữ thuốc cần uống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            DoseCard(taken: doseTaken, missed: doseMissed, onTaken: onTaken),
            const SizedBox(height: 18),
            const Text(
              'Toa thuốc đang điều trị',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const PrescriptionCard(
              'Liệu trình huyết áp & tiểu đường',
              '16/09 - 16/10/2026',
              '3 thuốc · 3 khung giờ (Sáng, Trưa, Tối)',
            ),
            if (prescriptionAdded) ...[
              const SizedBox(height: 10),
              const PrescriptionCard(
                'Vitamin tổng hợp',
                '16/09 - 16/11/2026',
                '1 thuốc · 08:00 sáng',
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => showAddMedicineModal(
                context,
                onAdded: () => onPrescriptionAdded?.call(),
                isPatient: true,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Thêm thuốc mới / thuốc ngoài đơn'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 14),
            const Glass(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF5267F4),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lưu ý: Uống thuốc đúng giờ sau bữa ăn. Bấm "Tôi đã uống đủ thuốc" để tự động thông báo đến người chăm sóc.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (tab == 2) {
      return AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro('Lịch uống thuốc', 'Thứ Hai, 16 tháng 9'),
            const DayStrip(),
            const SizedBox(height: 18),
            TimelineItem(
              '07:30',
              'Sáng',
              'Metformin · Vitamin D3',
              doseTaken ? 'Đã hoàn thành' : 'Đã đến giờ',
              doseTaken ? const Color(0xFF259F78) : const Color(0xFF5469F5),
            ),
            const TimelineItem(
              '12:30',
              'Trưa',
              'Amlodipine 5mg',
              'Sắp tới',
              Color(0xFFF0A042),
            ),
            const TimelineItem(
              '20:00',
              'Tối',
              'Atorvastatin 10mg',
              'Sắp tới',
              Color(0xFF9A72DB),
            ),
          ],
        ),
      );
    }
    if (tab == 3) {
      return AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              'Hồ sơ sức khoẻ',
              'Thông tin cá nhân & mã liên kết',
            ),
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: Color(0xFF5267F4),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Mã liên kết của bạn',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      StatusChip(
                        isLinked ? 'Đã liên kết' : 'Chưa liên kết',
                        isLinked
                            ? const Color(0xFF249D76)
                            : const Color(0xFFF09B3C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        linkedPatientCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5065F2),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLinked
                        ? 'Đã kết nối với người chăm sóc: Trần Minh Anh (Con gái).'
                        : 'Đưa mã này cho người chăm sóc để liên kết tài khoản và nhận lịch nhắc thuốc.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E7590),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Glass(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: Color(0xFFFFD9C6),
                    child: Icon(
                      Icons.face_3_rounded,
                      size: 38,
                      color: Color(0xFFAD6047),
                    ),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyễn Thị Lan',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('72 tuổi · Nhóm máu O+'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Glass(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Người liên hệ khẩn cấp',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Trần Minh Anh'),
                    subtitle: Text('Con gái · 090 123 4567'),
                    trailing: Icon(
                      Icons.call_rounded,
                      color: Color(0xFF5065F2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Glass(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: Color(0xFF5065F2)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Âm lượng chuông nhắc',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Đang đặt mức tối đa cho người lớn tuổi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF717993),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip('Tối đa', Color(0xFF249D76)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro(
            'Chào buổi sáng, cô Lan',
            'Hôm nay là một ngày tuyệt vời',
          ),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF5368F4), Color(0xFF8068DD)],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFFFE39A),
                  size: 35,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '16 tháng 9',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Hôm nay có 3 liều thuốc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (doseMissed) const EmergencyPatientCard(),
          Text(
            doseTaken ? 'Tuyệt vời, cô đã hoàn thành!' : 'Đến giờ uống thuốc',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DoseCard(taken: doseTaken, missed: doseMissed, onTaken: onTaken),
          const SizedBox(height: 20),
          const Text(
            'Tiến độ hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: doseTaken ? .34 : 0.0,
                        strokeWidth: 7,
                        backgroundColor: const Color(0xFFE6E8F8),
                      ),
                      Text(
                        doseTaken ? '1/3' : '0/3',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chăm sóc sức khoẻ mỗi ngày',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 3),
                      Text('Còn 2 liều thuốc trong hôm nay'),
                    ],
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

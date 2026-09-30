import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key, required this.doseMissed});
  final bool doseMissed;

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Trung tâm điều hành',
          'Tổng quan hệ thống MedsReminder',
        ),
        const Row(
          children: [
            MetricCard(
              '1,248',
              'Bệnh nhân',
              Icons.favorite_rounded,
              Color(0xFF566BF5),
            ),
            SizedBox(width: 10),
            MetricCard(
              '96.8%',
              'Tuân thủ',
              Icons.trending_up_rounded,
              Color(0xFF28A378),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const MetricCard(
              '87',
              'Người chăm sóc',
              Icons.volunteer_activism_rounded,
              Color(0xFF9A70DB),
            ),
            const SizedBox(width: 10),
            MetricCard(
              doseMissed ? '1' : '0',
              'Cảnh báo mới',
              Icons.warning_rounded,
              const Color(0xFFD65E4A),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Glass(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              ActivityItem(
                Icons.check_circle_rounded,
                'Cô Nguyễn Thị Lan đã uống liều sáng',
                '07:38',
                Color(0xFF28A378),
              ),
              ActivityItem(
                Icons.link_rounded,
                'Một tài khoản PA vừa được liên kết',
                '07:20',
                Color(0xFF556AF4),
              ),
              ActivityItem(
                Icons.local_shipping_rounded,
                'Đơn #MR-018 được tạo',
                '07:06',
                Color(0xFF9A70DB),
              ),
            ],
          ),
        ),
        if (doseMissed)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: AlertCard(),
          ),
      ],
    ),
  );
}

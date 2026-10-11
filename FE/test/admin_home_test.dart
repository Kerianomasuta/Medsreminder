import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/screens/admin/admin_home.dart';

void main() {
  testWidgets('AdminHome renders complete dashboard matching design mockup', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHome(),
      ),
    );

    // Header checks
    expect(find.text('MedsReminder'), findsOneWidget);
    expect(find.text('Nhắc thuốc đều đều, sức khỏe thêm nhiều.'), findsOneWidget);
    expect(find.text('Quy chợ lớn'), findsOneWidget);

    // Title checks
    expect(find.text('Trung tâm điều hành'), findsOneWidget);
    expect(find.text('Tổng quan hệ thống MedsReminder'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);

    // Stats Grid checks
    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('Bệnh nhân'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

    expect(find.text('96.8%'), findsOneWidget);
    expect(find.text('Tuân thủ'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);

    expect(find.text('87'), findsOneWidget);
    expect(find.text('Người chăm sóc'), findsOneWidget);
    expect(find.byIcon(Icons.volunteer_activism_rounded), findsOneWidget);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('Cảnh báo mới'), findsOneWidget);
    expect(find.byIcon(Icons.warning_rounded), findsOneWidget);

    // Recent Activities checks
    expect(find.text('Hoạt động gần đây'), findsOneWidget);
    expect(find.text('Cô Nguyễn Thị Lan đã uống liều sáng'), findsOneWidget);
    expect(find.text('07:38'), findsOneWidget);
    expect(find.text('Một tài khoản PA vừa được liên kết'), findsOneWidget);
    expect(find.text('07:20'), findsOneWidget);
    expect(find.text('Đơn #MR-018 được tạo'), findsOneWidget);
    expect(find.text('07:06'), findsOneWidget);

    // Floating Action Button check
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Bottom Navigation Bar tabs check
    expect(find.text('Hệ thống'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Cảnh báo'), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

    // Tap on second tab
    await tester.pump(const Duration(milliseconds: 300));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/widgets/patient_qr_code_card.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('PatientQrCodeCard renders QR code, patient info and handles refresh', (
    tester,
  ) async {
    bool refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientQrCodeCard(
            invitationUuid: '550e8400-e29b-41d4-a716-446655440000',
            invitationLink:
                'https://medsreminder.app/invitation?invitationUUID=550e8400-e29b-41d4-a716-446655440000',
            patientName: 'Nguyễn Văn A',
            createdAt: DateTime.now(),
            onRefresh: () => refreshed = true,
          ),
        ),
      ),
    );

    // Verify QR code is rendered
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Mã QR kết nối người chăm sóc'), findsOneWidget);
    expect(find.text('Nguyễn Văn A'), findsOneWidget);

    // Verify toggle for raw UUID
    expect(find.text('Xem mã văn bản (sao chép)'), findsOneWidget);
    await tester.tap(find.text('Xem mã văn bản (sao chép)'));
    await tester.pump();
    expect(find.text('550e8400-e29b-41d4-a716-446655440000'), findsOneWidget);

    // Verify refresh button
    expect(find.text('Làm mới'), findsOneWidget);
    await tester.tap(find.text('Làm mới'));
    expect(refreshed, isTrue);
  });
}

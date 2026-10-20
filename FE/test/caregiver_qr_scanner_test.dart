import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/widgets/caregiver_qr_scanner_sheet.dart';

void main() {
  testWidgets('CaregiverQrScannerSheet switches to manual mode and enters UUID', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: CaregiverQrScannerSheet(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Quét mã QR bệnh nhân'), findsOneWidget);
    expect(find.text('Nhập mã thủ công'), findsOneWidget);

    // Switch to manual input mode
    await tester.tap(find.text('Nhập mã thủ công'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nhập mã kết nối bệnh nhân'), findsOneWidget);

    // Enter a full invitation URL into the text field
    const testUrl =
        'https://medsreminder.app/invitation?invitationUUID=550e8400-e29b-41d4-a716-446655440000';
    await tester.enterText(find.byType(TextField), testUrl);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(testUrl), findsOneWidget);
    expect(find.text('Xác nhận kết nối'), findsOneWidget);
  });
}

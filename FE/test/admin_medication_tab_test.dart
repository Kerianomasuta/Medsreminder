import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/screens/admin/admin_medication_tab.dart';
import 'package:meds_reminder/services/admin_api.dart';

void main() {
  group('AdminMedicationTab tests', () {
    testWidgets('displays prescription list, shows full fields on detail modal, and logs search bar', (
      tester,
    ) async {
      http.Response jsonUtf8(dynamic data, int statusCode) {
        return http.Response.bytes(
          utf8.encode(jsonEncode(data)),
          statusCode,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/prescriptions') {
          return jsonUtf8({
            'page': 1,
            'limit': 20,
            'total': 1,
            'prescriptions': [
              {
                'id': 'rx-uuid-1234',
                'patientId': '6abbd74f1234567890abcdef',
                'createdByCgId': '6abbd74f9999999999abcdef',
                'title': 'Đơn thuốc hạ sốt',
                'doctorName': 'Nguyễn Văn A',
                'prescriptionCode': 'DT-2026-001',
                'startDate': '2026-10-01',
                'endDate': '2026-10-30',
                'isActive': true,
                'createdAt': '2026-10-01T08:00:00.000Z',
                'updatedAt': '2026-10-02T09:00:00.000Z',
              }
            ],
          }, 200);
        }
        if (request.url.path == '/api/v1/admin/prescriptions/rx-uuid-1234') {
          return jsonUtf8({
            'prescription': {
              'id': 'rx-uuid-1234',
              'patientId': '6abbd74f1234567890abcdef',
              'createdByCgId': '6abbd74f9999999999abcdef',
              'title': 'Đơn thuốc hạ sốt',
              'doctorName': 'Nguyễn Văn A',
              'prescriptionCode': 'DT-2026-001',
              'startDate': '2026-10-01',
              'endDate': '2026-10-30',
              'isActive': true,
              'createdAt': '2026-10-01T08:00:00.000Z',
              'updatedAt': '2026-10-02T09:00:00.000Z',
            },
            'items': [
              {
                'id': 'item-1',
                'name': 'Paracetamol 500mg',
                'genericName': 'Acetaminophen',
                'unit': 'VIEN',
                'dosagePerTime': 1.0,
                'currentStock': 20,
                'reorderThreshold': 5,
                'instructions': 'Uống sau ăn no với nhiều nước',
                'schedules': [
                  {
                    'id': 'sched-1',
                    'reminderTime': '08:00:00',
                    'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
                    'isActive': true,
                  }
                ],
              }
            ],
          }, 200);
        }
        if (request.url.path == '/api/v1/admin/medication-logs') {
          return jsonUtf8({
            'page': 1,
            'limit': 20,
            'total': 1,
            'logs': [
              {
                'id': 'log-1',
                'patientId': '6abbd74f1234567890abcdef',
                'medicineName': 'Paracetamol 500mg',
                'scheduledAt': '2026-10-16T08:00:00.000Z',
                'actualTakenAt': '2026-10-16T08:05:00.000Z',
                'status': 'TAKEN',
              }
            ],
          }, 200);
        }
        return http.Response('Not Found', 404);
      });

      final adminApi = AdminApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminMedicationTab(adminApi: adminApi),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Prescriptions list is shown
      expect(find.text('Đơn thuốc hạ sốt'), findsOneWidget);
      expect(find.text('BS. Nguyễn Văn A'), findsOneWidget);

      // Tap prescription card to open detail bottom sheet
      await tester.tap(find.text('Đơn thuốc hạ sốt'));
      await tester.pumpAndSettle();

      // Verify all fields are present in detail sheet
      expect(find.text('THÔNG TIN CHUNG ĐƠN THUỐC'), findsOneWidget);
      expect(find.text('Mã đơn thuốc:'), findsOneWidget);
      expect(find.text('DT-2026-001'), findsWidgets);
      expect(find.text('ID đơn thuốc:'), findsOneWidget);
      expect(find.text('Mã bệnh nhân:'), findsOneWidget);
      expect(find.text('Người chăm sóc:'), findsOneWidget);
      expect(find.text('Bác sĩ kê đơn:'), findsOneWidget);
      expect(find.text('Thời gian áp dụng:'), findsOneWidget);
      expect(find.text('DANH SÁCH THUỐC TRONG ĐƠN (1)'), findsOneWidget);
      expect(find.text('Paracetamol 500mg'), findsWidgets);
      expect(find.text('Hoạt chất: Acetaminophen'), findsOneWidget);
      expect(find.text('Liều dùng: 1.0 VIEN / lần'), findsOneWidget);
      expect(find.text('Còn: 20 VIEN'), findsOneWidget);
      expect(
          find.text('Hướng dẫn: Uống sau ăn no với nhiều nước'), findsOneWidget);
      expect(find.text('08:00 (Hàng ngày)'), findsOneWidget);

      // Close modal via close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Switch to Nhật ký uống thuốc sub-tab
      await tester.tap(find.textContaining('Nhật ký uống thuốc'));
      await tester.pumpAndSettle();

      // Verify Search bar is present in Logs sub-tab
      expect(find.widgetWithText(TextField, 'Tìm theo tên thuốc, mã bệnh nhân...'),
          findsOneWidget);
      expect(find.text('Đã uống (TAKEN)'), findsOneWidget);
      expect(find.text('Bỏ lỡ (MISSED)'), findsOneWidget);
      expect(find.text('Đã hoãn (SNOOZED)'), findsOneWidget);
      expect(find.text('Lên lịch (SCHEDULED)'), findsOneWidget);
      expect(find.textContaining('Đã uống:'), findsOneWidget);
    });
  });
}

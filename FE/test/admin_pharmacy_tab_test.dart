import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/screens/admin/admin_pharmacy_tab.dart';
import 'package:meds_reminder/services/admin_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  http.Response jsonUtf8(dynamic body, int statusCode) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  group('AdminPharmacyTab detail modal tests', () {
    testWidgets('shows all fields on pharmacy detail and order detail modals',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/pharmacies/summary') {
          return jsonUtf8({
            'totalPharmacies': 1,
            'orders': {
              'total': 8,
              'byStatus': {
                'PENDING_REVIEW': 0,
                'PREPARING': 0,
                'READY_FOR_PICKUP': 0,
                'SHIPPED': 0,
                'COMPLETED': 2,
                'CANCELLED': 6,
              },
            },
          }, 200);
        }
        if (request.url.path == '/api/v1/admin/pharmacies') {
          return jsonUtf8({
            'page': 1,
            'limit': 20,
            'total': 1,
            'pharmacies': [
              {
                'id': '5835eab3-ef5a-4377-91dc-979b37a8f2db',
                'name': 'Nhà thuốc An Khang',
                'phoneNumber': '0856232226',
                'addressText': '123 Lê Lợi, Quận 1, TP.HCM',
              }
            ],
          }, 200);
        }
        if (request.url.path ==
            '/api/v1/admin/pharmacies/5835eab3-ef5a-4377-91dc-979b37a8f2db') {
          return jsonUtf8({
            'pharmacy': {
              'id': '5835eab3-ef5a-4377-91dc-979b37a8f2db',
              'pharmacistId': '6ac7dbbd1610c215cab6ca38',
              'name': 'Nhà thuốc An Khang',
              'phoneNumber': '0856232226',
              'addressText': '123 Lê Lợi, Quận 1, TP.HCM',
              'latitude': 10.7769,
              'longitude': 106.7009,
              'createdAt': '2026-10-08T18:06:55.197Z',
              'updatedAt': '2026-10-09T05:01:22.825Z',
            },
            'orders': {
              'total': 8,
              'byStatus': {
                'PENDING_REVIEW': 0,
                'PREPARING': 0,
                'READY_FOR_PICKUP': 0,
                'SHIPPED': 0,
                'COMPLETED': 2,
                'CANCELLED': 6,
              },
            },
          }, 200);
        }
        if (request.url.path == '/api/v1/admin/orders') {
          return jsonUtf8({
            'page': 1,
            'limit': 20,
            'total': 1,
            'orders': [
              {
                'id': '3ad3b1e8-3405-472f-85c4-5298b6ce7443',
                'orderCode': 'MDW2GVJSGY',
                'totalAmount': 0,
                'status': 'CANCELLED',
              }
            ],
          }, 200);
        }
        if (request.url.path ==
            '/api/v1/admin/orders/3ad3b1e8-3405-472f-85c4-5298b6ce7443') {
          return jsonUtf8({
            'order': {
              'id': '3ad3b1e8-3405-472f-85c4-5298b6ce7443',
              'orderCode': 'MDW2GVJSGY',
              'patientId': '6abbd74f1a65898500954ec6',
              'caregiverId': '6ac62c2613a14fc6ee7cd146',
              'pharmacyId': '3afb49c8-8496-4d07-9969-a88bf5348a27',
              'prescriptionId': '122c7af5-f0c8-4d12-94e6-e00a56d10202',
              'status': 'CANCELLED',
              'fulfillmentType': 'PICKUP',
              'totalAmount': 0,
              'createdAt': '2026-10-09T04:38:19.497Z',
              'updatedAt': '2026-10-09T04:39:08.848Z',
              'pharmacyName': 'vinh xam',
              'recipientName': 'Kien bede',
              'recipientPhone': '0877736640',
              'deliveryAddress': null,
              'patientNote': 'bệnh nhân khỏe reeeeee',
              'shipperName': null,
              'shipperPhone': null,
              'rejectionReason': 'ko thik bán nữa',
            },
            'items': [
              {
                'id': '66efc6d4-263f-4f0f-82d7-4e788e664bd5',
                'prescriptionItemId': '3be93c94-fb2b-439c-bf0a-f27cab1098cd',
                'name': 'Paracetamol',
                'unit': 'VIEN',
                'quantity': 9,
                'unitPrice': null,
              }
            ],
          }, 200);
        }
        return jsonUtf8({}, 404);
      });

      final adminApi = AdminApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPharmacyTab(adminApi: adminApi),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Pharmacy Card is rendered
      expect(find.text('Nhà thuốc An Khang'), findsOneWidget);
      expect(find.text('0856232226'), findsOneWidget);

      // Tap Pharmacy Card to open detail sheet
      await tester.tap(find.text('Nhà thuốc An Khang'));
      await tester.pumpAndSettle();

      // Verify all Pharmacy fields from Postman screenshot 2
      expect(find.text('Mã ID nhà thuốc:'), findsOneWidget);
      expect(find.text('5835eab3-ef5a-4377-91dc-979b37a8f2db'), findsOneWidget);
      expect(find.text('Mã Dược sĩ phụ trách:'), findsOneWidget);
      expect(find.text('6ac7dbbd1610c215cab6ca38'), findsOneWidget);
      expect(find.text('Tọa độ vị trí (GPS):'), findsOneWidget);
      expect(find.textContaining('10.7769'), findsOneWidget);
      expect(find.textContaining('106.7009'), findsOneWidget);
      expect(find.text('THỐNG KÊ ĐƠN HÀNG (TỔNG: 8 ĐƠN)'), findsOneWidget);
      expect(find.text('Hoàn thành (COMPLETED)'), findsOneWidget);
      expect(find.text('Đã hủy (CANCELLED)'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      // Switch to Đơn đặt hàng sub-tab
      await tester.tap(find.textContaining('Đơn đặt hàng'));
      await tester.pumpAndSettle();

      // Verify Order Card is rendered
      expect(find.text('#MDW2GVJSGY'), findsOneWidget);

      // Tap Order Card to open detail sheet
      await tester.tap(find.text('#MDW2GVJSGY'));
      await tester.pumpAndSettle();

      // Verify all Order fields from Postman screenshot 3
      expect(find.text('Mã đặt hàng (Code):'), findsOneWidget);
      expect(find.text('MDW2GVJSGY'), findsOneWidget);
      expect(find.text('Mã ID đơn hàng:'), findsOneWidget);
      expect(find.text('3ad3b1e8-3405-472f-85c4-5298b6ce7443'), findsOneWidget);
      expect(find.text('Mã bệnh nhân:'), findsOneWidget);
      expect(find.text('6abbd74f1a65898500954ec6'), findsOneWidget);
      expect(find.text('Mã người chăm sóc:'), findsOneWidget);
      expect(find.text('6ac62c2613a14fc6ee7cd146'), findsOneWidget);
      expect(find.text('Nhà thuốc phục vụ:'), findsOneWidget);
      expect(find.textContaining('vinh xam'), findsOneWidget);
      expect(find.text('Mã đơn thuốc kèm:'), findsOneWidget);
      expect(find.text('122c7af5-f0c8-4d12-94e6-e00a56d10202'), findsOneWidget);
      expect(find.text('Tên người nhận:'), findsOneWidget);
      expect(find.text('Kien bede'), findsOneWidget);
      expect(find.text('0877736640'), findsOneWidget);
      expect(find.textContaining('Ghi chú người đặt: bệnh nhân khỏe reeeeee'),
          findsOneWidget);
      expect(find.textContaining('Lý do từ chối / hủy đơn: ko thik bán nữa'),
          findsOneWidget);

      // Verify Order items
      expect(find.text('DANH SÁCH SẢN PHẨM / THUỐC (1)'), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('x9 VIEN'), findsOneWidget);
    });
  });
}

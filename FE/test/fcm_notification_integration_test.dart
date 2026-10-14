import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/services/fcm_service.dart';
import 'package:meds_reminder/services/notification_service.dart';

/// Ghi nhận chi tiết mỗi lần showCaregiverAlert được gọi
class CaregiverAlertCall {
  const CaregiverAlertCall({
    required this.title,
    required this.body,
    this.id,
    this.payload,
  });

  final String title;
  final String body;
  final int? id;
  final String? payload;
}

/// Fake NotificationService để chặn và kiểm tra các cuộc gọi hiển thị thông báo
class FakeNotificationService extends NotificationService {
  FakeNotificationService() : super(isSupported: true);

  final List<CaregiverAlertCall> alertCalls = [];

  @override
  Future<void> showCaregiverAlert({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    alertCalls.add(
      CaregiverAlertCall(title: title, body: body, id: id, payload: payload),
    );
  }
}

/// Fake FlutterLocalNotificationsPlugin để kiểm tra chi tiết cấu hình AndroidNotificationDetails (Importance.max, ChannelId, v.v.)
class FakeFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> shownNotifications = [];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'notificationDetails': notificationDetails,
      'payload': payload,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake FcmMessagingGateway cho stream sự kiện FCM
class FakeFcmGateway implements FcmMessagingGateway {
  FakeFcmGateway({this.token = 'fake-fcm-token'});

  String? token;
  int permissionRequests = 0;
  final tokenRefreshController = StreamController<String>.broadcast();
  final messageController = StreamController<RemoteMessage>.broadcast();

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => tokenRefreshController.stream;

  @override
  Stream<RemoteMessage> get onMessage => messageController.stream;

  void dispose() {
    tokenRefreshController.close();
    messageController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService originalNotificationService;

  setUp(() {
    originalNotificationService = NotificationService.instance;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.medsreminder/wake_lock'),
          (call) async {
            if (call.method == 'getTimeZoneName') {
              return 'Asia/Ho_Chi_Minh';
            }
            return null;
          },
        );
  });

  tearDown(() {
    NotificationService.instance = originalNotificationService;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.medsreminder/wake_lock'),
          null,
        );
  });

  group('FCM Notification Details & Importance.max Verification', () {
    test('caregiverAndroidNotificationDetails has caregiver_alerts channel and Importance.max', () {
      final details = NotificationService.caregiverAndroidNotificationDetails();

      expect(details.channelId, 'caregiver_alerts');
      expect(details.channelName, 'Cảnh báo người chăm sóc');
      expect(details.importance, Importance.max);
      expect(details.priority, Priority.max);
      expect(details.visibility, NotificationVisibility.public);
      expect(details.fullScreenIntent, isTrue);
      expect(details.playSound, isTrue);
      expect(details.enableVibration, isTrue);
      expect(details.category, AndroidNotificationCategory.alarm);
    });

    test('NotificationService.showCaregiverAlert invokes flutter_local_notifications plugin with Importance.max', () async {
      final fakePlugin = FakeFlutterLocalNotificationsPlugin();
      final realServiceWithFakePlugin = NotificationService(
        plugin: fakePlugin,
        isSupported: true,
      );
      NotificationService.instance = realServiceWithFakePlugin;

      await NotificationService.instance.showCaregiverAlert(
        title: 'Quên uống thuốc',
        body: 'Bệnh nhân · Panadol lúc 08:00',
        payload: jsonEncode({'type': 'DOSE_ALERT', 'logId': 'log-01'}),
      );

      expect(fakePlugin.shownNotifications, hasLength(1));
      final shown = fakePlugin.shownNotifications.first;

      expect(shown['title'], 'Quên uống thuốc');
      expect(shown['body'], 'Bệnh nhân · Panadol lúc 08:00');
      expect(shown['payload'], contains('log-01'));

      final details = shown['notificationDetails'] as NotificationDetails?;
      expect(details, isNotNull);
      final android = details!.android;
      expect(android, isNotNull);
      expect(android!.channelId, 'caregiver_alerts');
      expect(android.importance, Importance.max);
      expect(android.priority, Priority.max);
      expect(android.fullScreenIntent, isTrue);
    });
  });

  group('handleIncomingFcmMessage Payload Extraction & Alert Triggering', () {
    late FakeNotificationService fakeService;

    setUp(() {
      fakeService = FakeNotificationService();
      NotificationService.instance = fakeService;
    });

    test(
      'triggers alert from message with explicit notification title & body',
      () async {
        const message = RemoteMessage(
          notification: RemoteNotification(
            title: 'Cảnh báo cữ thuốc',
            body: 'Bệnh nhân Nguyễn Văn A đã quên uống thuốc lúc 20:00',
          ),
          data: {'type': 'DOSE_ALERT', 'logId': 'log-999', 'status': 'MISSED'},
        );

        await handleIncomingFcmMessage(message);

        expect(fakeService.alertCalls, hasLength(1));
        final call = fakeService.alertCalls.first;
        expect(call.title, 'Cảnh báo cữ thuốc');
        expect(
          call.body,
          'Bệnh nhân Nguyễn Văn A đã quên uống thuốc lúc 20:00',
        );
        expect(call.payload, contains('log-999'));
      },
    );

    test('extracts title "Đã bỏ qua thuốc" when status is SKIPPED', () async {
      const message = RemoteMessage(
        data: {
          'status': 'SKIPPED',
          'body': 'Bệnh nhân đã bỏ qua cữ thuốc vì lý do dạ dày.',
          'logId': 'log-101',
        },
      );

      await handleIncomingFcmMessage(message);

      expect(fakeService.alertCalls, hasLength(1));
      final call = fakeService.alertCalls.first;
      expect(call.title, 'Đã bỏ qua thuốc');
      expect(call.body, 'Bệnh nhân đã bỏ qua cữ thuốc vì lý do dạ dày.');
      expect(call.payload, contains('SKIPPED'));
    });

    test('extracts title "Quên uống thuốc" when status is MISSED with custom message field', () async {
      const message = RemoteMessage(
        data: {
          'status': 'MISSED',
          'message': 'Đã quá 30 phút bệnh nhân chưa xác nhận uống thuốc.',
          'logId': 'log-202',
        },
      );

      await handleIncomingFcmMessage(message);

      expect(fakeService.alertCalls, hasLength(1));
      final call = fakeService.alertCalls.first;
      expect(call.title, 'Quên uống thuốc');
      expect(call.body, 'Đã quá 30 phút bệnh nhân chưa xác nhận uống thuốc.');
    });

    test('provides safe fallback title and body when notification & data fields are empty', () async {
      const message = RemoteMessage(data: {});

      await handleIncomingFcmMessage(message);

      expect(fakeService.alertCalls, hasLength(1));
      final call = fakeService.alertCalls.first;
      expect(call.title, 'Quên uống thuốc');
      expect(call.body, 'Có thông báo cữ thuốc mới.');
      expect(call.payload, isNull);
    });
  });

  group('End-to-End FCM to Local Notification Flow', () {
    test('FcmService onMessage stream automatically pops up local notification via NotificationService', () async {
      final fakePlugin = FakeFlutterLocalNotificationsPlugin();
      final realService = NotificationService(
        plugin: fakePlugin,
        isSupported: true,
      );
      NotificationService.instance = realService;

      final gateway = FakeFcmGateway();
      final fcmService = FcmService(
        gateway: gateway,
        uploader: (_) async => true,
        supported: true,
      );

      await fcmService.start();

      // Giả lập Backend bắn FCM qua gateway onMessage
      const incomingMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'Quên uống thuốc',
          body: 'Bà Lan · Amlodipine 5mg lúc 08:00',
        ),
        data: {'type': 'DOSE_ALERT', 'status': 'MISSED', 'logId': 'dose-12345'},
      );
      gateway.messageController.add(incomingMessage);
      await pumpEventQueue();

      // Kiểm tra plugin local notification đã nhận đúng thông tin và kênh Importance.max
      expect(fakePlugin.shownNotifications, hasLength(1));
      final shown = fakePlugin.shownNotifications.first;
      expect(shown['title'], 'Quên uống thuốc');
      expect(shown['body'], 'Bà Lan · Amlodipine 5mg lúc 08:00');

      final details = shown['notificationDetails'] as NotificationDetails?;
      expect(details?.android?.channelId, 'caregiver_alerts');
      expect(details?.android?.importance, Importance.max);
      expect(details?.android?.priority, Priority.max);

      // Sau khi stop(), tin nhắn mới không được kích hoạt
      await fcmService.stop();
      gateway.messageController.add(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'Tin nhắn thừa',
            body: 'Không được hiển thị',
          ),
        ),
      );
      await pumpEventQueue();

      expect(fakePlugin.shownNotifications, hasLength(1));

      gateway.dispose();
    });

    test(
      'firebaseMessagingBackgroundHandler triggers NotificationService pop-up',
      () async {
        final fakePlugin = FakeFlutterLocalNotificationsPlugin();
        final realService = NotificationService(
          plugin: fakePlugin,
          isSupported: true,
        );
        NotificationService.instance = realService;

        const backgroundMessage = RemoteMessage(
          data: {
            'status': 'SKIPPED',
            'body': 'Bệnh nhân bỏ qua cữ thuốc Aspirin 81mg',
            'logId': 'bg-log-777',
          },
        );

        await firebaseMessagingBackgroundHandler(backgroundMessage);

        expect(fakePlugin.shownNotifications, hasLength(1));
        final shown = fakePlugin.shownNotifications.first;
        expect(shown['title'], 'Đã bỏ qua thuốc');
        expect(shown['body'], 'Bệnh nhân bỏ qua cữ thuốc Aspirin 81mg');
        expect(shown['payload'], contains('bg-log-777'));

        final details = shown['notificationDetails'] as NotificationDetails?;
        expect(details?.android?.channelId, 'caregiver_alerts');
        expect(details?.android?.importance, Importance.max);
      },
    );
  });
}

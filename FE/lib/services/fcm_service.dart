import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'fcm_token_api.dart';
import 'notification_service.dart';

/// Hàm xử lý FCM background độc lập (chạy khi app chạy ngầm hoặc đã đóng)
@visibleForTesting
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await FcmService.initializeFirebase();
    await handleIncomingFcmMessage(message);
  } catch (error) {
    debugPrint('FCM background message error: $error');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    firebaseMessagingBackgroundHandler(message);

typedef FcmAlertPresenter = Future<void> Function({
  required String title,
  required String body,
  int? id,
  String? payload,
});

/// Trích xuất nội dung từ FCM và hiển thị pop-up thông báo qua flutter_local_notifications
Future<void> handleIncomingFcmMessage(
  RemoteMessage message, {
  FcmAlertPresenter? alertPresenter,
}) async {
  final notification = message.notification;
  final data = message.data;

  // Tiêu đề: lấy từ notification.title -> data['title'] -> fallback theo trạng thái
  String? title = notification?.title ?? data['title']?.toString();
  if (title == null || title.isEmpty) {
    final status = data['status']?.toString();
    title = status == 'SKIPPED' ? 'Đã bỏ qua thuốc' : 'Quên uống thuốc';
  }

  // Nội dung: lấy từ notification.body -> data['body'] -> data['message'] -> fallback
  String? body =
      notification?.body ??
      data['body']?.toString() ??
      data['message']?.toString();
  body ??= 'Có thông báo cữ thuốc mới.';

  final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  final payload = data.isNotEmpty ? jsonEncode(data) : null;

  final presenter =
      alertPresenter ?? NotificationService.instance.showCaregiverAlert;
  await presenter(title: title, body: body, id: id, payload: payload);
}

/// Lớp mỏng quanh FirebaseMessaging để có thể thay bằng fake khi test.
abstract class FcmMessagingGateway {
  Future<void> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onMessage;
}

class FirebaseMessagingGateway implements FcmMessagingGateway {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<void> requestPermission() =>
      _messaging.requestPermission(alert: true, badge: true, sound: true);

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
}

typedef FcmTokenUploader = Future<bool> Function(String? token);
typedef FcmMessageHandler = Future<void> Function(RemoteMessage message);

/// Đồng bộ FCM token và hiển thị thông báo đẩy cho Người chăm sóc.
class FcmService {
  FcmService({
    FcmMessagingGateway? gateway,
    FcmTokenUploader? uploader,
    FcmMessageHandler? messageHandler,
    bool? supported,
  }) : _injectedGateway = gateway,
       _injectedUploader = uploader,
       _injectedMessageHandler = messageHandler,
       _supported = supported ?? defaultSupported;

  static bool get defaultSupported =>
      !kIsWeb &&
      Platform.isAndroid &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  final FcmMessagingGateway? _injectedGateway;
  final FcmTokenUploader? _injectedUploader;
  final FcmMessageHandler? _injectedMessageHandler;
  late final FcmMessagingGateway _gateway =
      _injectedGateway ?? FirebaseMessagingGateway();
  late final FcmTokenUploader _uploader =
      _injectedUploader ?? FcmTokenApi().saveToken;
  late final FcmMessageHandler _messageHandler =
      _injectedMessageHandler ?? handleIncomingFcmMessage;

  final bool _supported;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  int _session = 0;

  bool get isActive => _refreshSub != null;

  /// Khởi tạo Firebase an toàn: không làm crash web / flutter test / thiếu config.
  static Future<bool> initializeFirebase() async {
    if (!defaultSupported) return false;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      return true;
    } catch (error) {
      debugPrint('Firebase init failed: $error');
      return false;
    }
  }

  /// Gọi sau khi Caregiver đăng nhập / khôi phục phiên.
  Future<void> start() async {
    if (!_supported) return;
    await stop();
    final session = ++_session;
    try {
      final gateway = _gateway;
      final upload = _uploader;
      await gateway.requestPermission();
      if (session != _session) return;

      _refreshSub = gateway.onTokenRefresh.listen(
        (token) => _upload(upload, token),
        onError: (Object error) => debugPrint('FCM refresh error: $error'),
      );

      _messageSub = gateway.onMessage.listen(
        (message) => _onMessage(message),
        onError: (Object error) => debugPrint('FCM onMessage error: $error'),
      );

      await _upload(upload, await gateway.getToken());
    } catch (error) {
      debugPrint('FCM start failed: $error');
    }
  }

  /// Gọi khi đăng xuất hoặc user không còn là Caregiver.
  Future<void> stop() async {
    _session++;
    final refreshSub = _refreshSub;
    final messageSub = _messageSub;
    _refreshSub = null;
    _messageSub = null;
    await refreshSub?.cancel();
    await messageSub?.cancel();
  }

  Future<void> _onMessage(RemoteMessage message) async {
    try {
      await _messageHandler(message);
    } catch (error) {
      debugPrint('FCM message handler error: $error');
    }
  }

  Future<void> _upload(FcmTokenUploader upload, String? token) async {
    try {
      await upload(token);
    } catch (error) {
      debugPrint('FCM token upload failed: $error');
    }
  }
}

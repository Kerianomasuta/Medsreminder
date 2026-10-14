import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/auth_cookie_adapter.dart';
import 'package:meds_reminder/services/fcm_service.dart';
import 'package:meds_reminder/services/fcm_token_api.dart';

class _FakeCookies implements AuthCookieAdapter {
  @override
  Map<String, String> get requestHeaders => const {'Cookie': 'accessToken=abc'};

  @override
  String? get accessToken => 'abc';

  @override
  Future<void> restore() async {}

  @override
  void capture(Map<String, String> responseHeaders) {}

  @override
  void clear() {}
}

class _FakeGateway implements FcmMessagingGateway {
  _FakeGateway({this.token = 'token-1'});

  String? token;
  int permissionRequests = 0;
  final refresh = StreamController<String>.broadcast();
  final messages = StreamController<RemoteMessage>.broadcast();

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<RemoteMessage> get onMessage => messages.stream;
}

FcmTokenApi _api(MockClient client) =>
    FcmTokenApi(client: client, cookies: _FakeCookies());

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('FcmTokenApi', () {
    test('PUTs the trimmed token with auth cookie and JSON body', () async {
      late http.Request sent;
      final api = _api(
        MockClient((request) async {
          sent = request;
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }),
      );

      expect(await api.saveToken('  abc123  '), isTrue);

      expect(sent.method, 'PUT');
      expect(sent.url.path, '/api/v1/users/me/fcm-token');
      expect(jsonDecode(sent.body), {'token': 'abc123'});
      expect(sent.headers['Cookie'], 'accessToken=abc');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
    });

    test('does not call the API for null, empty or oversized token', () async {
      var calls = 0;
      final api = _api(
        MockClient((request) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );

      expect(await api.saveToken(null), isFalse);
      expect(await api.saveToken(''), isFalse);
      expect(await api.saveToken('   '), isFalse);
      expect(
        await api.saveToken('a' * (FcmTokenApi.maxTokenLength + 1)),
        isFalse,
      );
      expect(calls, 0);
    });

    test('maps 400 to a typed exception with the server message', () async {
      final api = _api(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': ['token must be shorter'],
            }),
            400,
          ),
        ),
      );

      await expectLater(
        api.saveToken('abc'),
        throwsA(
          isA<FcmTokenApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'token must be shorter'),
        ),
      );
    });

    test('maps 401 to a typed exception', () async {
      final api = _api(MockClient((_) async => http.Response('', 401)));

      await expectLater(
        api.saveToken('abc'),
        throwsA(
          isA<FcmTokenApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });

  group('FcmService', () {
    test('does nothing when unsupported (web / flutter test)', () async {
      final gateway = _FakeGateway();
      final uploaded = <String?>[];
      final service = FcmService(
        gateway: gateway,
        uploader: (token) async {
          uploaded.add(token);
          return true;
        },
        supported: false,
      );

      await service.start();

      expect(gateway.permissionRequests, 0);
      expect(uploaded, isEmpty);
      expect(service.isActive, isFalse);
    });

    test('uploads the token on start and again on token refresh', () async {
      final gateway = _FakeGateway();
      final uploaded = <String?>[];
      final service = FcmService(
        gateway: gateway,
        uploader: (token) async {
          uploaded.add(token);
          return true;
        },
        supported: true,
      );

      await service.start();
      expect(gateway.permissionRequests, 1);
      expect(uploaded, ['token-1']);

      gateway.refresh.add('token-2');
      await _settle();
      expect(uploaded, ['token-1', 'token-2']);
    });

    test('stops uploading refreshed tokens after stop()', () async {
      final gateway = _FakeGateway();
      final uploaded = <String?>[];
      final service = FcmService(
        gateway: gateway,
        uploader: (token) async {
          uploaded.add(token);
          return true;
        },
        supported: true,
      );

      await service.start();
      await service.stop();
      gateway.refresh.add('token-2');
      await _settle();

      expect(uploaded, ['token-1']);
      expect(service.isActive, isFalse);
    });

    test('hands a null token to the uploader, which skips the call', () async {
      var calls = 0;
      final api = _api(
        MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      final service = FcmService(
        gateway: _FakeGateway(token: null),
        uploader: api.saveToken,
        supported: true,
      );

      await service.start();

      expect(calls, 0);
    });

    test(
      'survives upload failures and keeps listening for refreshes',
      () async {
        final gateway = _FakeGateway();
        final uploaded = <String?>[];
        final service = FcmService(
          gateway: gateway,
          uploader: (token) async {
            uploaded.add(token);
            if (token == 'token-1') {
              throw const FcmTokenApiException('401', statusCode: 401);
            }
            return true;
          },
          supported: true,
        );

        await service.start();
        gateway.refresh.add('token-2');
        await _settle();

        expect(uploaded, ['token-1', 'token-2']);
      },
    );

    test('routes foreground messages to message handler', () async {
      final gateway = _FakeGateway();
      final received = <RemoteMessage>[];
      final service = FcmService(
        gateway: gateway,
        uploader: (_) async => true,
        messageHandler: (msg) async => received.add(msg),
        supported: true,
      );

      await service.start();
      const message = RemoteMessage(data: {'status': 'MISSED'});
      gateway.messages.add(message);
      await _settle();

      expect(received, [message]);

      await service.stop();
      gateway.messages.add(const RemoteMessage(data: {'status': 'SKIPPED'}));
      await _settle();

      expect(received, [message]);
    });
  });

  group('handleIncomingFcmMessage', () {
    test(
      'extracts notification title and body and invokes alert presenter',
      () async {
        String? presentedTitle;
        String? presentedBody;
        String? presentedPayload;

        const message = RemoteMessage(
          notification: RemoteNotification(
            title: 'Quên uống thuốc',
            body: 'Bệnh nhân · Panadol lúc 08:00',
          ),
          data: {'status': 'MISSED', 'logId': 'log-123'},
        );

        await handleIncomingFcmMessage(
          message,
          alertPresenter: ({required title, required body, id, payload}) async {
            presentedTitle = title;
            presentedBody = body;
            presentedPayload = payload;
          },
        );

        expect(presentedTitle, 'Quên uống thuốc');
        expect(presentedBody, 'Bệnh nhân · Panadol lúc 08:00');
        expect(presentedPayload, contains('log-123'));
      },
    );

    test('falls back to data fields when notification is omitted', () async {
      String? presentedTitle;
      String? presentedBody;

      const message = RemoteMessage(
        data: {
          'status': 'SKIPPED',
          'message': 'Đã bỏ qua cữ thuốc vì đau dạ dày',
        },
      );

      await handleIncomingFcmMessage(
        message,
        alertPresenter: ({required title, required body, id, payload}) async {
          presentedTitle = title;
          presentedBody = body;
        },
      );

      expect(presentedTitle, 'Đã bỏ qua thuốc');
      expect(presentedBody, 'Đã bỏ qua cữ thuốc vì đau dạ dày');
    });

    test('uses default title and body when payload is empty', () async {
      String? presentedTitle;
      String? presentedBody;

      const message = RemoteMessage(data: {});

      await handleIncomingFcmMessage(
        message,
        alertPresenter: ({required title, required body, id, payload}) async {
          presentedTitle = title;
          presentedBody = body;
        },
      );

      expect(presentedTitle, 'Quên uống thuốc');
      expect(presentedBody, 'Có thông báo cữ thuốc mới.');
    });
  });
}

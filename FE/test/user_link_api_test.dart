import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meds_reminder/services/user_link_api.dart';

void main() {
  test(
    'calls the four user linking endpoints with the repository contract',
    () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/create-link-invitation')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'invitationLink':
                    'http://localhost:3000/invitation?invitationUUID=invite-1',
              },
            }),
            201,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/verify-invitation/')) {
          return http.Response(
            jsonEncode({'status': 'success'}),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.endsWith('/link-infomations')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'linkedAccounts': [
                  {
                    'linkId': 'link-1',
                    'linkedAt': '2026-10-08T01:00:00.000Z',
                    'patienInfo': {
                      '_id': '507f1f77bcf86cd799439011',
                      'fullName': 'Nguyễn Thị Lan',
                    },
                  },
                ],
              },
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              '_id': '507f1f77bcf86cd799439011',
              'fullName': 'Nguyễn Thị Lan',
              'email': 'lan@example.com',
              'phone': '0900000000',
            },
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = UserLinkApi(client: client);
      expect(await api.createInvitation(), 'invite-1');
      await api.verifyInvitation('invite-1');
      final links = await api.getLinkedAccounts();
      final patient = await api.getPatientDetail(links.single.patient!.id);

      expect(links.single.patient!.fullName, 'Nguyễn Thị Lan');
      expect(patient.phone, '0900000000');
      expect(calls, [
        'POST /api/v1/users/create-link-invitation',
        'PATCH /api/v1/users/verify-invitation/invite-1',
        'GET /api/v1/users/link-infomations',
        'GET /api/v1/users/patient-detail/507f1f77bcf86cd799439011',
      ]);
    },
  );
}

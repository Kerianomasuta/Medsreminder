import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/care_network.dart';
import 'api_base_url.dart';
import 'http_client_factory.dart';

class UserLinkApiException implements Exception {
  const UserLinkApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UserLinkApi {
  UserLinkApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;
  String? lastInvitationLink;

  Future<String> createInvitation() async {
    final payload = await _request(
      'POST',
      Uri.parse('$apiBaseUrl/api/v1/users/create-link-invitation'),
    );
    final data = payload['data'] as Map<String, dynamic>?;
    final link = data?['invitationLink']?.toString().trim();
    lastInvitationLink = link;
    final invitationUuid = link == null || link.isEmpty
        ? null
        : Uri.tryParse(link)?.queryParameters['invitationUUID']?.trim();
    if (invitationUuid == null || invitationUuid.isEmpty) {
      throw const UserLinkApiException(
        'Máy chủ không trả về mã lời mời hợp lệ.',
      );
    }
    return invitationUuid;
  }

  /// Parses invitation UUID from varied formats:
  /// - Full URL query string: `.../invitation?invitationUUID=<uuid>`
  /// - JSON string: `{"invitationUUID": "<uuid>"}`
  /// - Standard 36-char UUID string: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
  /// - Raw string fallback
  static String? extractInvitationUuid(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Check URL parameters
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasQuery) {
      final param = uri.queryParameters['invitationUUID'] ??
          uri.queryParameters['invitationUuid'] ??
          uri.queryParameters['uuid'];
      if (param != null && param.trim().isNotEmpty) {
        return param.trim();
      }
    }

    // 2. Check JSON payload
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final id = decoded['invitationUUID'] ??
              decoded['invitationUuid'] ??
              decoded['uuid'];
          if (id != null && id.toString().trim().isNotEmpty) {
            return id.toString().trim();
          }
        }
      } catch (_) {}
    }

    // 3. Check UUID regex
    final uuidRegex = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    );
    final match = uuidRegex.firstMatch(trimmed);
    if (match != null) {
      return match.group(0);
    }

    return trimmed;
  }

  Future<void> verifyInvitation(String invitationUuid) async {
    await _request(
      'PATCH',
      Uri.parse(
        '$apiBaseUrl/api/v1/users/verify-invitation/${Uri.encodeComponent(invitationUuid)}',
      ),
    );
  }

  Future<List<LinkedAccount>> getLinkedAccounts() async {
    // The repository BE currently spells this route `link-infomations`.
    // Keep the exact deployed contract here and remove the typo with the BE fix.
    final payload = await _request(
      'GET',
      Uri.parse('$apiBaseUrl/api/v1/users/link-infomations'),
    );
    final data = payload['data'] as Map<String, dynamic>?;
    final raw = data?['linkedAccounts'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LinkedAccount.fromJson)
        .toList(growable: false);
  }

  Future<PatientDetail> getPatientDetail(String patientId) async {
    final payload = await _request(
      'GET',
      Uri.parse(
        '$apiBaseUrl/api/v1/users/patient-detail/${Uri.encodeComponent(patientId)}',
      ),
    );
    final raw = payload['data'];
    if (raw is! Map<String, dynamic>) {
      throw const UserLinkApiException('Thông tin bệnh nhân không hợp lệ.');
    }
    return PatientDetail.fromJson(raw);
  }

  Future<Map<String, dynamic>> _request(String method, Uri uri) async {
    late http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri),
        'POST' => await _client.post(uri),
        'PATCH' => await _client.patch(uri),
        _ => throw UnsupportedError('Unsupported method: $method'),
      };
    } catch (_) {
      throw const UserLinkApiException(
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
      );
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw UserLinkApiException(
        message ?? 'Yêu cầu thất bại (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const UserLinkApiException('Phản hồi máy chủ không hợp lệ.');
    }
    return decoded;
  }

  void close() => _client.close();
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medication_log.dart';
import 'api_base_url.dart';
import 'auth_cookie_adapter.dart';
import 'http_client_factory.dart';

class MedicationLogsApiException implements Exception {
  const MedicationLogsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class MedicationLogsApi {
  MedicationLogsApi({http.Client? client, AuthCookieAdapter? cookies})
    : _client = client ?? createHttpClient(),
      _cookies = cookies ?? AuthCookieAdapter();

  final http.Client _client;
  final AuthCookieAdapter _cookies;

  Future<List<MedicationLog>> list({
    required DateTime from,
    DateTime? to,
    String? patientId,
  }) async {
    final query = <String, String>{'from': _dateOnly(from)};
    if (to != null) query['to'] = _dateOnly(to);
    if (patientId != null && patientId.isNotEmpty) {
      query['patientId'] = patientId;
    }
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/medication-logs')
          .replace(queryParameters: query),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _exception(response);
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) => MedicationLog.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<MedicationLog> markTaken(String id) => _post('$id/taken', const {});

  Future<MedicationLog> snooze(String id, {required int minutes}) {
    if (minutes != 5 && minutes != 10) {
      throw const MedicationLogsApiException(
        'Chỉ có thể nhắc lại sau 5 hoặc 10 phút.',
      );
    }
    return _post('$id/snooze', {'minutes': minutes});
  }

  Future<MedicationLog> skip(String id, {String? reason}) {
    final normalized = reason?.trim();
    if ((normalized?.length ?? 0) > 500) {
      throw const MedicationLogsApiException(
        'Lý do bỏ qua không được vượt quá 500 ký tự.',
      );
    }
    return _post('$id/skip', {
      if (normalized != null && normalized.isNotEmpty) 'skipReason': normalized,
    });
  }

  Future<MedicationLog> markMissed(String id) => _post('$id/missed', const {});

  Future<MedicationLog> _post(String suffix, Map<String, Object> body) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/v1/medication-logs/$suffix'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) throw _exception(response);
    return MedicationLog.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Map<String, String> get _headers => {
    ..._cookies.requestHeaders,
    'Accept': 'application/json',
  };

  MedicationLogsApiException _exception(http.Response response) {
    var message =
        'Yêu cầu cập nhật cữ thuốc thất bại (${response.statusCode}).';
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final value = payload['message'];
      if (value is String && value.isNotEmpty) message = value;
      if (value is List) message = value.join('\n');
    } catch (_) {}
    return MedicationLogsApiException(message, statusCode: response.statusCode);
  }

  String _dateOnly(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  void close() => _client.close();
}

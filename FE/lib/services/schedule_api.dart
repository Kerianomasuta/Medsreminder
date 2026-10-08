import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/schedule_rule.dart';
import 'api_base_url.dart';
import 'auth_cookie_adapter.dart';
import 'http_client_factory.dart';

class ScheduleApiException implements Exception {
  const ScheduleApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ScheduleApi {
  ScheduleApi({
    http.Client? client,
    AuthCookieAdapter? cookies,
  })  : _client = client ?? createHttpClient(),
        _cookies = cookies ?? AuthCookieAdapter();

  final http.Client _client;
  final AuthCookieAdapter _cookies;

  /// Gọi GET /api/v1/schedule-rules?patientId=...&isActive=...
  Future<List<ScheduleRule>> list({
    required String patientId,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{'patientId': patientId};
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('$apiBaseUrl/api/v1/schedule-rules')
        .replace(queryParameters: queryParams);

    final response = await _client.get(
      uri,
      headers: {
        ..._cookies.requestHeaders,
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => ScheduleRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ScheduleApiException(
        'Lỗi lấy danh sách lịch nhắc: ${response.statusCode}',
      );
    }
  }

  /// Gọi GET /api/v1/schedule-rules/:id
  Future<ScheduleRule> getById(String id) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/schedule-rules/$id');
    final response = await _client.get(
      uri,
      headers: {
        ..._cookies.requestHeaders,
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return ScheduleRule.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw ScheduleApiException(
        'Lỗi lấy chi tiết cữ uống: ${response.statusCode}',
      );
    }
  }

  /// Gọi PATCH /api/v1/schedule-rules/:id
  Future<ScheduleRule> update(
    String id, {
    String? reminderTime,
    List<int>? daysOfWeek,
    bool? isActive,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/schedule-rules/$id');
    final body = <String, dynamic>{};
    if (reminderTime != null) {
      final parts = reminderTime.split(':');
      if (parts.length >= 2) {
        final hh = parts[0].padLeft(2, '0');
        final mm = parts[1].padLeft(2, '0');
        body['reminderTime'] = '$hh:$mm';
      } else {
        body['reminderTime'] = reminderTime;
      }
    }
    if (daysOfWeek != null) body['daysOfWeek'] = daysOfWeek;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.patch(
      uri,
      headers: {
        ..._cookies.requestHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return ScheduleRule.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw ScheduleApiException(
        'Cập nhật lịch uống thất bại: ${response.statusCode}',
      );
    }
  }

  /// Gọi POST /api/v1/prescription-items/:id/schedules
  Future<ScheduleRule> create(
    String prescriptionItemId, {
    required String reminderTime,
    List<int>? daysOfWeek,
  }) async {
    final uri = Uri.parse(
      '$apiBaseUrl/api/v1/prescription-items/$prescriptionItemId/schedules',
    );
    final parts = reminderTime.split(':');
    final formattedTime = parts.length >= 2
        ? '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}'
        : reminderTime;

    final body = <String, dynamic>{
      'reminderTime': formattedTime,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
    };

    final response = await _client.post(
      uri,
      headers: {
        ..._cookies.requestHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ScheduleRule.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw ScheduleApiException(
        'Thêm lịch uống thất bại: ${response.statusCode}',
      );
    }
  }

  void close() => _client.close();
}

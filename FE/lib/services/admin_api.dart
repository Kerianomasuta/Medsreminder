import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_base_url.dart';
import 'auth_cookie_adapter.dart';
import 'http_client_factory.dart';

class AdminApiException implements Exception {
  const AdminApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AdminSummary {
  const AdminSummary({
    required this.totalUsers,
    required this.patientCount,
    required this.caregiverCount,
    required this.pharmacistCount,
    required this.adminCount,
    required this.premiumCount,
    required this.inactiveCount,
    required this.registeredLast7Days,
    required this.activeLinks,
    required this.inactiveLinks,
  });

  final int totalUsers;
  final int patientCount;
  final int caregiverCount;
  final int pharmacistCount;
  final int adminCount;
  final int premiumCount;
  final int inactiveCount;
  final int registeredLast7Days;
  final int activeLinks;
  final int inactiveLinks;

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    final users = json['users'] is Map<String, dynamic>
        ? json['users'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final links = json['links'] is Map<String, dynamic>
        ? json['links'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AdminSummary(
      totalUsers: (users['total'] as num?)?.toInt() ?? 0,
      patientCount: (users['patient'] as num?)?.toInt() ?? 0,
      caregiverCount: (users['caregiver'] as num?)?.toInt() ?? 0,
      pharmacistCount: (users['pharmacist'] as num?)?.toInt() ?? 0,
      adminCount: (users['admin'] as num?)?.toInt() ?? 0,
      premiumCount: (users['premium'] as num?)?.toInt() ?? 0,
      inactiveCount: (users['inactive'] as num?)?.toInt() ?? 0,
      registeredLast7Days: (users['registeredLast7Days'] as num?)?.toInt() ?? 0,
      activeLinks: (links['active'] as num?)?.toInt() ?? 0,
      inactiveLinks: (links['inactive'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPaymentsPlanBreakdown {
  const AdminPaymentsPlanBreakdown({this.paid = 0, this.paidAmount = 0.0});

  final int paid;
  final double paidAmount;

  factory AdminPaymentsPlanBreakdown.fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const AdminPaymentsPlanBreakdown();
    }
    return AdminPaymentsPlanBreakdown(
      paid: (raw['paid'] as num?)?.toInt() ?? 0,
      paidAmount: (raw['paidAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminPaymentsWindow {
  const AdminPaymentsWindow({this.count = 0, this.amount = 0.0});

  final int count;
  final double amount;

  factory AdminPaymentsWindow.fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const AdminPaymentsWindow();
    }
    return AdminPaymentsWindow(
      count: (raw['count'] as num?)?.toInt() ?? 0,
      amount: (raw['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminPaymentsSummary {
  const AdminPaymentsSummary({
    required this.total,
    required this.pending,
    required this.paid,
    required this.failed,
    required this.paidAmount,
    required this.pendingAmount,
    required this.month,
    required this.year,
    required this.paidLast7Days,
    required this.paidLast30Days,
  });

  final int total;
  final int pending;
  final int paid;
  final int failed;
  final double paidAmount;
  final double pendingAmount;
  final AdminPaymentsPlanBreakdown month;
  final AdminPaymentsPlanBreakdown year;
  final AdminPaymentsWindow paidLast7Days;
  final AdminPaymentsWindow paidLast30Days;

  // Compatibility getters
  double get totalAmount => paidAmount;
  int get totalCount => total;
  double get paidLast7DaysAmount => paidLast7Days.amount;
  int get paidLast7DaysCount => paidLast7Days.count;
  double get paidLast30DaysAmount => paidLast30Days.amount;
  int get paidLast30DaysCount => paidLast30Days.count;

  factory AdminPaymentsSummary.fromJson(Map<String, dynamic> json) {
    final totalRaw = json['total'];
    final int totalCount = totalRaw is num
        ? totalRaw.toInt()
        : (totalRaw is Map ? (totalRaw['count'] as num?)?.toInt() ?? 0 : 0);

    final paidAmountRaw = json['paidAmount'];
    final double paidAmount = paidAmountRaw is num
        ? paidAmountRaw.toDouble()
        : (totalRaw is Map
              ? (totalRaw['amount'] as num?)?.toDouble() ?? 0.0
              : 0.0);

    final pendingAmountRaw = json['pendingAmount'];
    final double pendingAmount = (pendingAmountRaw as num?)?.toDouble() ?? 0.0;

    return AdminPaymentsSummary(
      total: totalCount,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      paid: (json['paid'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      month: AdminPaymentsPlanBreakdown.fromJson(json['month']),
      year: AdminPaymentsPlanBreakdown.fromJson(json['year']),
      paidLast7Days: AdminPaymentsWindow.fromJson(json['paidLast7Days']),
      paidLast30Days: AdminPaymentsWindow.fromJson(json['paidLast30Days']),
    );
  }
}

class AdminPharmacySummary {
  const AdminPharmacySummary({
    required this.pharmacyTotal,
    required this.pharmacyCreatedLast7Days,
    required this.ordersTotal,
    required this.ordersCreatedLast7Days,
    required this.ordersCompletedAmount,
    this.ordersPendingReview = 0,
    this.ordersPreparing = 0,
    this.ordersReadyForPickup = 0,
    this.ordersShipped = 0,
    this.ordersCompleted = 0,
    this.ordersCancelled = 0,
  });

  // pharmacies
  final int pharmacyTotal;
  final int pharmacyCreatedLast7Days;

  // orders
  final int ordersTotal;
  final int ordersCreatedLast7Days;
  final double ordersCompletedAmount;
  final int ordersPendingReview;
  final int ordersPreparing;
  final int ordersReadyForPickup;
  final int ordersShipped;
  final int ordersCompleted;
  final int ordersCancelled;

  factory AdminPharmacySummary.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacies'] is Map<String, dynamic>
        ? json['pharmacies'] as Map<String, dynamic>
        : (json['pharmacy'] is Map<String, dynamic>
              ? json['pharmacy'] as Map<String, dynamic>
              : const <String, dynamic>{});
    final orders = json['orders'] is Map<String, dynamic>
        ? json['orders'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final orderStatuses = orders['byStatus'] is Map<String, dynamic>
        ? orders['byStatus'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AdminPharmacySummary(
      pharmacyTotal: (pharmacy['total'] as num?)?.toInt() ?? 0,
      pharmacyCreatedLast7Days:
          (pharmacy['createdLast7Days'] as num?)?.toInt() ?? 0,
      ordersTotal: (orders['total'] as num?)?.toInt() ?? 0,
      ordersCreatedLast7Days:
          (orders['createdLast7Days'] as num?)?.toInt() ?? 0,
      ordersCompletedAmount:
          (orders['completedAmount'] as num?)?.toDouble() ?? 0.0,
      ordersPendingReview:
          (orderStatuses['PENDING_REVIEW'] as num?)?.toInt() ?? 0,
      ordersPreparing: (orderStatuses['PREPARING'] as num?)?.toInt() ?? 0,
      ordersReadyForPickup:
          (orderStatuses['READY_FOR_PICKUP'] as num?)?.toInt() ?? 0,
      ordersShipped: (orderStatuses['SHIPPED'] as num?)?.toInt() ?? 0,
      ordersCompleted: (orderStatuses['COMPLETED'] as num?)?.toInt() ?? 0,
      ordersCancelled: (orderStatuses['CANCELLED'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminMedicationSummary {
  const AdminMedicationSummary({
    required this.prescriptionsTotal,
    required this.prescriptionsActive,
    required this.prescriptionsInactive,
    required this.prescriptionsCreatedLast7Days,
    required this.itemsTotal,
    required this.itemsLowStock,
    required this.schedulesTotal,
    required this.schedulesActive,
    required this.schedulesInactive,
    required this.logsTotal,
    required this.logsRecordedLast7Days,
    required this.logsScheduled,
    required this.logsTaken,
    required this.logsSnoozed,
    required this.logsMissed,
    required this.logsSkipped,
  });

  // prescriptions
  final int prescriptionsTotal;
  final int prescriptionsActive;
  final int prescriptionsInactive;
  final int prescriptionsCreatedLast7Days;

  // items
  final int itemsTotal;
  final int itemsLowStock;
  int get lowStockItems => itemsLowStock;

  // schedules
  final int schedulesTotal;
  final int schedulesActive;
  final int schedulesInactive;

  // logs
  final int logsTotal;
  final int logsRecordedLast7Days;
  final int logsScheduled;
  final int logsTaken;
  final int logsSnoozed;
  final int logsMissed;
  final int logsSkipped;
  int get doseLogsTotal => logsTotal;

  factory AdminMedicationSummary.fromJson(Map<String, dynamic> json) {
    final prescriptions = json['prescriptions'] is Map<String, dynamic>
        ? json['prescriptions'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final items = json['items'] is Map<String, dynamic>
        ? json['items'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final schedules = json['schedules'] is Map<String, dynamic>
        ? json['schedules'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final logs = json['logs'] is Map<String, dynamic>
        ? json['logs'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final logStatuses = logs['byStatus'] is Map<String, dynamic>
        ? logs['byStatus'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AdminMedicationSummary(
      prescriptionsTotal: (prescriptions['total'] as num?)?.toInt() ?? 0,
      prescriptionsActive: (prescriptions['active'] as num?)?.toInt() ?? 0,
      prescriptionsInactive: (prescriptions['inactive'] as num?)?.toInt() ?? 0,
      prescriptionsCreatedLast7Days:
          (prescriptions['createdLast7Days'] as num?)?.toInt() ?? 0,
      itemsTotal: (items['total'] as num?)?.toInt() ?? 0,
      itemsLowStock: (items['lowStock'] as num?)?.toInt() ?? 0,
      schedulesTotal: (schedules['total'] as num?)?.toInt() ?? 0,
      schedulesActive: (schedules['active'] as num?)?.toInt() ?? 0,
      schedulesInactive: (schedules['inactive'] as num?)?.toInt() ?? 0,
      logsTotal: (logs['total'] as num?)?.toInt() ?? 0,
      logsRecordedLast7Days: (logs['recordedLast7Days'] as num?)?.toInt() ?? 0,
      logsScheduled: (logStatuses['SCHEDULED'] as num?)?.toInt() ?? 0,
      logsTaken: (logStatuses['TAKEN'] as num?)?.toInt() ?? 0,
      logsSnoozed: (logStatuses['SNOOZED'] as num?)?.toInt() ?? 0,
      logsMissed: (logStatuses['MISSED'] as num?)?.toInt() ?? 0,
      logsSkipped: (logStatuses['SKIPPED'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.isPremium,
    this.premiumExpiresAt,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AdminUserItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Chưa đặt tên',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'PATIENT',
      avatarUrl: json['avatar_url']?.toString(),
      isPremium: json['isPremium'] == true,
      premiumExpiresAt: parseDate(json['premiumExpiresAt']),
      isActive: json['isActive'] != false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class AdminUserListResponse {
  const AdminUserListResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.users,
  });

  final int page;
  final int limit;
  final int total;
  final List<AdminUserItem> users;

  factory AdminUserListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['users'] as List<dynamic>? ?? const [];
    return AdminUserListResponse(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      users: rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminUserItem.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminUserDetail {
  const AdminUserDetail({required this.user, this.links = const []});

  final AdminUserItem user;
  final List<Map<String, dynamic>> links;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawLinks = json['links'] as List<dynamic>? ?? const [];

    return AdminUserDetail(
      user: AdminUserItem.fromJson(rawUser),
      links: rawLinks.whereType<Map<String, dynamic>>().toList(growable: false),
    );
  }
}

class AdminPagedResponse {
  const AdminPagedResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<Map<String, dynamic>> items;
}

class AdminApi {
  AdminApi({http.Client? client})
    : _client = client ?? createHttpClient(),
      _cookies = AuthCookieAdapter();

  final http.Client _client;
  final AuthCookieAdapter _cookies;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    ..._cookies.requestHeaders,
  };

  /// 1. GET /api/v1/admin/summary
  Future<AdminSummary> getSummary() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/admin/summary'),
      headers: _authHeaders,
    );
    return AdminSummary.fromJson(_parseResponse(res));
  }

  /// 2. GET /api/v1/admin/payments/summary
  Future<AdminPaymentsSummary> getPaymentsSummary() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/admin/payments/summary'),
      headers: _authHeaders,
    );
    return AdminPaymentsSummary.fromJson(_parseResponse(res));
  }

  /// 3. GET /api/v1/admin/pharmacy/summary
  Future<AdminPharmacySummary> getPharmacySummary() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/admin/pharmacy/summary'),
      headers: _authHeaders,
    );
    return AdminPharmacySummary.fromJson(_parseResponse(res));
  }

  /// 4. GET /api/v1/admin/medication/summary
  Future<AdminMedicationSummary> getMedicationSummary() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/admin/medication/summary'),
      headers: _authHeaders,
    );
    return AdminMedicationSummary.fromJson(_parseResponse(res));
  }

  /// 5. GET /api/v1/admin/users
  Future<AdminUserListResponse> getUsers({
    String? role,
    String? q,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (role != null && role.isNotEmpty && role != 'ALL') {
      queryParams['role'] = role;
    }
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('$apiBaseUrl/api/v1/admin/users')
        .replace(queryParameters: queryParams);

    final res = await _client.get(uri, headers: _authHeaders);
    return AdminUserListResponse.fromJson(_parseResponse(res));
  }

  /// 6. GET /api/v1/admin/users/{userId}
  Future<AdminUserDetail> getUserDetail(String userId) async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/api/v1/admin/users/$userId'),
      headers: _authHeaders,
    );
    return AdminUserDetail.fromJson(_parseResponse(res));
  }

  /// 7. PATCH /api/v1/admin/users/{userId}
  Future<AdminUserItem> updateUser(
    String userId, {
    String? fullName,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (role != null) body['role'] = role;
    if (isActive != null) body['isActive'] = isActive;

    final res = await _client.patch(
      Uri.parse('$apiBaseUrl/api/v1/admin/users/$userId'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    final json = _parseResponse(res);
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    return AdminUserItem.fromJson(userMap);
  }

  Future<AdminPagedResponse> searchPrescriptions({
    String? patientId,
    bool? isActive,
    String? q,
    int page = 1,
    int limit = 20,
  }) => _getPaged('/api/v1/admin/prescriptions', 'prescriptions', {
    'patientId': patientId,
    'isActive': isActive?.toString(),
    'q': q,
    'page': page.toString(),
    'limit': limit.toString(),
  });

  Future<Map<String, dynamic>> getPrescriptionDetail(String id) =>
      _getDetail('/api/v1/admin/prescriptions/$id');

  Future<AdminPagedResponse> searchMedicationLogs({
    String? patientId,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) => _getPaged('/api/v1/admin/medication-logs', 'logs', {
    'patientId': patientId,
    'status': status,
    'from': from,
    'to': to,
    'page': page.toString(),
    'limit': limit.toString(),
  });

  Future<AdminPagedResponse> searchPharmacies({
    String? q,
    int page = 1,
    int limit = 20,
  }) => _getPaged('/api/v1/admin/pharmacies', 'pharmacies', {
    'q': q,
    'page': page.toString(),
    'limit': limit.toString(),
  });

  Future<Map<String, dynamic>> getPharmacyDetail(String id) =>
      _getDetail('/api/v1/admin/pharmacies/$id');

  Future<AdminPagedResponse> searchOrders({
    String? status,
    String? pharmacyId,
    String? patientId,
    String? q,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) => _getPaged('/api/v1/admin/orders', 'orders', {
    'status': status,
    'pharmacyId': pharmacyId,
    'patientId': patientId,
    'q': q,
    'from': from,
    'to': to,
    'page': page.toString(),
    'limit': limit.toString(),
  });

  Future<Map<String, dynamic>> getOrderDetail(String id) =>
      _getDetail('/api/v1/admin/orders/$id');

  Future<AdminPagedResponse> searchPayments({
    String? status,
    String? plan,
    String? userId,
    String? q,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) => _getPaged('/api/v1/admin/payments', 'payments', {
    'status': status,
    'plan': plan,
    'userId': userId,
    'q': q,
    'from': from,
    'to': to,
    'page': page.toString(),
    'limit': limit.toString(),
  });

  Future<Map<String, dynamic>> getPaymentDetail(String id) =>
      _getDetail('/api/v1/admin/payments/$id');

  Future<AdminPagedResponse> _getPaged(
    String path,
    String key,
    Map<String, String?> params,
  ) async {
    final query = <String, String>{};
    for (final entry in params.entries) {
      if (entry.value != null && entry.value!.trim().isNotEmpty) {
        query[entry.key] = entry.value!;
      }
    }
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final json = _parseResponse(await _client.get(uri, headers: _authHeaders));
    final rawItems = json[key] as List<dynamic>? ?? const [];
    return AdminPagedResponse(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      items: rawItems.whereType<Map<String, dynamic>>().toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> _getDetail(String path) async {
    return _parseResponse(
      await _client.get(Uri.parse('$apiBaseUrl$path'), headers: _authHeaders),
    );
  }

  Map<String, dynamic> _parseResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
      return <String, dynamic>{};
    }
    String message = 'Yêu cầu thất bại (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {}
    throw AdminApiException(message, statusCode: res.statusCode);
  }
}

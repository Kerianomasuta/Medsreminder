import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prescription.dart';
import 'api_base_url.dart';
import 'http_client_factory.dart';

// ---------------------------------------------------------------------------

class PrescriptionServiceException implements Exception {
  final int statusCode;
  final String message;
  PrescriptionServiceException(this.statusCode, this.message);

  @override
  String toString() => 'PrescriptionServiceException($statusCode): $message';
}

// ---------------------------------------------------------------------------

class PrescriptionService {
  PrescriptionService({http.Client? client})
    : _client = client ?? createHttpClient();

  static final instance = PrescriptionService();

  final http.Client _client;

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    late http.Response response;

    try {
      response = switch (method) {
        'GET' => await _client.get(
          uri,
          headers: const {'Accept': 'application/json'},
        ),
        'POST' => await _client.post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        ),
        'PATCH' => await _client.patch(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        ),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      };
    } catch (e) {
      if (e is PrescriptionServiceException) rethrow;
      throw PrescriptionServiceException(
        0,
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String errorMsg = response.body;
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      errorMsg = (decoded['message'] ?? decoded['error'] ?? response.body)
          .toString();
    } catch (_) {}
    throw PrescriptionServiceException(response.statusCode, errorMsg);
  }

  Future<List<dynamic>> _requestList(String path) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    late http.Response response;

    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
    } catch (_) {
      throw PrescriptionServiceException(
        0,
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw PrescriptionServiceException(response.statusCode, response.body);
  }

  // ── API methods ────────────────────────────────────────────────────────────

  /// GET /api/v1/prescriptions?patientId={id}
  Future<List<Prescription>> listForPatient(String patientId) async {
    // ── DEV MOCK: patientId không phải UUID thật → trả mock data ──────────
    if (_isDevPatientId(patientId)) return _mockPrescriptions(patientId);
    // ─────────────────────────────────────────────────────────────────────────

    final raw = await _requestList(
      '/api/v1/prescriptions?patientId=$patientId',
    );
    return raw
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/prescriptions/{id}
  Future<Prescription> getById(String id) async {
    // ── DEV MOCK ─────────────────────────────────────────────────────────────
    if (_isDevId(id)) {
      final found = _allMockPrescriptions().where((p) => p.id == id).toList();
      if (found.isEmpty) {
        throw PrescriptionServiceException(404, 'Prescription not found');
      }
      return found.first;
    }
    // ─────────────────────────────────────────────────────────────────────────
    final raw = await _request('GET', '/api/v1/prescriptions/$id');
    return Prescription.fromJson(raw);
  }

  /// POST /api/v1/prescriptions (nested creation)
  Future<Prescription> create(Prescription prescription) async {
    if (prescription.items.isEmpty) {
      throw ArgumentError(
        'A prescription must have at least one medicine item.',
      );
    }
    for (final item in prescription.items) {
      if (item.schedules.isEmpty) {
        throw ArgumentError(
          'Each medicine item must have at least one schedule.',
        );
      }
    }
    // ── DEV MOCK: trả về prescription mới tạo giả ────────────────────────────
    if (_isDevPatientId(prescription.patientId)) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final newId = 'mock-rx-new-${DateTime.now().millisecondsSinceEpoch}';
      final created = Prescription(
        id: newId,
        patientId: prescription.patientId,
        title: prescription.title,
        doctorName: prescription.doctorName,
        prescriptionCode: prescription.prescriptionCode,
        startDate: prescription.startDate,
        endDate: prescription.endDate,
        isActive: prescription.isActive,
        items: prescription.items.map((item) {
          return PrescriptionItem(
            id: 'mock-item-new-${DateTime.now().microsecondsSinceEpoch}',
            medicineName: item.medicineName,
            genericName: item.genericName,
            unit: item.unit,
            imageUrl: item.imageUrl,
            dosagePerTime: item.dosagePerTime,
            currentStock: item.currentStock,
            reorderThreshold: item.reorderThreshold,
            instructions: item.instructions,
            schedules: item.schedules,
          );
        }).toList(),
      );
      _mockCreated.add(created);
      return created;
    }
    // ─────────────────────────────────────────────────────────────────────────
    final raw = await _request(
      'POST',
      '/api/v1/prescriptions',
      body: prescription.toCreateJson(),
    );
    return Prescription.fromJson(raw);
  }

  /// PATCH /api/v1/prescriptions/{id}
  Future<Prescription> updateInfo(String id, Map<String, dynamic> patch) async {
    // ── DEV MOCK ─────────────────────────────────────────────────────────────
    if (_isDevId(id)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final all = _allMockPrescriptions();
      final idx = all.indexWhere((p) => p.id == id);
      if (idx == -1) {
        throw PrescriptionServiceException(404, 'Prescription not found');
      }
      final old = all[idx];
      return Prescription(
        id: old.id,
        patientId: old.patientId,
        title: patch['title'] as String? ?? old.title,
        doctorName: patch.containsKey('doctorName')
            ? patch['doctorName'] as String?
            : old.doctorName,
        prescriptionCode: patch.containsKey('prescriptionCode')
            ? patch['prescriptionCode'] as String?
            : old.prescriptionCode,
        startDate: patch['startDate'] as String? ?? old.startDate,
        endDate: patch.containsKey('endDate')
            ? patch['endDate'] as String?
            : old.endDate,
        isActive: patch['isActive'] as bool? ?? old.isActive,
        items: old.items,
      );
    }
    // ─────────────────────────────────────────────────────────────────────────
    final raw = await _request(
      'PATCH',
      '/api/v1/prescriptions/$id',
      body: patch,
    );
    return Prescription.fromJson(raw);
  }

  /// POST /api/v1/prescriptions/{id}/items
  Future<PrescriptionItem> addItem(
    String prescriptionId,
    PrescriptionItem item,
  ) async {
    if (item.schedules.isEmpty) {
      throw ArgumentError('A medicine item must have at least one schedule.');
    }
    // ── DEV MOCK ─────────────────────────────────────────────────────────────
    if (_isDevId(prescriptionId)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return PrescriptionItem(
        id: 'mock-item-added-${DateTime.now().millisecondsSinceEpoch}',
        medicineName: item.medicineName,
        genericName: item.genericName,
        unit: item.unit,
        imageUrl: item.imageUrl,
        dosagePerTime: item.dosagePerTime,
        currentStock: item.currentStock,
        reorderThreshold: item.reorderThreshold,
        instructions: item.instructions,
        schedules: item.schedules,
      );
    }
    // ─────────────────────────────────────────────────────────────────────────
    final raw = await _request(
      'POST',
      '/api/v1/prescriptions/$prescriptionId/items',
      body: item.toAddItemJson(),
    );
    return PrescriptionItem.fromJson(raw);
  }

  /// PATCH /api/v1/prescription-items/{id}
  Future<PrescriptionItem> updateItem(
    String itemId,
    PrescriptionItem item,
  ) async {
    // ── DEV MOCK ─────────────────────────────────────────────────────────────
    if (_isDevId(itemId)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return PrescriptionItem(
        id: itemId,
        medicineName: item.medicineName,
        genericName: item.genericName,
        unit: item.unit,
        imageUrl: item.imageUrl,
        dosagePerTime: item.dosagePerTime,
        currentStock: item.currentStock,
        reorderThreshold: item.reorderThreshold,
        instructions: item.instructions,
        schedules: item.schedules,
      );
    }
    // ─────────────────────────────────────────────────────────────────────────
    final raw = await _request(
      'PATCH',
      '/api/v1/prescription-items/$itemId',
      body: item.toPatchJson(),
    );
    return PrescriptionItem.fromJson(raw);
  }

  // ── DEV MOCK data store ───────────────────────────────────────────────────
  // Danh sách đơn mới tạo trong session (reset khi reload)
  static final List<Prescription> _mockCreated = [];

  static bool _isDevId(String id) => id.startsWith('mock-');
  static bool _isDevPatientId(String id) {
    // BE chưa làm xong API, nên tạm coi ID này là Mock để test UI lưu vào RAM
    // Cho phép cả UUID chuẩn và MongoDB ObjectId (24 ký tự hex)
    final idRe = RegExp(
      r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|[0-9a-fA-F]{24})$',
    );
    return !idRe.hasMatch(id);
  }

  // ── Mock patient IDs (để dùng trong linkedPatients) ──────────────────────
  // PA-8899 → bbbbbbbb-0001-4000-b000-000000000001
  // PA-5521 → bbbbbbbb-0002-4000-b000-000000000002
  static List<Prescription> _allMockPrescriptions() {
    return [..._mockDb, ..._mockCreated];
  }

  static List<Prescription> _mockPrescriptions(String patientId) {
    // Map code PA-xxxx sang mock UUID
    final mapped = _kPatientCodeToId[patientId] ?? patientId;
    final fromDb = _mockDb.where((p) => p.patientId == mapped).toList();
    final fromCreated = _mockCreated
        .where((p) => p.patientId == mapped || p.patientId == patientId)
        .toList();
    return [...fromDb, ...fromCreated];
  }

  static const _kPatientCodeToId = <String, String>{
    'PA-8899': 'bbbbbbbb-0001-4000-b000-000000000001',
    'PA-5521': 'bbbbbbbb-0002-4000-b000-000000000002',
    'demo-patient-id-not-set': 'bbbbbbbb-0001-4000-b000-000000000001',
  };

  static final _mockDb = [
    // ── Patient 1: Nguyễn Thị Lan (PA-8899) ──────────────────────────────────
    Prescription(
      id: 'mock-rx-p1-001',
      patientId: 'bbbbbbbb-0001-4000-b000-000000000001',
      title: 'Đơn thuốc huyết áp',
      doctorName: 'BS. Trần Văn Khoa',
      prescriptionCode: 'RX-2026-001',
      startDate: '2026-09-01',
      endDate: '2026-12-01',
      isActive: true,
      items: [
        PrescriptionItem(
          id: 'mock-item-p1-001',
          medicineName: 'Amlodipine 5mg',
          dosagePerTime: 1,
          currentStock: 28,
          reorderThreshold: 7,
          instructions: 'Uống sau bữa sáng',
          schedules: [
            Schedule(
              id: 'sch-001',
              reminderTime: '07:30',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
        PrescriptionItem(
          id: 'mock-item-p1-002',
          medicineName: 'Atorvastatin 10mg',
          dosagePerTime: 1,
          currentStock: 5,
          reorderThreshold: 7,
          instructions: 'Uống trước khi ngủ',
          schedules: [
            Schedule(
              id: 'sch-002',
              reminderTime: '21:00',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
      ],
    ),
    Prescription(
      id: 'mock-rx-p1-002',
      patientId: 'bbbbbbbb-0001-4000-b000-000000000001',
      title: 'Đơn thuốc tiểu đường',
      doctorName: 'BS. Lê Thị Hương',
      prescriptionCode: null,
      startDate: '2026-08-15',
      endDate: null,
      isActive: true,
      items: [
        PrescriptionItem(
          id: 'mock-item-p1-003',
          medicineName: 'Metformin 500mg',
          dosagePerTime: 2,
          currentStock: 60,
          reorderThreshold: 14,
          instructions: 'Uống trong bữa ăn, không uống khi đói',
          schedules: [
            Schedule(
              id: 'sch-003',
              reminderTime: '07:00',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
            Schedule(
              id: 'sch-004',
              reminderTime: '12:00',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
        PrescriptionItem(
          id: 'mock-item-p1-004',
          medicineName: 'Vitamin D3 1000IU',
          dosagePerTime: 1,
          currentStock: 90,
          reorderThreshold: 15,
          instructions: null,
          schedules: [
            Schedule(
              id: 'sch-005',
              reminderTime: '08:00',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
      ],
    ),
    Prescription(
      id: 'mock-rx-p1-003',
      patientId: 'bbbbbbbb-0001-4000-b000-000000000001',
      title: 'Đơn cũ — dạ dày (đã kết thúc)',
      doctorName: 'BS. Nguyễn Minh Tú',
      prescriptionCode: 'RX-2025-088',
      startDate: '2025-06-01',
      endDate: '2025-09-01',
      isActive: false,
      items: [
        PrescriptionItem(
          id: 'mock-item-p1-005',
          medicineName: 'Omeprazole 20mg',
          dosagePerTime: 1,
          currentStock: 0,
          reorderThreshold: 7,
          instructions: 'Uống 30 phút trước bữa sáng',
          schedules: [
            Schedule(
              id: 'sch-006',
              reminderTime: '06:30',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
      ],
    ),

    // ── Patient 2: Trần Văn Nam (PA-5521) ────────────────────────────────────
    Prescription(
      id: 'mock-rx-p2-001',
      patientId: 'bbbbbbbb-0002-4000-b000-000000000002',
      title: 'Đơn thuốc tim mạch',
      doctorName: 'BS. Phạm Quốc Bảo',
      prescriptionCode: 'RX-2026-045',
      startDate: '2026-07-01',
      endDate: '2027-01-01',
      isActive: true,
      items: [
        PrescriptionItem(
          id: 'mock-item-p2-001',
          medicineName: 'Lisinopril 10mg',
          dosagePerTime: 1,
          currentStock: 3,
          reorderThreshold: 10,
          instructions: 'Uống mỗi sáng, tránh dùng khi đang uống potassium',
          schedules: [
            Schedule(
              id: 'sch-007',
              reminderTime: '08:00',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
        PrescriptionItem(
          id: 'mock-item-p2-002',
          medicineName: 'Atorvastatin 10mg',
          dosagePerTime: 1,
          currentStock: 20,
          reorderThreshold: 7,
          instructions: 'Uống buổi tối',
          schedules: [
            Schedule(
              id: 'sch-008',
              reminderTime: '20:00',
              daysOfWeek: List.generate(7, (i) => i + 1),
            ),
          ],
        ),
      ],
    ),
    Prescription(
      id: 'mock-rx-p2-002',
      patientId: 'bbbbbbbb-0002-4000-b000-000000000002',
      title: 'Bổ sung vitamin',
      doctorName: null,
      prescriptionCode: null,
      startDate: '2026-09-15',
      endDate: null,
      isActive: true,
      items: [
        PrescriptionItem(
          id: 'mock-item-p2-003',
          medicineName: 'Vitamin D3 1000IU',
          dosagePerTime: 1,
          currentStock: 45,
          reorderThreshold: 10,
          instructions: null,
          schedules: [
            Schedule(
              id: 'sch-009',
              reminderTime: '09:00',
              daysOfWeek: [1, 3, 5, 7],
            ),
          ],
        ),
      ],
    ),
  ];
  // ──────────────────────────────────────────────────────────────────────────
}

// ---------------------------------------------------------------------------
// Validation helpers — reusable across screens
// ---------------------------------------------------------------------------

class PrescriptionValidator {
  // Cho phép cả UUID chuẩn và MongoDB ObjectId (24 ký tự hex)
  static final _uuidRe = RegExp(
    r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|[0-9a-fA-F]{24})$',
  );
  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _timeRe = RegExp(r'^\d{2}:\d{2}$');

  static bool isValidUuid(String s) => _uuidRe.hasMatch(s);

  static bool isValidDate(String s) {
    if (!_dateRe.hasMatch(s)) return false;
    try {
      DateTime.parse(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isValidTime(String s) => _timeRe.hasMatch(s);

  /// Returns error message or null if valid.
  static String? validatePrescription(Prescription p) {
    if (!isValidUuid(p.patientId)) return 'patientId phải là UUID hợp lệ';
    if (p.title.trim().isEmpty) return 'Tiêu đề không được để trống';
    if (!isValidDate(p.startDate)) {
      return 'Ngày bắt đầu không hợp lệ (YYYY-MM-DD)';
    }
    if (p.endDate != null) {
      if (!isValidDate(p.endDate!)) {
        return 'Ngày kết thúc không hợp lệ (YYYY-MM-DD)';
      }
      if (DateTime.parse(p.endDate!).isBefore(DateTime.parse(p.startDate))) {
        return 'Ngày kết thúc phải >= ngày bắt đầu';
      }
    }
    if (p.items.isEmpty) return 'Cần ít nhất 1 loại thuốc';
    for (final item in p.items) {
      final err = validateItem(item);
      if (err != null) return err;
    }
    return null;
  }

  static String? validateItem(PrescriptionItem item) {
    if (item.medicineName.trim().isEmpty) {
      return 'Tên thuốc không được để trống';
    }
    if (item.dosagePerTime <= 0) return 'Liều dùng phải > 0';
    if (item.currentStock < 0) return 'Tồn kho không được âm';
    if (item.reorderThreshold < 0) return 'Ngưỡng đặt lại không được âm';
    if (item.schedules.isEmpty) return 'Cần ít nhất 1 lịch nhắc';
    for (final s in item.schedules) {
      if (!isValidTime(s.reminderTime)) {
        return 'Giờ nhắc không hợp lệ: ${s.reminderTime} (cần HH:mm)';
      }
      if (s.daysOfWeek.isNotEmpty) {
        if (s.daysOfWeek.any((d) => d < 1 || d > 7)) {
          return 'Ngày trong tuần phải trong khoảng 1-7';
        }
      }
    }
    return null;
  }
}

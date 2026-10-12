import 'package:flutter/foundation.dart';

import '../models/medication_log.dart';
import '../services/medication_logs_api.dart';

class MedicationLogsController extends ChangeNotifier {
  MedicationLogsController({MedicationLogsApi? api})
    : _api = api ?? MedicationLogsApi(),
      _ownsApi = api == null;

  final MedicationLogsApi _api;
  final bool _ownsApi;
  bool _disposed = false;

  List<MedicationLog> logs = const [];
  bool loading = false;
  String? loadError;
  final Set<String> processingLogIds = {};

  bool isProcessing(String id) => processingLogIds.contains(id);

  Future<void> loadToday({String? patientId}) {
    final now = DateTime.now();
    return loadRange(now, now, patientId: patientId);
  }

  Future<void> loadRange(
    DateTime from,
    DateTime to, {
    String? patientId,
  }) async {
    loading = true;
    loadError = null;
    _notify();
    try {
      logs = await _api.list(from: from, to: to, patientId: patientId);
      logs = [...logs]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } catch (error) {
      loadError = error.toString();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<MedicationLog> take(String id) => _act(id, () => _api.markTaken(id));

  Future<MedicationLog> snooze(String id, int minutes) =>
      _act(id, () => _api.snooze(id, minutes: minutes));

  Future<MedicationLog> skip(String id, {String? reason}) =>
      _act(id, () => _api.skip(id, reason: reason));

  Future<MedicationLog> miss(String id) => _act(id, () => _api.markMissed(id));

  Future<MedicationLog> _act(
    String id,
    Future<MedicationLog> Function() request,
  ) async {
    if (processingLogIds.contains(id)) {
      throw const MedicationLogsApiException('Cữ thuốc đang được cập nhật.');
    }
    processingLogIds.add(id);
    _notify();
    try {
      final updated = await request();
      final index = logs.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final next = [...logs];
        next[index] = updated;
        logs = next;
      }
      return updated;
    } finally {
      processingLogIds.remove(id);
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsApi) _api.close();
    super.dispose();
  }
}

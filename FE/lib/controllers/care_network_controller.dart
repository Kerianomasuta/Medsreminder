import 'package:flutter/foundation.dart';

import '../models/app_role.dart';
import '../models/auth_user.dart';
import '../models/care_network.dart';
import '../models/prescription.dart';
import '../models/schedule_rule.dart';
import '../services/prescription_service.dart';
import '../services/schedule_api.dart';
import '../services/user_link_api.dart';

class CareNetworkController extends ChangeNotifier {
  CareNetworkController({
    required this.user,
    UserLinkApi? userLinkApi,
    ScheduleApi? scheduleApi,
    PrescriptionService? prescriptionService,
  }) : _userLinkApi = userLinkApi ?? UserLinkApi(),
       _scheduleApi = scheduleApi ?? ScheduleApi(),
       _prescriptionService =
           prescriptionService ?? PrescriptionService.instance;

  final AuthUser user;
  final UserLinkApi _userLinkApi;
  final ScheduleApi _scheduleApi;
  final PrescriptionService _prescriptionService;

  List<LinkedAccount> linkedAccounts = const [];
  String? selectedPatientId;
  bool linksLoading = false;
  String? linksError;
  String? invitationLink;

  bool _linksLoaded = false;
  Future<void>? _linksInFlight;
  final Map<String, PatientBundle> _bundleCache = {};
  final Map<String, Future<void>> _bundleInFlight = {};
  final Map<String, String> _bundleErrors = {};

  List<LinkedUserSummary> get linkedPatients => linkedAccounts
      .map((link) => link.patient)
      .whereType<LinkedUserSummary>()
      .toList(growable: false);

  List<LinkedUserSummary> get linkedCaregivers => linkedAccounts
      .map((link) => link.caregiver)
      .whereType<LinkedUserSummary>()
      .toList(growable: false);

  PatientBundle? bundleFor(String? patientId) =>
      patientId == null ? null : _bundleCache[patientId];

  String? bundleErrorFor(String? patientId) =>
      patientId == null ? null : _bundleErrors[patientId];

  bool isPatientLoading(String? patientId) =>
      patientId != null && _bundleInFlight.containsKey(patientId);

  Future<void> initialize() => loadLinkedAccounts();

  Future<void> loadLinkedAccounts({bool force = false}) {
    if (_linksLoaded && !force) return Future.value();
    if (_linksInFlight != null) return _linksInFlight!;

    linksLoading = true;
    linksError = null;
    notifyListeners();

    final request = _loadLinkedAccounts();
    _linksInFlight = request;
    request.whenComplete(() => _linksInFlight = null);
    return request;
  }

  Future<void> _loadLinkedAccounts() async {
    try {
      linkedAccounts = await _userLinkApi.getLinkedAccounts();
      _linksLoaded = true;
      if (user.role == AppRole.caregiver) {
        final patients = linkedPatients;
        if (patients.isEmpty) {
          selectedPatientId = null;
        } else if (!patients.any((item) => item.id == selectedPatientId)) {
          selectedPatientId = patients.first.id;
        }
      }
    } catch (error) {
      linksError = error.toString();
    } finally {
      linksLoading = false;
      notifyListeners();
    }

    if (user.role == AppRole.caregiver && selectedPatientId != null) {
      await loadPatient(selectedPatientId!);
    }
  }

  Future<void> selectPatient(String patientId) async {
    if (selectedPatientId != patientId) {
      selectedPatientId = patientId;
      notifyListeners();
    }
    await loadPatient(patientId);
  }

  Future<void> loadPatient(String patientId, {bool force = false}) {
    if (!force && _bundleCache.containsKey(patientId)) {
      return Future.value();
    }
    if (_bundleInFlight.containsKey(patientId)) {
      return _bundleInFlight[patientId]!;
    }

    _bundleErrors.remove(patientId);
    final request = _fetchPatientBundle(patientId);
    _bundleInFlight[patientId] = request;
    notifyListeners();
    request.whenComplete(() {
      _bundleInFlight.remove(patientId);
      notifyListeners();
    });
    return request;
  }

  Future<void> _fetchPatientBundle(String patientId) async {
    try {
      final results = await Future.wait<Object>([
        _userLinkApi.getPatientDetail(patientId),
        _scheduleApi.list(patientId: patientId),
        _prescriptionService.listForPatient(patientId),
      ]);
      final bundle = PatientBundle(
        detail: results[0] as PatientDetail,
        schedules: results[1] as List<ScheduleRule>,
        prescriptions: results[2] as List<Prescription>,
      );
      _bundleCache[patientId] = bundle;
    } catch (error) {
      _bundleErrors[patientId] = error.toString();
    }
  }

  Future<String> createInvitation() async {
    invitationLink ??= await _userLinkApi.createInvitation();
    notifyListeners();
    return invitationLink!;
  }

  Future<void> verifyInvitation(String invitationUuid) async {
    await _userLinkApi.verifyInvitation(invitationUuid);
    _linksLoaded = false;
    await loadLinkedAccounts(force: true);
  }

  Future<void> refreshSelectedPatient() async {
    final id = selectedPatientId;
    if (id == null) return;
    await loadPatient(id, force: true);
  }

  @override
  void dispose() {
    _userLinkApi.close();
    _scheduleApi.close();
    super.dispose();
  }
}

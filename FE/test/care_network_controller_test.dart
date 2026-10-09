import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/controllers/care_network_controller.dart';
import 'package:meds_reminder/models/app_role.dart';
import 'package:meds_reminder/models/auth_user.dart';
import 'package:meds_reminder/models/care_network.dart';
import 'package:meds_reminder/models/prescription.dart';
import 'package:meds_reminder/models/schedule_rule.dart';
import 'package:meds_reminder/services/prescription_service.dart';
import 'package:meds_reminder/services/schedule_api.dart';
import 'package:meds_reminder/services/user_link_api.dart';

void main() {
  test(
    'loads each patient endpoint once and reuses the cached bundle',
    () async {
      final links = _FakeUserLinkApi();
      final schedules = _FakeScheduleApi();
      final prescriptions = _FakePrescriptionService();
      final controller = CareNetworkController(
        user: const AuthUser(
          id: '507f1f77bcf86cd799439012',
          email: 'caregiver@example.com',
          fullName: 'Người chăm sóc',
          role: AppRole.caregiver,
        ),
        userLinkApi: links,
        scheduleApi: schedules,
        prescriptionService: prescriptions,
      );

      await controller.initialize();
      await controller.loadLinkedAccounts();
      await controller.loadPatient(_patientId);

      expect(links.linkCalls, 1);
      expect(links.detailCalls, 1);
      expect(schedules.calls, 1);
      expect(prescriptions.calls, 1);
      expect(controller.bundleFor(_patientId), isNotNull);

      await controller.loadPatient(_patientId, force: true);
      expect(links.detailCalls, 2);
      expect(schedules.calls, 2);
      expect(prescriptions.calls, 2);
    },
  );
}

const _patientId = '507f1f77bcf86cd799439011';

class _FakeUserLinkApi extends UserLinkApi {
  int linkCalls = 0;
  int detailCalls = 0;

  @override
  Future<List<LinkedAccount>> getLinkedAccounts() async {
    linkCalls++;
    return const [
      LinkedAccount(
        linkId: 'link-1',
        linkedAt: null,
        patient: LinkedUserSummary(id: _patientId, fullName: 'Nguyễn Thị Lan'),
      ),
    ];
  }

  @override
  Future<PatientDetail> getPatientDetail(String patientId) async {
    detailCalls++;
    return const PatientDetail(
      id: _patientId,
      fullName: 'Nguyễn Thị Lan',
      email: 'lan@example.com',
      phone: '0900000000',
    );
  }

  @override
  void close() {}
}

class _FakeScheduleApi extends ScheduleApi {
  int calls = 0;

  @override
  Future<List<ScheduleRule>> list({String? patientId, bool? isActive}) async {
    calls++;
    return const [];
  }

  @override
  void close() {}
}

class _FakePrescriptionService extends PrescriptionService {
  int calls = 0;

  @override
  Future<List<Prescription>> listForPatient(String patientId) async {
    calls++;
    return const [];
  }
}

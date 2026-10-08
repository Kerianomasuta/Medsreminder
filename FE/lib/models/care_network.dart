import 'prescription.dart';
import 'schedule_rule.dart';

class LinkedUserSummary {
  const LinkedUserSummary({required this.id, required this.fullName});

  final String id;
  final String fullName;

  factory LinkedUserSummary.fromJson(Map<String, dynamic> json) =>
      LinkedUserSummary(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        fullName: (json['fullName'] ?? 'Người dùng').toString(),
      );
}

class LinkedAccount {
  const LinkedAccount({
    required this.linkId,
    required this.linkedAt,
    this.patient,
    this.caregiver,
  });

  final String linkId;
  final DateTime? linkedAt;
  final LinkedUserSummary? patient;
  final LinkedUserSummary? caregiver;

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    // `patienInfo` is supported temporarily because the current BE contains
    // that typo. Remove the fallback after the BE contract is corrected.
    final patientJson = json['patientInfo'] ?? json['patienInfo'];
    final caregiverJson = json['caregiverInfo'];
    return LinkedAccount(
      linkId: (json['linkId'] ?? json['_id'] ?? '').toString(),
      linkedAt: DateTime.tryParse((json['linkedAt'] ?? '').toString()),
      patient: patientJson is Map<String, dynamic>
          ? LinkedUserSummary.fromJson(patientJson)
          : null,
      caregiver: caregiverJson is Map<String, dynamic>
          ? LinkedUserSummary.fromJson(caregiverJson)
          : null,
    );
  }
}

class PatientDetail {
  const PatientDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;

  factory PatientDetail.fromJson(Map<String, dynamic> json) => PatientDetail(
    id: (json['_id'] ?? json['id'] ?? '').toString(),
    fullName: (json['fullName'] ?? 'Bệnh nhân').toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
  );
}

class PatientBundle {
  const PatientBundle({
    required this.detail,
    required this.schedules,
    required this.prescriptions,
  });

  final PatientDetail detail;
  final List<ScheduleRule> schedules;
  final List<Prescription> prescriptions;

  int get activePrescriptionCount =>
      prescriptions.where((item) => item.isActive).length;

  int get lowStockCount => prescriptions
      .expand((prescription) => prescription.items)
      .where((item) => item.isLowStock)
      .length;
}

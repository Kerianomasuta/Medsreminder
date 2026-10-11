enum DoseStatus { scheduled, snoozed, taken, skipped, missed }

extension DoseStatusData on DoseStatus {
  bool get isOpen => this == DoseStatus.scheduled || this == DoseStatus.snoozed;

  String get label => switch (this) {
    DoseStatus.scheduled => 'Đã đặt lịch',
    DoseStatus.snoozed => 'Đã hoãn',
    DoseStatus.taken => 'Đã uống',
    DoseStatus.skipped => 'Đã bỏ qua',
    DoseStatus.missed => 'Đã bỏ lỡ',
  };

  static DoseStatus fromApi(Object? value) => switch (value?.toString()) {
    'SCHEDULED' => DoseStatus.scheduled,
    'SNOOZED' => DoseStatus.snoozed,
    'TAKEN' => DoseStatus.taken,
    'SKIPPED' => DoseStatus.skipped,
    'MISSED' => DoseStatus.missed,
    _ => throw FormatException('Unsupported dose status: $value'),
  };
}

class MedicationLogMedicine {
  const MedicationLogMedicine({
    required this.name,
    required this.unit,
    this.genericName,
    this.imageUrl,
  });

  final String name;
  final String? genericName;
  final String unit;
  final String? imageUrl;

  factory MedicationLogMedicine.fromJson(Map<String, dynamic> json) =>
      MedicationLogMedicine(
        name: json['name']?.toString() ?? 'Thuốc',
        genericName: json['genericName']?.toString(),
        unit: json['unit']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
      );
}

class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.scheduleRuleId,
    required this.patientId,
    required this.scheduledAt,
    required this.status,
    required this.escalationLevel,
    this.actualTakenAt,
    this.snoozeUntil,
    this.skipReason,
    this.dosagePerTime,
    this.instructions,
    this.medicine,
  });

  final String id;
  final String scheduleRuleId;
  final String patientId;
  final DateTime scheduledAt;
  final DateTime? actualTakenAt;
  final DoseStatus status;
  final DateTime? snoozeUntil;
  final int escalationLevel;
  final String? skipReason;
  final double? dosagePerTime;
  final String? instructions;
  final MedicationLogMedicine? medicine;

  bool get isOpen => status.isOpen;
  bool get isFinal => !isOpen;
  DateTime get effectiveReminderAt =>
      status == DoseStatus.snoozed && snoozeUntil != null
      ? snoozeUntil!
      : scheduledAt;

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
    id: json['id']?.toString() ?? '',
    scheduleRuleId: json['scheduleRuleId']?.toString() ?? '',
    patientId: json['patientId']?.toString() ?? '',
    scheduledAt: _date(json['scheduledAt'], 'scheduledAt')!,
    actualTakenAt: _date(json['actualTakenAt'], 'actualTakenAt'),
    status: DoseStatusData.fromApi(json['status']),
    snoozeUntil: _date(json['snoozeUntil'], 'snoozeUntil'),
    escalationLevel: (json['escalationLevel'] as num?)?.toInt() ?? 0,
    skipReason: json['skipReason']?.toString(),
    dosagePerTime: (json['dosagePerTime'] as num?)?.toDouble(),
    instructions: json['instructions']?.toString(),
    medicine: json['medicine'] is Map<String, dynamic>
        ? MedicationLogMedicine.fromJson(
            json['medicine'] as Map<String, dynamic>,
          )
        : null,
  );

  static DateTime? _date(Object? value, String field) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) throw FormatException('Invalid $field: $value');
    return parsed.toLocal();
  }
}

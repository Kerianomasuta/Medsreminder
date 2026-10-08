class ScheduleMedicine {
  final String id;
  final String name;
  final String? genericName;
  final String unit;
  final String? imageUrl;

  const ScheduleMedicine({
    required this.id,
    required this.name,
    this.genericName,
    required this.unit,
    this.imageUrl,
  });

  factory ScheduleMedicine.fromJson(Map<String, dynamic> json) => ScheduleMedicine(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    genericName: json['genericName'] as String?,
    unit: json['unit'] as String? ?? 'VIEN',
    imageUrl: json['imageUrl'] as String?,
  );
}

class SchedulePrescription {
  final String id;
  final String title;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  const SchedulePrescription({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory SchedulePrescription.fromJson(Map<String, dynamic> json) => SchedulePrescription(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    startDate: json['startDate'] as String?,
    endDate: json['endDate'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}

class ScheduleRule {
  final String id;
  final String prescriptionItemId;
  final String patientId;
  final String reminderTime;
  final List<int> daysOfWeek;
  final bool isActive;
  final double dosagePerTime;
  final String? instructions;
  final ScheduleMedicine medicine;
  final SchedulePrescription prescription;

  const ScheduleRule({
    required this.id,
    required this.prescriptionItemId,
    required this.patientId,
    required this.reminderTime,
    required this.daysOfWeek,
    required this.isActive,
    required this.dosagePerTime,
    this.instructions,
    required this.medicine,
    required this.prescription,
  });

  String get displayTime {
    final parts = reminderTime.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return reminderTime;
  }

  String get period {
    final parts = reminderTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    if (hour < 11) return 'Sáng';
    if (hour < 14) return 'Trưa';
    if (hour < 18) return 'Chiều';
    return 'Tối';
  }

  factory ScheduleRule.fromJson(Map<String, dynamic> json) => ScheduleRule(
    id: json['id'] as String? ?? '',
    prescriptionItemId: json['prescriptionItemId'] as String? ?? '',
    patientId: json['patientId'] as String? ?? '',
    reminderTime: json['reminderTime'] as String? ?? '08:00:00',
    daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [1, 2, 3, 4, 5, 6, 7],
    isActive: json['isActive'] as bool? ?? true,
    dosagePerTime: (json['dosagePerTime'] as num?)?.toDouble() ?? 1.0,
    instructions: json['instructions'] as String?,
    medicine: ScheduleMedicine.fromJson(
      json['medicine'] as Map<String, dynamic>? ?? {},
    ),
    prescription: SchedulePrescription.fromJson(
      json['prescription'] as Map<String, dynamic>? ?? {},
    ),
  );
}

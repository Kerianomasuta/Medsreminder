// ─────────────────────────────────────────────────────────────────────────────
// Prescription Models
// Matches the NestJS microservice API contract exactly.
// ─────────────────────────────────────────────────────────────────────────────

class Schedule {
  final String? id;
  final String reminderTime; // "HH:mm"
  final List<int> daysOfWeek; // [1..7], empty means daily

  const Schedule({
    this.id,
    required this.reminderTime,
    required this.daysOfWeek,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String?,
    reminderTime: json['reminderTime'] as String,
    daysOfWeek:
        (json['daysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList() ??
        [],
  );

  /// Serialises for CREATE payload — omit daysOfWeek if full week.
  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{'reminderTime': reminderTime};
    final isFullWeek = daysOfWeek.toSet().containsAll({1, 2, 3, 4, 5, 6, 7});
    if (!isFullWeek && daysOfWeek.isNotEmpty) {
      map['daysOfWeek'] = daysOfWeek;
    }
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Drug Interaction Model
// ─────────────────────────────────────────────────────────────────────────────

class DrugInteraction {
  final bool checked;
  final bool hasWarning;
  final String summary;

  const DrugInteraction({
    required this.checked,
    required this.hasWarning,
    required this.summary,
  });

  factory DrugInteraction.fromJson(Map<String, dynamic> json) =>
      DrugInteraction(
        checked: json['checked'] == true,
        hasWarning: json['hasWarning'] == true,
        summary: json['summary']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'checked': checked,
    'hasWarning': hasWarning,
    'summary': summary,
  };
}

class PrescriptionItem {
  final String? id;
  final String medicineName;
  final String? genericName;
  final String unit;
  final String? imageUrl;
  final double dosagePerTime; // > 0
  final int currentStock; // >= 0
  final int reorderThreshold; // >= 0
  final String? instructions; // nullable
  final List<Schedule> schedules;
  final DrugInteraction? interaction;

  const PrescriptionItem({
    this.id,
    required this.medicineName,
    this.genericName,
    this.unit = 'VIEN',
    this.imageUrl,
    required this.dosagePerTime,
    required this.currentStock,
    required this.reorderThreshold,
    this.instructions,
    required this.schedules,
    this.interaction,
  });

  bool get isLowStock => currentStock <= reorderThreshold;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        id: json['id'] as String?,
        medicineName:
            (json['name'] ??
                    (json['medicine'] as Map<String, dynamic>?)?['name'] ??
                    'Thuốc')
                .toString(),
        genericName:
            (json['genericName'] ??
                    (json['medicine'] as Map<String, dynamic>?)?['genericName'])
                ?.toString(),
        unit:
            (json['unit'] ??
                    (json['medicine'] as Map<String, dynamic>?)?['unit'] ??
                    'VIEN')
                .toString(),
        imageUrl:
            (json['imageUrl'] ??
                    (json['medicine'] as Map<String, dynamic>?)?['imageUrl'])
                ?.toString(),
        dosagePerTime: (json['dosagePerTime'] as num).toDouble(),
        currentStock: json['currentStock'] as int,
        reorderThreshold: json['reorderThreshold'] as int,
        instructions: json['instructions'] as String?,
        schedules:
            (json['schedules'] as List<dynamic>?)
                ?.map((s) => Schedule.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        interaction: json['interaction'] != null
            ? DrugInteraction.fromJson(
                json['interaction'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{
      'name': medicineName,
      'unit': unit,
      'dosagePerTime': dosagePerTime,
      'currentStock': currentStock,
      'reorderThreshold': reorderThreshold,
      'schedules': schedules.map((s) => s.toCreateJson()).toList(),
    };
    if (instructions != null && instructions!.isNotEmpty) {
      map['instructions'] = instructions;
    }
    if (genericName != null && genericName!.isNotEmpty) {
      map['genericName'] = genericName;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) map['imageUrl'] = imageUrl;
    return map;
  }

  Map<String, dynamic> toPatchJson() {
    final map = <String, dynamic>{
      'dosagePerTime': dosagePerTime,
      'currentStock': currentStock,
      'reorderThreshold': reorderThreshold,
      'instructions': (instructions != null && instructions!.isNotEmpty)
          ? instructions
          : null,
    };
    return map;
  }

  Map<String, dynamic> toAddItemJson() => toCreateJson();
}

// ─────────────────────────────────────────────────────────────────────────────

class Prescription {
  final String? id;
  final String patientId; // Mongo ObjectId
  final String? createdByCgId; // Mongo ObjectId
  final String title;
  final String? doctorName;
  final String? prescriptionCode;
  final String? imagePrescriptionUrl;
  final String startDate; // "YYYY-MM-DD"
  final String? endDate; // "YYYY-MM-DD", >= startDate
  final bool isActive;
  final List<PrescriptionItem> items;
  final DrugInteraction? interaction;

  const Prescription({
    this.id,
    required this.patientId,
    this.createdByCgId,
    required this.title,
    this.doctorName,
    this.prescriptionCode,
    this.imagePrescriptionUrl,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.items = const [],
    this.interaction,
  });

  Prescription copyWith({
    String? id,
    String? patientId,
    String? createdByCgId,
    String? title,
    String? doctorName,
    String? prescriptionCode,
    String? imagePrescriptionUrl,
    String? startDate,
    String? endDate,
    bool? isActive,
    List<PrescriptionItem>? items,
    DrugInteraction? interaction,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      createdByCgId: createdByCgId ?? this.createdByCgId,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      prescriptionCode: prescriptionCode ?? this.prescriptionCode,
      imagePrescriptionUrl: imagePrescriptionUrl ?? this.imagePrescriptionUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      items: items ?? this.items,
      interaction: interaction ?? this.interaction,
    );
  }

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
    id: json['id'] as String?,
    patientId: json['patientId'] as String,
    createdByCgId: json['createdByCgId'] as String?,
    title: json['title'] as String,
    doctorName: json['doctorName'] as String?,
    prescriptionCode: json['prescriptionCode'] as String?,
    imagePrescriptionUrl: json['imagePrescriptionUrl'] as String?,
    startDate: json['startDate'] as String,
    endDate: json['endDate'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    items:
        (json['items'] as List<dynamic>?)
            ?.map((i) => PrescriptionItem.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [],
    interaction: json['interaction'] != null
        ? DrugInteraction.fromJson(json['interaction'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{
      'patientId': patientId,
      'createdByCgId': (createdByCgId != null && createdByCgId!.isNotEmpty)
          ? createdByCgId!
          : '6ac0cbf1ea185d34aa6f322a',
      'title': title,
      'startDate': startDate,
      'items': items.map((i) => i.toCreateJson()).toList(),
    };
    if (doctorName != null && doctorName!.isNotEmpty) {
      map['doctorName'] = doctorName;
    }
    if (prescriptionCode != null && prescriptionCode!.isNotEmpty) {
      map['prescriptionCode'] = prescriptionCode;
    }
    if (endDate != null) map['endDate'] = endDate;
    return map;
  }

  Map<String, dynamic> toPatchJson() {
    return {
      'title': title,
      'isActive': isActive,
      'startDate': startDate,
      'doctorName': (doctorName != null && doctorName!.isNotEmpty)
          ? doctorName
          : null,
      'prescriptionCode':
          (prescriptionCode != null && prescriptionCode!.isNotEmpty)
          ? prescriptionCode
          : null,
      'endDate': endDate,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mutable draft models for the Create Prescription Wizard local state.
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleDraft {
  String reminderTime;
  List<int> daysOfWeek;

  ScheduleDraft({this.reminderTime = '08:00', List<int>? daysOfWeek})
    : daysOfWeek = daysOfWeek ?? [];

  Schedule toSchedule() =>
      Schedule(reminderTime: reminderTime, daysOfWeek: daysOfWeek);
}

class PrescriptionItemDraft {
  String medicineName;
  String? genericName;
  String unit;
  String? imageUrl;
  double dosagePerTime;
  int currentStock;
  int reorderThreshold;
  String? instructions;
  List<ScheduleDraft> schedules;

  PrescriptionItemDraft({
    this.medicineName = '',
    this.genericName,
    this.unit = 'VIEN',
    this.imageUrl,
    this.dosagePerTime = 1,
    this.currentStock = 0,
    this.reorderThreshold = 0,
    this.instructions,
    List<ScheduleDraft>? schedules,
  }) : schedules = schedules ?? [ScheduleDraft()];

  PrescriptionItem toPrescriptionItem() => PrescriptionItem(
    medicineName: medicineName,
    genericName: genericName,
    unit: unit,
    imageUrl: imageUrl,
    dosagePerTime: dosagePerTime,
    currentStock: currentStock,
    reorderThreshold: reorderThreshold,
    instructions: instructions,
    schedules: schedules.map((s) => s.toSchedule()).toList(),
  );
}

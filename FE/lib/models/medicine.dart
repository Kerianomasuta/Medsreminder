enum MedicineUnit {
  vien('VIEN', 'Viên'),
  goi('GOI', 'Gói'),
  chai('CHAI', 'Chai');

  const MedicineUnit(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static MedicineUnit fromApi(String value) => values.firstWhere(
    (unit) => unit.apiValue == value,
    orElse: () => MedicineUnit.vien,
  );
}

class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.unit,
    this.genericName,
    this.instructionNote,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? genericName;
  final MedicineUnit unit;
  final String? instructionNote;
  final String? imageUrl;

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    genericName: json['genericName']?.toString(),
    unit: MedicineUnit.fromApi(json['unit']?.toString() ?? 'VIEN'),
    instructionNote: json['instructionNote']?.toString(),
    imageUrl: json['imageUrl']?.toString(),
  );
}

class MedicineInput {
  const MedicineInput({
    required this.name,
    required this.unit,
    this.genericName,
    this.instructionNote,
    this.imageUrl,
  });

  final String name;
  final String? genericName;
  final MedicineUnit unit;
  final String? instructionNote;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'genericName': _optional(genericName),
    'unit': unit.apiValue,
    'instructionNote': _optional(instructionNote),
    'imageUrl': _optional(imageUrl),
  };

  static String? _optional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

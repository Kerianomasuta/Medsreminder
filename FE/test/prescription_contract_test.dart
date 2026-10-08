import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/models/prescription.dart';

void main() {
  test('parses and serializes the current prescription item contract', () {
    final item = PrescriptionItem.fromJson({
      'id': '44444444-4444-4444-8444-444444444444',
      'prescriptionId': '33333333-3333-4333-8333-333333333333',
      'name': 'Paracetamol',
      'genericName': 'Acetaminophen',
      'unit': 'VIEN',
      'imageUrl': null,
      'dosagePerTime': 2,
      'currentStock': 30,
      'reorderThreshold': 6,
      'instructions': 'Sau ăn',
      'schedules': [
        {
          'id': '55555555-5555-4555-8555-555555555555',
          'reminderTime': '08:00:00',
          'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
        },
      ],
    });

    expect(item.medicineName, 'Paracetamol');
    expect(item.unit, 'VIEN');
    expect(item.schedules.single.reminderTime, '08:00:00');
    expect(item.toCreateJson(), containsPair('name', 'Paracetamol'));
    expect(item.toCreateJson(), containsPair('unit', 'VIEN'));
    expect(item.toCreateJson(), isNot(contains('medicineId')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/models/prescription.dart';
import 'package:meds_reminder/services/cloudinary_upload_service.dart';

void main() {
  group('CloudinaryUploadService & PrescriptionItem imageUrl tests', () {
    test('CloudinaryUploadService has configured cloudName and uploadPreset', () {
      final service = CloudinaryUploadService.instance;
      expect(service.cloudName, equals('pingbx2s'));
      expect(service.uploadPreset, equals('meds_medicine_preset'));
    });

    test('PrescriptionItem correctly parses and serializes imageUrl', () {
      const testImageUrl = 'https://res.cloudinary.com/pingbx2s/image/upload/v12345/medicine.jpg';
      final item = PrescriptionItem.fromJson({
        'name': 'Panadol Extra',
        'unit': 'VIEN',
        'imageUrl': testImageUrl,
        'dosagePerTime': 1,
        'currentStock': 20,
        'reorderThreshold': 5,
        'schedules': [],
      });

      expect(item.imageUrl, equals(testImageUrl));
      final createJson = item.toCreateJson();
      expect(createJson['imageUrl'], equals(testImageUrl));
    });
  });
}

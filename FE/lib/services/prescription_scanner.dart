import 'package:http/http.dart' as http;
import '../models/prescription.dart';
import 'prescription_scanner_stub.dart'
    if (dart.library.js_interop) 'prescription_scanner_web.dart' as platform;

Future<Prescription> scanPrescription({
  required String url,
  required List<int> imageBytes,
  required String filename,
  required String patientId,
  http.Client? client,
}) {
  return platform.scanPrescriptionPlatform(
    url: url,
    imageBytes: imageBytes,
    filename: filename,
    patientId: patientId,
    client: client,
  );
}

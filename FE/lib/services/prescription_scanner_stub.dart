import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prescription.dart';
import 'http_client_factory.dart';
import 'prescription_service.dart';

Future<Prescription> scanPrescriptionPlatform({
  required String url,
  required List<int> imageBytes,
  required String filename,
  required String patientId,
  http.Client? client,
}) async {
  final request = http.MultipartRequest('POST', Uri.parse(url))
    ..headers['Accept'] = 'application/json'
    ..fields['patientId'] = patientId
    ..files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ),
    );

  final httpClient = client ?? createHttpClient();
  late http.StreamedResponse response;
  try {
    response = await httpClient.send(request);
  } catch (_) {
    throw PrescriptionServiceException(
      0,
      'Không thể kết nối máy chủ. Vui lòng thử lại.',
    );
  }

  final body = await response.stream.bytesToString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return Prescription.fromJson(decoded);
  }

  String message = body;
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    message = (decoded['message'] ?? decoded['error'] ?? body).toString();
  } catch (_) {}
  throw PrescriptionServiceException(response.statusCode, message);
}

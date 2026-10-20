import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../models/prescription.dart';
import 'prescription_service.dart';

Future<Prescription> scanPrescriptionPlatform({
  required String url,
  required List<int> imageBytes,
  required String filename,
  required String patientId,
  http.Client? client,
}) async {
  final formData = web.FormData();
  formData.append('patientId', patientId.toJS);

  String mimeType = 'image/jpeg';
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) {
    mimeType = 'image/png';
  } else if (lower.endsWith('.webp')) {
    mimeType = 'image/webp';
  }

  final uint8List =
      imageBytes is Uint8List ? imageBytes : Uint8List.fromList(imageBytes);
  final jsArray = uint8List.toJS;
  final blobParts = [jsArray].toJS;
  final blobOptions = web.BlobPropertyBag(type: mimeType);
  final blob = web.Blob(blobParts, blobOptions);
  formData.append('image', blob, filename);

  final headers = web.Headers();
  headers.append('Accept', 'application/json');

  final init = web.RequestInit(
    method: 'POST',
    headers: headers,
    body: formData,
    credentials: 'include',
  );

  web.Response response;
  try {
    response = await web.window.fetch(url.toJS, init).toDart;
  } catch (_) {
    throw PrescriptionServiceException(
      0,
      'Không thể kết nối máy chủ. Vui lòng thử lại.',
    );
  }

  final status = response.status;
  final textJs = await response.text().toDart;
  final text = textJs.toDart;

  if (status >= 200 && status < 300) {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    return Prescription.fromJson(decoded);
  }

  String message = text;
  try {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    message = (decoded['message'] ?? decoded['error'] ?? text).toString();
  } catch (_) {}
  throw PrescriptionServiceException(status, message);
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadException implements Exception {
  final String message;
  const CloudinaryUploadException(this.message);

  @override
  String toString() => message;
}

/// Dịch vụ upload ảnh trực tiếp từ Flutter lên Cloudinary (Unsigned Upload).
///
/// Có thể truyền cấu hình qua `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
///   --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
/// ```
/// Hoặc điền trực tiếp vào [defaultCloudName] và [defaultUploadPreset] bên dưới.
class CloudinaryUploadService {
  CloudinaryUploadService._();
  static final CloudinaryUploadService instance = CloudinaryUploadService._();

  /// Điền Cloud Name của bạn vào đây nếu không dùng --dart-define
  static const String defaultCloudName = 'pingbx2s';

  /// Điền tên Unsigned Upload Preset của bạn vào đây nếu không dùng --dart-define
  static const String defaultUploadPreset = 'meds_medicine_preset';

  static const String _envCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _envUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  String get cloudName =>
      _envCloudName.trim().isNotEmpty ? _envCloudName.trim() : defaultCloudName;

  String get uploadPreset => _envUploadPreset.trim().isNotEmpty
      ? _envUploadPreset.trim()
      : defaultUploadPreset;

  final ImagePicker _picker = ImagePicker();

  /// Mở Camera hoặc Thư viện ảnh và tự động upload lên Cloudinary.
  /// Trả về `secure_url` (String) nếu thành công, hoặc `null` nếu người dùng huỷ chọn ảnh.
  Future<String?> pickAndUpload({
    required ImageSource source,
    String folder = 'medsreminder/medicines',
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return null;
    }

    return uploadFile(pickedFile, folder: folder);
  }

  /// Upload một [XFile] lên Cloudinary thông qua Unsigned Upload API.
  /// Sử dụng `fromBytes` để tương thích đồng thời trên cả iOS, Android và Web.
  Future<String> uploadFile(
    XFile file, {
    String folder = 'medsreminder/medicines',
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw const CloudinaryUploadException(
        'Chưa cấu hình CLOUDINARY_CLOUD_NAME hoặc CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty
        ? file.name
        : 'medicine_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send();
    } catch (_) {
      throw const CloudinaryUploadException(
        'Không thể kết nối tới Cloudinary. Vui lòng kiểm tra mạng.',
      );
    }

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode >= 200 &&
        streamedResponse.statusCode < 300) {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = (decoded['secure_url'] ?? decoded['url'])?.toString();
      if (secureUrl != null && secureUrl.isNotEmpty) {
        return secureUrl;
      }
      throw const CloudinaryUploadException(
        'Phản hồi từ Cloudinary không chứa đường dẫn ảnh.',
      );
    }

    String errorDetail = 'Upload ảnh thất bại (${streamedResponse.statusCode}).';
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final errObj = decoded['error'];
      if (errObj is Map<String, dynamic> && errObj['message'] != null) {
        errorDetail = 'Lỗi Cloudinary: ${errObj['message']}';
      }
    } catch (_) {}

    if (cloudName == 'demo') {
      errorDetail +=
          ' (Hãy cấu hình CLOUDINARY_CLOUD_NAME & CLOUDINARY_UPLOAD_PRESET trong cloudinary_upload_service.dart)';
    }

    throw CloudinaryUploadException(errorDetail);
  }
}

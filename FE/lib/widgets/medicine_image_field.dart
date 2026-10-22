import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_upload_service.dart';

/// Cụm giao diện chọn / chụp ảnh thuốc, tự động upload lên Cloudinary
/// và đồng bộ URL kết quả vào [controller].
class MedicineImageField extends StatefulWidget {
  const MedicineImageField({
    super.key,
    required this.controller,
    this.onUploadingChanged,
  });

  final TextEditingController controller;
  final ValueChanged<bool>? onUploadingChanged;

  @override
  State<MedicineImageField> createState() => _MedicineImageFieldState();
}

class _MedicineImageFieldState extends State<MedicineImageField> {
  bool _uploading = false;
  bool _showUrlInput = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _setUploading(bool value) {
    if (!mounted) return;
    setState(() => _uploading = value);
    widget.onUploadingChanged?.call(value);
  }

  Future<void> _handlePickAndUpload(ImageSource source) async {
    if (_uploading) return;
    _setUploading(true);
    try {
      final uploadedUrl = await CloudinaryUploadService.instance.pickAndUpload(
        source: source,
      );
      if (uploadedUrl != null && mounted) {
        widget.controller.text = uploadedUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải ảnh thuốc lên thành công!'),
            backgroundColor: Color(0xFF249D76),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD65B49),
          ),
        );
      }
    } finally {
      _setUploading(false);
    }
  }

  void _clearImage() {
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.controller.text.trim();
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDEE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Ô Xem trước ảnh (Preview) ─────────────────────────────────
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDEE2F5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _uploading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF5168F4),
                          ),
                        ),
                      )
                    : hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFFD65B49),
                                size: 26,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: GestureDetector(
                              onTap: _clearImage,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(
                          Icons.medication_liquid_rounded,
                          color: Color(0xFF9BA3C2),
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // ── Cụm 2 nút Chụp ảnh & Chọn từ máy ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploading
                                ? null
                                : () =>
                                      _handlePickAndUpload(ImageSource.camera),
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Chụp ảnh',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5168F4),
                              side: const BorderSide(color: Color(0xFFBCC3F5)),
                              backgroundColor: const Color(0xFFEEF0FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploading
                                ? null
                                : () => _handlePickAndUpload(
                                    ImageSource.gallery,
                                  ),
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Chọn từ máy',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5168F4),
                              side: const BorderSide(color: Color(0xFFBCC3F5)),
                              backgroundColor: const Color(0xFFEEF0FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _uploading
                                ? 'Đang tải ảnh lên Cloudinary...'
                                : hasImage
                                ? 'Đã gắn ảnh thuốc'
                                : 'Chưa có ảnh minh hoạ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _uploading
                                  ? const Color(0xFF5168F4)
                                  : hasImage
                                  ? const Color(0xFF249D76)
                                  : const Color(0xFF6B7492),
                              fontWeight: hasImage || _uploading
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showUrlInput = !_showUrlInput),
                          child: Text(
                            _showUrlInput ? 'Ẩn nhập link' : 'Nhập link URL',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5168F4),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showUrlInput) ...[
            const SizedBox(height: 10),
            TextField(
              controller: widget.controller,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://res.cloudinary.com/.../medicine.png',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: hasImage
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: _clearImage,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDEE2F5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDEE2F5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF5168F4),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

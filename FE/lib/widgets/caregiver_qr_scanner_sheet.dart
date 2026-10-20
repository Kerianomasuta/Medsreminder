import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/user_link_api.dart';

class CaregiverQrScannerSheet extends StatefulWidget {
  const CaregiverQrScannerSheet({super.key});

  /// Opens the scanner modal and returns the detected or manually entered UUID string.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CaregiverQrScannerSheet(),
    );
  }

  @override
  State<CaregiverQrScannerSheet> createState() => _CaregiverQrScannerSheetState();
}

class _CaregiverQrScannerSheetState extends State<CaregiverQrScannerSheet>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _laserAnim;
  final TextEditingController _manualController = TextEditingController();

  bool _isManualMode = false;
  bool _hasDetected = false;
  bool _isTorchOn = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;

      final uuid = UserLinkApi.extractInvitationUuid(raw);
      if (uuid != null && uuid.isNotEmpty) {
        _hasDetected = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(uuid);
        return;
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      final uuid = UserLinkApi.extractInvitationUuid(text);
      if (uuid != null && uuid.isNotEmpty) {
        _manualController.text = uuid;
      } else {
        _manualController.text = text;
      }
    }
  }

  void _submitManual() {
    final text = _manualController.text.trim();
    final uuid = UserLinkApi.extractInvitationUuid(text);
    if (uuid != null && uuid.isNotEmpty) {
      Navigator.of(context).pop(uuid);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã lời mời hợp lệ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF131728),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5066F3).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF7B8CF8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quét mã QR bệnh nhân',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Hướng camera vào mã QR để kết nối',
                        style: TextStyle(
                          color: Color(0xFF9EA6C8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF262C47), height: 1),

          // Body: Scanner or Manual Input
          Expanded(
            child: _isManualMode || _cameraError != null
                ? _buildManualInputView()
                : _buildScannerView(),
          ),

          // Bottom Bar Switcher
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF191F38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isManualMode = !_isManualMode;
                        _cameraError = null;
                      });
                    },
                    icon: Icon(
                      _isManualMode
                          ? Icons.camera_alt_rounded
                          : Icons.keyboard_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isManualMode ? 'Quét bằng camera' : 'Nhập mã thủ công',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF384370)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera stream
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _cameraError = error.errorCode.name);
              }
            });
            return const SizedBox.shrink();
          },
        ),

        // Semi-transparent cutout overlay
        LayoutBuilder(
          builder: (context, constraints) {
            final scanAreaSize = constraints.maxWidth * 0.72;
            final left = (constraints.maxWidth - scanAreaSize) / 2;
            final top = (constraints.maxHeight - scanAreaSize) / 2.3;

            return Stack(
              children: [
                // Darkened surround
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.65),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                      Positioned(
                        left: left,
                        top: top,
                        width: scanAreaSize,
                        height: scanAreaSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Corner brackets & Laser
                Positioned(
                  left: left,
                  top: top,
                  width: scanAreaSize,
                  height: scanAreaSize,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6E81FF),
                        width: 2.5,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _laserAnim,
                      builder: (context, _) => CustomPaint(
                        painter: _LaserLinePainter(progress: _laserAnim.value),
                      ),
                    ),
                  ),
                ),

                // Instruction under scanner
                Positioned(
                  left: 20,
                  right: 20,
                  top: top + scanAreaSize + 22,
                  child: const Center(
                    child: Text(
                      'Căn chỉnh mã QR của bệnh nhân vào giữa khung ngắm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD2D8F7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Floating Camera Controls (Torch & Switch)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _CircleGlassButton(
                        icon: _isTorchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _isTorchOn ? const Color(0xFFFFD54F) : Colors.white,
                        onTap: _toggleTorch,
                      ),
                      const SizedBox(height: 10),
                      _CircleGlassButton(
                        icon: Icons.flip_camera_ios_rounded,
                        color: Colors.white,
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildManualInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          if (_cameraError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF33202C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7A3644)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam_off_rounded, color: Color(0xFFF37588)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Không thể mở camera trên thiết bị này. Bạn có thể nhập mã mời bên dưới.',
                      style: TextStyle(color: Color(0xFFF8BDC6), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Nhập mã kết nối bệnh nhân',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhập chuỗi UUID hoặc đường dẫn lời mời được người bệnh chia sẻ.',
            style: TextStyle(color: Color(0xFF9EA6C8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _manualController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Mã mời hoặc link mời',
              labelStyle: const TextStyle(color: Color(0xFF9EA6C8)),
              prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF7B8CF8)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF7B8CF8)),
                tooltip: 'Dán từ bộ nhớ tạm',
                onPressed: _pasteFromClipboard,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF323A5E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6E81FF), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFF1C223D),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submitManual,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Xác nhận kết nối'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5066F3),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaserLinePainter extends CustomPainter {
  _LaserLinePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFF8193FF),
          Color(0xFFC0CAFF),
          Color(0xFF8193FF),
          Colors.transparent,
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, y, size.width, 3))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
  }

  @override
  bool shouldRepaint(covariant _LaserLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CircleGlassButton extends StatelessWidget {
  const _CircleGlassButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

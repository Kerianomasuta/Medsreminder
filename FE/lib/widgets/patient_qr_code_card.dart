import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'glass.dart';

class PatientQrCodeCard extends StatefulWidget {
  const PatientQrCodeCard({
    super.key,
    required this.invitationUuid,
    this.invitationLink,
    required this.patientName,
    this.createdAt,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  final String invitationUuid;
  final String? invitationLink;
  final String patientName;
  final DateTime? createdAt;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  State<PatientQrCodeCard> createState() => _PatientQrCodeCardState();
}

class _PatientQrCodeCardState extends State<PatientQrCodeCard> {
  Timer? _ticker;
  Duration _remaining = const Duration(minutes: 15);
  bool _showRawUuid = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant PatientQrCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invitationUuid != widget.invitationUuid ||
        oldWidget.createdAt != widget.createdAt) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final created = widget.createdAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(created);
    const ttl = Duration(minutes: 15);
    final remaining = ttl - elapsed;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _qrPayload =>
      (widget.invitationLink != null && widget.invitationLink!.isNotEmpty)
          ? widget.invitationLink!
          : widget.invitationUuid;

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;

    return Glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFF5066F3),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã QR kết nối người chăm sóc',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E285F),
                      ),
                    ),
                    Text(
                      'Đưa mã này cho người chăm sóc để quét',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E7590),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFFFDE8E8)
                      : const Color(0xFFE6F8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpired
                          ? Icons.timer_off_outlined
                          : Icons.timer_outlined,
                      size: 14,
                      color: isExpired
                          ? const Color(0xFFC64E57)
                          : const Color(0xFF249D76),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? 'Hết hạn' : _formatDuration(_remaining),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isExpired
                            ? const Color(0xFFC64E57)
                            : const Color(0xFF249D76),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // QR Display Box
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD8DEFF),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3D4FC2).withValues(alpha: .08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: QrImageView(
                      data: _qrPayload,
                      version: QrVersions.auto,
                      size: 210,
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF3444B4),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1B234F),
                      ),
                    ),
                  ),
                ),
                if (isExpired)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 40,
                              color: Color(0xFFC64E57),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mã QR đã hết hạn',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFC64E57),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: widget.isRefreshing ? null : widget.onRefresh,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Tạo mã mới'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF5066F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Patient identity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_rounded,
                  size: 18,
                  color: Color(0xFF5066F3),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF283891),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Fallback UUID View / Toggle
          InkWell(
            onTap: () => setState(() => _showRawUuid = !_showRawUuid),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showRawUuid
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: const Color(0xFF6E7590),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showRawUuid
                        ? 'Ẩn mã văn bản'
                        : 'Xem mã văn bản (sao chép)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E7590),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showRawUuid) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEFFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                widget.invitationUuid,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF3D4FC2),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isRefreshing ? null : widget.onRefresh,
                  icon: widget.isRefreshing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Làm mới'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Sao chép mã'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5066F3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final textToCopy = widget.invitationUuid;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép mã mời vào bộ nhớ tạm.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

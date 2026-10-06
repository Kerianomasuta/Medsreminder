import 'package:flutter/material.dart';

import '../../../models/prescription.dart';
import '../../../services/prescription_service.dart';
import '../../../widgets/glass.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/app_components.dart';
import 'prescription_detail_screen.dart';
import 'create_prescription_screen.dart';

// ---------------------------------------------------------------------------
// Prescription List Screen
// Shows all prescriptions for a patient; FAB navigates to Create screen.
// ---------------------------------------------------------------------------

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  List<Prescription> _prescriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await PrescriptionService.instance.listForPatient(widget.patientId);
      if (mounted) setState(() => _prescriptions = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Đơn thuốc',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2A54),
                  ),
                ),
                Text(
                  'Bệnh nhân: ${widget.patientName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF687195),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _prescriptions.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-prescription-fab',
        onPressed: _openCreate,
        backgroundColor: const Color(0xFF5168F4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tạo đơn thuốc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildList() => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        itemCount: _prescriptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _PrescriptionTile(
          prescription: _prescriptions[i],
          onTap: () => _openDetail(_prescriptions[i]),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EBFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Color(0xFF5168F4),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chưa có đơn thuốc nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2A54),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhấn nút bên dưới để tạo đơn thuốc đầu tiên.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF687195)),
              ),
            ],
          ),
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Color(0xFFD65B49)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD65B49)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );

  void _openDetail(Prescription p) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PrescriptionDetailScreen(prescriptionId: p.id!),
      ),
    );
    _load(); // refresh after returning
  }

  void _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreatePrescriptionScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    );
    if (created == true) _load();
  }
}

// ---------------------------------------------------------------------------

class _PrescriptionTile extends StatelessWidget {
  const _PrescriptionTile({
    required this.prescription,
    required this.onTap,
  });

  final Prescription prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = prescription.isActive;
    return Pressable(
      onTap: onTap,
      child: Glass(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE7E9FF)
                    : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_rounded,
                color: isActive
                    ? const Color(0xFF5267F4)
                    : const Color(0xFF9BA3BF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prescription.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (prescription.doctorName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'BS: ${prescription.doctorName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7492),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _formatDateRange(prescription.startDate, prescription.endDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF717993),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(
                  isActive ? 'Đang dùng' : 'Ngừng',
                  isActive
                      ? const Color(0xFF249D76)
                      : const Color(0xFF9BA3BF),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF9BA3BF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(String start, String? end) {
    final s = _formatDate(start);
    if (end == null) return 'Từ $s';
    return '$s – ${_formatDate(end)}';
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

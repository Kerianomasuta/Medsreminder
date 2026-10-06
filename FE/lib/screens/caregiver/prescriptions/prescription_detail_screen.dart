import 'package:flutter/material.dart';

import '../../../models/prescription.dart';
import '../../../services/prescription_service.dart';
import '../../../widgets/glass.dart';
import '../../../widgets/app_components.dart';
import 'add_item_sheet.dart';
import 'edit_prescription_sheet.dart';

// ---------------------------------------------------------------------------
// Prescription Detail Screen
// ---------------------------------------------------------------------------

class PrescriptionDetailScreen extends StatefulWidget {
  const PrescriptionDetailScreen({super.key, required this.prescriptionId});
  final String prescriptionId;

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  Prescription? _prescription;
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
      final data = await PrescriptionService.instance
          .getById(widget.prescriptionId);
      if (mounted) setState(() => _prescription = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: const Text(
          'Chi tiết đơn thuốc',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_prescription != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Chỉnh sửa thông tin',
              onPressed: _openEdit,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      floatingActionButton: _prescription != null
          ? FloatingActionButton.extended(
              heroTag: 'add-item-fab',
              onPressed: _openAddItem,
              backgroundColor: const Color(0xFF5168F4),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Thêm thuốc',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    final p = _prescription!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        // ── General info card ─────────────────────────────────────────────
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.isActive
                          ? const Color(0xFFE7E9FF)
                          : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: p.isActive
                          ? const Color(0xFF5267F4)
                          : const Color(0xFF9BA3BF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  StatusChip(
                    p.isActive ? 'Đang dùng' : 'Ngừng',
                    p.isActive
                        ? const Color(0xFF249D76)
                        : const Color(0xFF9BA3BF),
                  ),
                ],
              ),
              const Divider(height: 24),
              _infoRow(Icons.person_outline_rounded, 'Bác sĩ',
                  p.doctorName ?? 'Không rõ'),
              const SizedBox(height: 8),
              _infoRow(Icons.tag_rounded, 'Mã đơn',
                  p.prescriptionCode ?? 'Không có'),
              const SizedBox(height: 8),
              _infoRow(Icons.calendar_today_rounded, 'Bắt đầu',
                  _formatDate(p.startDate)),
              if (p.endDate != null) ...[
                const SizedBox(height: 8),
                _infoRow(Icons.event_rounded, 'Kết thúc',
                    _formatDate(p.endDate!)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section title ─────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Danh sách thuốc',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2A54),
            ),
          ),
        ),

        if (p.items.isEmpty)
          Glass(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'Chưa có thuốc nào. Nhấn "Thêm thuốc" để bắt đầu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF687195)),
              ),
            ),
          ),

        ...p.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ItemCard(
                item: item,
                onEditSaved: _load,
              ),
            )),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5267F4)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7492),
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
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

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPrescriptionSheet(
        prescription: _prescription!,
        onSaved: _load,
      ),
    );
  }

  void _openAddItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(
        prescriptionId: widget.prescriptionId,
        onSaved: _load,
      ),
    );
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

// ---------------------------------------------------------------------------
// Item Card Widget
// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onEditSaved});
  final PrescriptionItem item;
  final VoidCallback onEditSaved;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.isLowStock;
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: Color(0xFF5167F2), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.medicineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Liều: ${item.dosagePerTime % 1 == 0 ? item.dosagePerTime.toInt() : item.dosagePerTime} / lần',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7492)),
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: const Color(0xFF5267F4),
                tooltip: 'Chỉnh sửa thuốc',
                onPressed: () => _openItemEdit(context),
              ),
            ],
          ),
          const Divider(height: 16),
          // Stock row
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: Color(0xFF6B7492)),
              const SizedBox(width: 6),
              Text(
                'Tồn kho: ${item.currentStock}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.notification_important_outlined,
                  size: 14, color: Color(0xFF6B7492)),
              const SizedBox(width: 6),
              Text(
                'Ngưỡng: ${item.reorderThreshold}',
                style: const TextStyle(fontSize: 12),
              ),
              if (lowStock) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFD65B49).withValues(alpha: .4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: Color(0xFFD65B49)),
                      SizedBox(width: 4),
                      Text(
                        'Sắp hết',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD65B49),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (item.instructions != null && item.instructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note_alt_outlined,
                    size: 14, color: Color(0xFF6B7492)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.instructions!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7492)),
                  ),
                ),
              ],
            ),
          ],
          // Schedules
          if (item.schedules.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.schedules.map((s) => _ScheduleChip(s)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _openItemEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(item: item, onSaved: onEditSaved),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip(this.schedule);
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final days = schedule.daysOfWeek.isEmpty
        ? 'Mỗi ngày'
        : schedule.daysOfWeek.map((d) => _dayLabel(d)).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBCC3F5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alarm_rounded, size: 12, color: Color(0xFF5168F4)),
          const SizedBox(width: 5),
          Text(
            '${schedule.reminderTime} · $days',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4459D9),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int d) => ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][d - 1];
}

// ---------------------------------------------------------------------------
// Quick Edit Item Sheet (inline, reuses prescription item)
// ---------------------------------------------------------------------------

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({required this.item, required this.onSaved});
  final PrescriptionItem item;
  final VoidCallback onSaved;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late TextEditingController _dosageCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _thresholdCtrl;
  late TextEditingController _instructionsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _dosageCtrl = TextEditingController(text: i.dosagePerTime.toString());
    _stockCtrl = TextEditingController(text: i.currentStock.toString());
    _thresholdCtrl = TextEditingController(text: i.reorderThreshold.toString());
    _instructionsCtrl = TextEditingController(text: i.instructions ?? '');
  }

  @override
  void dispose() {
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final dosage = double.tryParse(_dosageCtrl.text.trim());
    if (dosage == null || dosage <= 0) {
      _showError('Liều dùng phải là số > 0');
      return;
    }
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (stock == null || stock < 0) {
      _showError('Tồn kho phải là số nguyên >= 0');
      return;
    }
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    if (threshold == null || threshold < 0) {
      _showError('Ngưỡng tái đặt phải là số nguyên >= 0');
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = PrescriptionItem(
        id: widget.item.id,
        medicineId: widget.item.medicineId,
        medicineName: widget.item.medicineName,
        dosagePerTime: dosage,
        currentStock: stock,
        reorderThreshold: threshold,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        schedules: widget.item.schedules,
      );
      await PrescriptionService.instance
          .updateItem(widget.item.id!, updated);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFD65B49),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
      padding: EdgeInsets.fromLTRB(22, 14, 22, 22 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D8EF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chỉnh sửa: ${widget.item.medicineName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _field('Liều dùng / lần', _dosageCtrl,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Tồn kho hiện tại', _stockCtrl,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Ngưỡng đặt lại', _thresholdCtrl,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Hướng dẫn sử dụng', _instructionsCtrl, maxLines: 2),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('Lưu thay đổi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5168F4),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDEE2F5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDEE2F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF5168F4), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

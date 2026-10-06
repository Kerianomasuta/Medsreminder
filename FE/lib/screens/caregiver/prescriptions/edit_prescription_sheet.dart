import 'package:flutter/material.dart';
import '../../../models/prescription.dart';
import '../../../services/prescription_service.dart';

// ---------------------------------------------------------------------------
// Edit Prescription Bottom Sheet
// PATCH: title, doctorName, prescriptionCode, startDate, endDate, isActive
// ---------------------------------------------------------------------------

class EditPrescriptionSheet extends StatefulWidget {
  const EditPrescriptionSheet({
    super.key,
    required this.prescription,
    required this.onSaved,
  });
  final Prescription prescription;
  final VoidCallback onSaved;

  @override
  State<EditPrescriptionSheet> createState() => _EditPrescriptionSheetState();
}

class _EditPrescriptionSheetState extends State<EditPrescriptionSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _doctorCtrl;
  late TextEditingController _codeCtrl;
  DateTime? _startDate;
  DateTime? _endDate;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prescription;
    _titleCtrl = TextEditingController(text: p.title);
    _doctorCtrl = TextEditingController(text: p.doctorName ?? '');
    _codeCtrl = TextEditingController(text: p.prescriptionCode ?? '');
    _startDate = _tryParse(p.startDate);
    _endDate = p.endDate != null ? _tryParse(p.endDate!) : null;
    _isActive = p.isActive;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doctorCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  DateTime? _tryParse(String s) {
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _display(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Chọn ngày bắt đầu' : 'Chọn ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Enforce endDate >= startDate
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        if (_startDate != null && picked.isBefore(_startDate!)) {
          _showError('Ngày kết thúc phải >= ngày bắt đầu');
          return;
        }
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Tiêu đề không được để trống');
      return;
    }
    if (_startDate == null) {
      _showError('Vui lòng chọn ngày bắt đầu');
      return;
    }

    setState(() => _saving = true);
    try {
      final patch = Prescription(
        id: widget.prescription.id,
        patientId: widget.prescription.patientId,
        title: _titleCtrl.text.trim(),
        doctorName: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
        prescriptionCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        startDate: _fmt(_startDate!),
        endDate: _endDate != null ? _fmt(_endDate!) : null,
        isActive: _isActive,
      );
      await PrescriptionService.instance
          .updateInfo(widget.prescription.id!, patch.toPatchJson());
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

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD65B49)));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
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
                width: 44, height: 5,
                decoration: BoxDecoration(color: const Color(0xFFD4D8EF), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF5168F4),
                  child: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chỉnh sửa đơn thuốc',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 20),
            _label('Tiêu đề đơn thuốc *'),
            _textField(_titleCtrl, 'Ví dụ: Liệu trình huyết áp & tiểu đường'),
            const SizedBox(height: 14),
            _label('Tên bác sĩ'),
            _textField(_doctorCtrl, 'Ví dụ: BS. Nguyễn Văn A'),
            const SizedBox(height: 14),
            _label('Mã đơn thuốc'),
            _textField(_codeCtrl, 'Ví dụ: RX-20260901'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Ngày bắt đầu *'),
                      _datePicker(
                        value: _startDate != null ? _display(_startDate!) : 'Chọn ngày',
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Ngày kết thúc'),
                      _datePicker(
                        value: _endDate != null ? _display(_endDate!) : 'Tuỳ chọn',
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label('Trạng thái'),
            Row(
              children: [
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: const Color(0xFF249D76),
                ),
                Text(
                  _isActive ? 'Đang sử dụng' : 'Ngừng sử dụng',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _isActive ? const Color(0xFF249D76) : const Color(0xFF9BA3BF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5168F4),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _textField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDEE2F5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDEE2F5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5168F4), width: 1.6)),
        ),
      );

  Widget _datePicker({required String value, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDEE2F5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF5168F4)),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

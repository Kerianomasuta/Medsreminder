import 'package:flutter/material.dart';

import '../../../models/prescription.dart';
import '../../../services/prescription_service.dart';

// ---------------------------------------------------------------------------
// Add Item Sheet
// POST /api/v1/prescriptions/{id}/items
// Medicine data is stored directly on the prescription line.
// ---------------------------------------------------------------------------

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({
    super.key,
    required this.prescriptionId,
    required this.onSaved,
  });
  final String prescriptionId;
  final VoidCallback onSaved;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _genericNameCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String _unit = 'VIEN';

  // ── Item fields ──────────────────────────────────────────────────────────
  final _dosageCtrl = TextEditingController(text: '1');
  final _stockCtrl = TextEditingController(text: '30');
  final _thresholdCtrl = TextEditingController(text: '5');
  final _instructionsCtrl = TextEditingController();

  final List<ScheduleDraft> _schedules = [ScheduleDraft()];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericNameCtrl.dispose();
    _imageUrlCtrl.dispose();
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final medicineName = _nameCtrl.text.trim();
    if (medicineName.isEmpty || medicineName.length > 200) {
      _showError('Tên thuốc bắt buộc và tối đa 200 ký tự');
      return;
    }
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
      _showError('Ngưỡng đặt lại phải là số nguyên >= 0');
      return;
    }
    for (final s in _schedules) {
      if (!PrescriptionValidator.isValidTime(s.reminderTime)) {
        _showError('Giờ nhắc không hợp lệ: ${s.reminderTime}. Cần HH:mm');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final item = PrescriptionItem(
        medicineName: medicineName,
        genericName: _genericNameCtrl.text.trim().isEmpty
            ? null
            : _genericNameCtrl.text.trim(),
        unit: _unit,
        imageUrl: _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        dosagePerTime: dosage,
        currentStock: stock,
        reorderThreshold: threshold,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        schedules: _schedules.map((s) => s.toSchedule()).toList(),
      );
      await PrescriptionService.instance.addItem(widget.prescriptionId, item);
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

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD65B49)),
  );

  Future<void> _pickTime(int index) async {
    final current = _schedules[index].reminderTime.split(':');
    final h = int.tryParse(current[0]) ?? 8;
    final m = int.tryParse(current[1]) ?? 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked == null) return;
    setState(() {
      _schedules[index].reminderTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  void _addSchedule() => setState(() => _schedules.add(ScheduleDraft()));
  void _removeSchedule(int i) {
    if (_schedules.length > 1) setState(() => _schedules.removeAt(i));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.06),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF5168F4),
                  child: Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Thêm thuốc vào đơn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _label('Tên thuốc *'),
            _tf(_nameCtrl, 'Ví dụ: Paracetamol'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Hoạt chất (tuỳ chọn)'),
                      _tf(_genericNameCtrl, 'Ví dụ: Acetaminophen'),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Đơn vị *'),
                      DropdownButtonFormField<String>(
                        initialValue: _unit,
                        items: const [
                          DropdownMenuItem(value: 'VIEN', child: Text('Viên')),
                          DropdownMenuItem(value: 'GOI', child: Text('Gói')),
                          DropdownMenuItem(value: 'CHAI', child: Text('Chai')),
                        ],
                        onChanged: (value) => setState(() => _unit = value!),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _label('URL ảnh thuốc (tuỳ chọn)'),
            _tf(_imageUrlCtrl, 'https://example.com/medicine.png'),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Liều / lần'),
                      _tf(_dosageCtrl, '1', keyboard: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tồn kho'),
                      _tf(_stockCtrl, '30', keyboard: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Ngưỡng đặt'),
                      _tf(_thresholdCtrl, '5', keyboard: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _label('Hướng dẫn sử dụng (tuỳ chọn)'),
            _tf(
              _instructionsCtrl,
              'Ví dụ: Uống sau bữa ăn cùng nước lọc',
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Lịch nhắc',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSchedule,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Thêm giờ'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_schedules.length, _scheduleRow),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_rounded),
              label: const Text(
                'Thêm thuốc vào đơn',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5168F4),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  );

  Widget _tf(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF5168F4), width: 1.6),
      ),
    ),
  );

  Widget _scheduleRow(int index) {
    final s = _schedules[index];
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              const Icon(
                Icons.alarm_rounded,
                size: 16,
                color: Color(0xFF5168F4),
              ),
              const SizedBox(width: 8),
              const Text(
                'Giờ nhắc',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickTime(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBCC3F5)),
                  ),
                  child: Text(
                    s.reminderTime,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5168F4),
                    ),
                  ),
                ),
              ),
              if (_schedules.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeSchedule(index),
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Color(0xFFD65B49),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Ngày trong tuần (bỏ chọn = mỗi ngày)',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7492)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: List.generate(7, (di) {
              final dayNum = di + 1;
              final selected = s.daysOfWeek.contains(dayNum);
              return FilterChip(
                label: Text(days[di]),
                selected: selected,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF2D3748),
                ),
                selectedColor: const Color(0xFF5168F4),
                checkmarkColor: Colors.white,
                backgroundColor: const Color(0xFFF0F0F8),
                side: BorderSide.none,
                onSelected: (v) => setState(() {
                  if (v) {
                    s.daysOfWeek.add(dayNum);
                  } else {
                    s.daysOfWeek.remove(dayNum);
                  }
                  s.daysOfWeek.sort();
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}

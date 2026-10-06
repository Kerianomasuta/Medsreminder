import 'package:flutter/material.dart';
import '../../../models/medicine.dart';
import '../../../models/prescription.dart';
import '../../../services/medicine_api.dart';
import '../../../services/prescription_service.dart';
import '../../../widgets/glass.dart';

// ---------------------------------------------------------------------------
// Create Prescription Screen — 2-step Wizard
// Step 1: General Info (title, doctor, code, dates, isActive)
// Step 2: Medicines list  (add / remove items + schedules locally)
//         Then POST the nested JSON to the API.
// ---------------------------------------------------------------------------

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });
  final String patientId;
  final String patientName;

  @override
  State<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  int _step = 0;

  // ── Step 1 state ─────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;

  // ── Step 2 state ─────────────────────────────────────────────────────────
  final List<PrescriptionItemDraft> _items = [];

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doctorCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _display(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Chọn ngày bắt đầu' : 'Chọn ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        if (picked.isBefore(_startDate)) {
          _showError('Ngày kết thúc phải >= ngày bắt đầu');
          return;
        }
        _endDate = picked;
      }
    });
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD65B49)));

  // ── Navigation ────────────────────────────────────────────────────────────

  void _nextStep() {
    if (_step == 0) {
      if (_titleCtrl.text.trim().isEmpty) {
        _showError('Tiêu đề không được để trống');
        return;
      }
      setState(() => _step = 1);
    }
  }

  void _prevStep() => setState(() => _step = 0);

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_items.isEmpty) {
      _showError('Cần ít nhất 1 loại thuốc');
      return;
    }
    for (final item in _items) {
      if (!PrescriptionValidator.isValidUuid(item.medicineId)) {
        _showError('medicineId của "${item.medicineName}" không hợp lệ');
        return;
      }
      if (item.medicineName.trim().isEmpty) {
        _showError('Tên thuốc không được để trống');
        return;
      }
      if (item.dosagePerTime <= 0) {
        _showError('Liều dùng của "${item.medicineName}" phải > 0');
        return;
      }
      if (item.schedules.isEmpty) {
        _showError('Thuốc "${item.medicineName}" cần ít nhất 1 lịch nhắc');
        return;
      }
      for (final s in item.schedules) {
        if (!PrescriptionValidator.isValidTime(s.reminderTime)) {
          _showError('Giờ nhắc "${s.reminderTime}" không hợp lệ (cần HH:mm)');
          return;
        }
      }
    }

    setState(() => _submitting = true);
    try {
      final prescription = Prescription(
        patientId: widget.patientId,
        title: _titleCtrl.text.trim(),
        doctorName: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
        prescriptionCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        startDate: _fmt(_startDate),
        endDate: _endDate != null ? _fmt(_endDate!) : null,
        isActive: _isActive,
        items: _items.map((d) => d.toPrescriptionItem()).toList(),
      );

      await PrescriptionService.instance.create(prescription);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo đơn thuốc thành công!'),
            backgroundColor: Color(0xFF249D76),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Tạo đơn thuốc mới',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _step == 0
                  ? _Step1(
                      key: const ValueKey(0),
                      titleCtrl: _titleCtrl,
                      doctorCtrl: _doctorCtrl,
                      codeCtrl: _codeCtrl,
                      startDate: _startDate,
                      endDate: _endDate,
                      isActive: _isActive,
                      patientName: widget.patientName,
                      onPickStart: () => _pickDate(isStart: true),
                      onPickEnd: () => _pickDate(isStart: false),
                      onToggleActive: (v) => setState(() => _isActive = v),
                      displayDate: _display,
                      onNext: _nextStep,
                    )
                  : _Step2(
                      key: const ValueKey(1),
                      items: _items,
                      submitting: _submitting,
                      onBack: _prevStep,
                      onAddItem: () => _showAddItemDialog(),
                      onRemoveItem: (i) => setState(() => _items.removeAt(i)),
                      onSubmit: _submit,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
        child: Row(
          children: [
            _StepDot(
              number: 1,
              label: 'Thông tin',
              active: _step == 0,
              done: _step > 0,
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _step > 0
                        ? [const Color(0xFF5168F4), const Color(0xFF5168F4)]
                        : [const Color(0xFFDEE2F5), const Color(0xFFDEE2F5)],
                  ),
                ),
              ),
            ),
            _StepDot(
              number: 2,
              label: 'Thuốc',
              active: _step == 1,
              done: false,
            ),
          ],
        ),
      );

  void _showAddItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemDraftSheet(
        onAdded: (draft) {
          setState(() => _items.add(draft));
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Dot indicator
// ---------------------------------------------------------------------------

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  final int number;
  final String label;
  final bool active, done;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active || done
                  ? const Color(0xFF5168F4)
                  : const Color(0xFFDEE2F5),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF9BA3BF),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active
                  ? const Color(0xFF5168F4)
                  : const Color(0xFF9BA3BF),
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Step 1 Widget — General Info Form
// ---------------------------------------------------------------------------

class _Step1 extends StatelessWidget {
  const _Step1({
    super.key,
    required this.titleCtrl,
    required this.doctorCtrl,
    required this.codeCtrl,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.patientName,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onToggleActive,
    required this.displayDate,
    required this.onNext,
  });

  final TextEditingController titleCtrl, doctorCtrl, codeCtrl;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String patientName;
  final VoidCallback onPickStart, onPickEnd;
  final ValueChanged<bool> onToggleActive;
  final String Function(DateTime) displayDate;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Glass(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: Color(0xFF5267F4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bệnh nhân: $patientName',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF249D76)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label('Tiêu đề đơn thuốc *'),
          _tf(titleCtrl, 'Ví dụ: Liệu trình huyết áp tháng 10'),
          const SizedBox(height: 14),
          _label('Tên bác sĩ'),
          _tf(doctorCtrl, 'Ví dụ: BS. Trần Thị B'),
          const SizedBox(height: 14),
          _label('Mã đơn thuốc'),
          _tf(codeCtrl, 'Ví dụ: RX-20261001'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Ngày bắt đầu *'),
                    _datePicker(
                      value: displayDate(startDate),
                      onTap: onPickStart,
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
                      value: endDate != null ? displayDate(endDate!) : 'Tuỳ chọn',
                      onTap: onPickEnd,
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
                value: isActive,
                onChanged: onToggleActive,
                activeThumbColor: const Color(0xFF249D76),
              ),
              Text(
                isActive ? 'Đang sử dụng' : 'Ngừng sử dụng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xFF249D76) : const Color(0xFF9BA3BF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text(
              'Tiếp theo: Thêm thuốc',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5168F4),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _tf(TextEditingController ctrl, String hint) => TextField(
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

// ---------------------------------------------------------------------------
// Step 2 Widget — Medicines List
// ---------------------------------------------------------------------------

class _Step2 extends StatelessWidget {
  const _Step2({
    super.key,
    required this.items,
    required this.submitting,
    required this.onBack,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onSubmit,
  });

  final List<PrescriptionItemDraft> items;
  final bool submitting;
  final VoidCallback onBack, onAddItem, onSubmit;
  final ValueChanged<int> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Danh sách thuốc',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1F2A54)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm thuốc'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Glass(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.medication_outlined, size: 40, color: Color(0xFFB0B8D8)),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có thuốc nào.\nNhấn "Thêm thuốc" để bắt đầu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF687195)),
                      ),
                    ],
                  ),
                ),
              ...List.generate(
                items.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DraftItemCard(
                    draft: items[i],
                    onRemove: () => onRemoveItem(i),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Quay lại'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(110, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('Tạo đơn thuốc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF249D76),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Draft Item Card (preview in Step 2)
// ---------------------------------------------------------------------------

class _DraftItemCard extends StatelessWidget {
  const _DraftItemCard({required this.draft, required this.onRemove});
  final PrescriptionItemDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Glass(
      padding: const EdgeInsets.all(14),
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
                    color: Color(0xFF5167F2), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.medicineName.isEmpty ? '(Tên thuốc)' : draft.medicineName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      'Liều: ${draft.dosagePerTime}/lần  ·  Kho: ${draft.currentStock}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7492)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD65B49)),
                tooltip: 'Xoá thuốc',
                onPressed: onRemove,
              ),
            ],
          ),
          if (draft.schedules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: draft.schedules.map((s) {
                final dayStr = s.daysOfWeek.isEmpty
                    ? 'Mỗi ngày'
                    : s.daysOfWeek
                        .map((d) => days[d - 1])
                        .join(', ');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBCC3F5)),
                  ),
                  child: Text(
                    '${s.reminderTime} · $dayStr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4459D9),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Item Draft Sheet (local — no API call yet)
// ---------------------------------------------------------------------------

class _AddItemDraftSheet extends StatefulWidget {
  const _AddItemDraftSheet({required this.onAdded});
  final ValueChanged<PrescriptionItemDraft> onAdded;

  @override
  State<_AddItemDraftSheet> createState() => _AddItemDraftSheetState();
}

class _AddItemDraftSheetState extends State<_AddItemDraftSheet> {
  // ── Medicine search ──────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  Medicine? _selectedMedicine;
  List<Medicine> _suggestions = [];
  bool _searching = false;
  bool _showDropdown = false;

  // ── Item fields ──────────────────────────────────────────────────────────
  final _dosageCtrl = TextEditingController(text: '1');
  final _stockCtrl = TextEditingController(text: '30');
  final _thresholdCtrl = TextEditingController(text: '5');
  final _instructionsCtrl = TextEditingController();

  final List<ScheduleDraft> _schedules = [ScheduleDraft()];
  final _api = MedicineApi();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _instructionsCtrl.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _suggestions = []; _showDropdown = false; });
      return;
    }
    setState(() { _searching = true; _showDropdown = true; });
    try {
      final results = await _api.list(search: query.trim());
      if (mounted) setState(() => _suggestions = results);
    } catch (_) {
      if (mounted) {
        setState(() => _suggestions = _mockMedicines
            .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
            .toList());
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectMedicine(Medicine m) {
    setState(() {
      _selectedMedicine = m;
      _searchCtrl.text = m.name;
      _showDropdown = false;
      _suggestions = [];
      if (m.instructionNote != null && _instructionsCtrl.text.isEmpty) {
        _instructionsCtrl.text = m.instructionNote!;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMedicine = null;
      _searchCtrl.clear();
      _showDropdown = false;
      _suggestions = [];
    });
  }

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

  void _confirm() {
    if (_selectedMedicine == null) {
      _showError('Vui lòng chọn thuốc từ danh sách');
      return;
    }
    final dosage = double.tryParse(_dosageCtrl.text.trim());
    if (dosage == null || dosage <= 0) {
      _showError('Liều dùng phải > 0');
      return;
    }
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (stock == null || stock < 0) {
      _showError('Tồn kho phải >= 0');
      return;
    }
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    if (threshold == null || threshold < 0) {
      _showError('Ngưỡng đặt lại phải >= 0');
      return;
    }

    for (final s in _schedules) {
      if (!PrescriptionValidator.isValidTime(s.reminderTime)) {
        _showError('Giờ nhắc "${s.reminderTime}" không hợp lệ (HH:mm)');
        return;
      }
    }

    final draft = PrescriptionItemDraft(
      medicineId: _selectedMedicine!.id,
      medicineName: _selectedMedicine!.name,
      dosagePerTime: dosage,
      currentStock: stock,
      reorderThreshold: threshold,
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      schedules: List.from(_schedules),
    );

    Navigator.of(context).pop();
    widget.onAdded(draft);
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD65B49)));

  @override
  Widget build(BuildContext context) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
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
                width: 44, height: 5,
                decoration: BoxDecoration(color: const Color(0xFFD4D8EF), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Color(0xFF5168F4), child: Icon(Icons.medication_rounded, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                const Expanded(child: Text('Thêm thuốc vào đơn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 20),

            _lbl('Tìm kiếm thuốc *'),
            if (_selectedMedicine != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5168F4), width: 1.6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF5168F4), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedMedicine!.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(_selectedMedicine!.unit.label,
                              style: const TextStyle(color: Color(0xFF6B7492), fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearSelection,
                      child: const Icon(Icons.close_rounded, color: Color(0xFF6B7492), size: 20),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Gõ tên thuốc để tìm kiếm...',
                  prefixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5168F4)),
                          ),
                        )
                      : const Icon(Icons.search_rounded, color: Color(0xFF5168F4)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDEE2F5))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDEE2F5))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5168F4), width: 1.6)),
                ),
              ),
              if (_showDropdown && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDEE2F5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _2) => const Divider(height: 1, indent: 14, endIndent: 14),
                    itemBuilder: (context, i) {
                      final m = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFEEF0FF),
                          child: Icon(Icons.medication_rounded, color: Color(0xFF5168F4), size: 16),
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(m.unit.label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7492))),
                        onTap: () => _selectMedicine(m),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Liều / lần'),
                  _tf(_dosageCtrl, '1', keyboard: TextInputType.number),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Tồn kho'),
                  _tf(_stockCtrl, '30', keyboard: TextInputType.number),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Ngưỡng đặt'),
                  _tf(_thresholdCtrl, '5', keyboard: TextInputType.number),
                ])),
              ],
            ),
            const SizedBox(height: 12),
            _lbl('Hướng dẫn (tuỳ chọn)'),
            _tf(_instructionsCtrl, 'Uống sau bữa ăn...', maxLines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Lịch nhắc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _schedules.add(ScheduleDraft())),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Thêm giờ'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_schedules.length, (index) {
              final s = _schedules[index];
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
                        const Icon(Icons.alarm_rounded, size: 16, color: Color(0xFF5168F4)),
                        const SizedBox(width: 8),
                        const Text('Giờ nhắc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _pickTime(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF0FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBCC3F5)),
                            ),
                            child: Text(
                              s.reminderTime,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF5168F4)),
                            ),
                          ),
                        ),
                        if (_schedules.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _schedules.removeAt(index)),
                            child: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFD65B49), size: 20),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Ngày trong tuần (bỏ chọn = mỗi ngày)', style: TextStyle(fontSize: 12, color: Color(0xFF6B7492))),
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
            }),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Xác nhận thêm thuốc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _tf(TextEditingController ctrl, String hint,
      {TextInputType? keyboard, int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
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
}

final _mockMedicines = [
  const Medicine(id: 'aaaaaaaa-0001-4000-a000-000000000001', name: 'Amlodipine 5mg', unit: MedicineUnit.vien),
  const Medicine(id: 'aaaaaaaa-0002-4000-a000-000000000002', name: 'Atorvastatin 10mg', unit: MedicineUnit.vien),
  const Medicine(id: 'aaaaaaaa-0003-4000-a000-000000000003', name: 'Metformin 500mg', unit: MedicineUnit.vien),
  const Medicine(id: 'aaaaaaaa-0004-4000-a000-000000000004', name: 'Vitamin D3 1000IU', unit: MedicineUnit.vien),
  const Medicine(id: 'aaaaaaaa-0005-4000-a000-000000000005', name: 'Lisinopril 10mg', unit: MedicineUnit.vien),
  const Medicine(id: 'aaaaaaaa-0006-4000-a000-000000000006', name: 'Omeprazole 20mg', unit: MedicineUnit.vien),
];


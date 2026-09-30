import 'package:flutter/material.dart';

void showAddMedicineModal(
    BuildContext context, {
      required VoidCallback onAdded,
      bool isPatient = false,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: AddMedicineSheet(
          onAdded: onAdded,
          isPatient: isPatient,
        ),
      ),
    ),
  );
}

class MedicineFormItem {
  const MedicineFormItem({
    required this.name,
    required this.icon,
    required this.defaultDose,
    required this.dosageHints,
    required this.suggestedNote,
  });
  final String name;
  final IconData icon;
  final String defaultDose;
  final List<String> dosageHints;
  final String suggestedNote;
}

const List<MedicineFormItem> kMedicineForms = [
  MedicineFormItem(
    name: 'Viên nang',
    icon: Icons.medication_liquid_rounded,
    defaultDose: '1 viên / lần',
    dosageHints: ['1 viên', '2 viên', '1/2 viên'],
    suggestedNote: 'Uống nguyên viên cùng nước lọc',
  ),
  MedicineFormItem(
    name: 'Viên nén',
    icon: Icons.circle_rounded,
    defaultDose: '1 viên / lần',
    dosageHints: ['1 viên', '2 viên', '1/2 viên'],
    suggestedNote: 'Uống sau bữa ăn no',
  ),
  MedicineFormItem(
    name: 'Dạng nước / siro',
    icon: Icons.water_drop_rounded,
    defaultDose: '10 ml / lần',
    dosageHints: ['5 ml', '10 ml', '15 ml', '1 nắp'],
    suggestedNote: 'Lắc đều trước khi uống, dùng cốc đong',
  ),
  MedicineFormItem(
    name: 'Dạng bột / gói',
    icon: Icons.all_inbox_rounded,
    defaultDose: '1 gói / lần',
    dosageHints: ['1 gói', '2 gói', '1/2 gói'],
    suggestedNote: 'Pha tan với 100ml nước ấm',
  ),
  MedicineFormItem(
    name: 'Dạng xịt / hít',
    icon: Icons.air_rounded,
    defaultDose: '2 nhát xịt / lần',
    dosageHints: ['1 nhát', '2 nhát', '3 nhát'],
    suggestedNote: 'Xịt thẳng vào vòm họng / khoang mũi',
  ),
  MedicineFormItem(
    name: 'Dạng bôi ngoài da',
    icon: Icons.healing_rounded,
    defaultDose: 'Thoa 1 lớp mỏng',
    dosageHints: ['1 lớp mỏng', '2 lần / ngày'],
    suggestedNote: 'Vệ sinh sạch da trước khi thoa thuốc',
  ),
];

class AddMedicineSheet extends StatefulWidget {
  const AddMedicineSheet({
    super.key,
    required this.onAdded,
    this.isPatient = false,
  });
  final VoidCallback onAdded;
  final bool isPatient;

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _timeController;
  late TextEditingController _noteController;
  int _selectedFormIndex = 0;
  String _selectedMealTiming = 'Sau bữa ăn';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.isPatient ? 'Vitamin C 500mg' : 'Vitamin tổng hợp Centrum',
    );
    _doseController = TextEditingController(
      text: kMedicineForms[0].defaultDose,
    );
    _timeController = TextEditingController(text: '08:00 sáng');
    _noteController = TextEditingController(
      text: 'Uống Sau bữa ăn, ${kMedicineForms[0].suggestedNote}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _timeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectForm(int index) {
    setState(() {
      _selectedFormIndex = index;
      _doseController.text = kMedicineForms[index].defaultDose;
      _noteController.text = 'Uống $_selectedMealTiming, ${kMedicineForms[index].suggestedNote}';
    });
  }

  Widget _mealTimingBox(String title, IconData icon) {
    final isSelected = _selectedMealTiming == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMealTiming = title;
            _noteController.text = 'Uống $title, ${kMedicineForms[_selectedFormIndex].suggestedNote}';
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5168F4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF5168F4) : const Color(0xFFDEE2F5),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF5168F4).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF5168F4),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentForm = kMedicineForms[_selectedFormIndex];

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
      padding: EdgeInsets.fromLTRB(22, 14, 22, 22 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPatient ? 'Thêm thuốc mới (Bệnh nhân)' : 'Thêm đơn thuốc & Giờ nhắc',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.isPatient
                            ? 'Tự thêm thuốc bổ/ngoài đơn và báo cho người chăm sóc'
                            : 'Thiết lập liều dùng và giờ nhắc cho người bệnh',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tên thuốc',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nhập tên thuốc hoặc thực phẩm bổ sung...',
                prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
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
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Dạng thuốc',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EBFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'viên nang, viên nén, dạng nước...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4353C4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(kMedicineForms.length, (index) {
                final form = kMedicineForms[index];
                final isSelected = index == _selectedFormIndex;
                return InkWell(
                  onTap: () => _selectForm(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF5168F4) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5168F4) : const Color(0xFFDEE2F5),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xFF5168F4).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          form.icon,
                          size: 17,
                          color: isSelected ? Colors.white : const Color(0xFF5168F4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          form.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Liều dùng',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _doseController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 1 viên / lần, 10 ml / lần...',
                prefixIcon: const Icon(Icons.pin_outlined, size: 20),
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
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: currentForm.dosageHints.map((hint) {
                return ActionChip(
                  label: Text(hint, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFEDEFFC),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () {
                    setState(() {
                      _doseController.text = '$hint / lần';
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Khung giờ nhắc uống',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                hintText: 'Chọn giờ nhắc...',
                prefixIcon: const Icon(Icons.alarm_rounded, size: 20),
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
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                '08:00 sáng',
                '12:30 trưa',
                '20:00 tối',
                '08:00 & 20:00',
              ].map((time) {
                return ActionChip(
                  label: Text(time, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFEDEFFC),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () {
                    setState(() {
                      _timeController.text = time;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Lưu ý khi uống',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EBFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Đang chọn: $_selectedMealTiming',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4353C4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _mealTimingBox('Trước bữa ăn', Icons.timer_outlined),
                const SizedBox(width: 8),
                _mealTimingBox('Sau bữa ăn', Icons.restaurant_rounded),
                const SizedBox(width: 8),
                _mealTimingBox('Trong khi ăn', Icons.flatware_rounded),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Ghi chú hướng dẫn thêm',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Uống sau bữa ăn no, uống nhiều nước...',
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
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
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final medName = _nameController.text.trim().isEmpty
                    ? 'Thuốc mới'
                    : _nameController.text.trim();
                widget.onAdded();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF249D76),
                    content: Text(
                      'Đã lưu "$medName" (Dạng ${currentForm.name} · $_selectedMealTiming) vào lịch nhắc thành công!',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                widget.isPatient
                    ? 'Lưu thuốc & Báo người chăm sóc'
                    : 'Lưu đơn thuốc & Đặt lịch nhắc',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
}

import 'package:flutter/material.dart';

import '../models/medicine.dart';

class MedicineDetailDialog extends StatelessWidget {
  const MedicineDetailDialog({super.key, required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
    contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
    title: Row(
      children: [
        _MedicineImage(url: medicine.imageUrl, size: 52),
        const SizedBox(width: 12),
        Expanded(child: Text(medicine.name)),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow('Hoạt chất', medicine.genericName ?? 'Chưa cập nhật'),
          _DetailRow('Đơn vị', medicine.unit.label),
          _DetailRow('Hướng dẫn', medicine.instructionNote ?? 'Chưa cập nhật'),
        ],
      ),
    ),
    actions: [
      FilledButton.icon(
        onPressed: () => Navigator.pop(context, true),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Chỉnh sửa'),
      ),
    ],
  );
}

class MedicineFormDialog extends StatefulWidget {
  const MedicineFormDialog({super.key, this.medicine});
  final Medicine? medicine;

  @override
  State<MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<MedicineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_MedicineDraft> _drafts = [];

  bool get _isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    _drafts.add(_MedicineDraft.fromMedicine(widget.medicine));
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    setState(() => _drafts.add(_MedicineDraft.fromMedicine(null)));
  }

  void _removeDraft(int index) {
    if (_drafts.length == 1) return;
    final draft = _drafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _drafts
          .map(
            (draft) => MedicineInput(
              name: draft.name.text,
              genericName: draft.genericName.text,
              unit: draft.unit,
              instructionNote: draft.note.text,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
    title: Row(
      children: [
        Expanded(child: Text(_isEditing ? 'Chỉnh sửa thuốc' : 'Thêm thuốc')),
        if (!_isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_drafts.length} thuốc',
              style: const TextStyle(
                color: Color(0xFF4F62D7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    ),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.64,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _drafts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _MedicineDraftCard(
              key: ObjectKey(_drafts[index]),
              draft: _drafts[index],
              index: index,
              autofocus: index == 0,
              canRemove: !_isEditing && _drafts.length > 1,
              onRemove: () => _removeDraft(index),
              decoration: _decoration,
              onUnitChanged: (unit) {
                setState(() => _drafts[index].unit = unit);
              },
            ),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      if (!_isEditing)
        OutlinedButton.icon(
          onPressed: _addDraft,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm thuốc khác'),
        ),
      FilledButton(
        onPressed: _submit,
        child: Text(
          _isEditing
              ? 'Lưu thay đổi'
              : _drafts.length == 1
              ? 'Thêm thuốc'
              : 'Thêm ${_drafts.length} thuốc',
        ),
      ),
    ],
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF3F6FC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

class _MedicineDraft {
  _MedicineDraft.fromMedicine(Medicine? medicine)
    : name = TextEditingController(text: medicine?.name),
      genericName = TextEditingController(text: medicine?.genericName),
      note = TextEditingController(text: medicine?.instructionNote),
      unit = medicine?.unit ?? MedicineUnit.vien;

  final TextEditingController name;
  final TextEditingController genericName;
  final TextEditingController note;
  MedicineUnit unit;

  void dispose() {
    name.dispose();
    genericName.dispose();
    note.dispose();
  }
}

class _MedicineDraftCard extends StatelessWidget {
  const _MedicineDraftCard({
    super.key,
    required this.draft,
    required this.index,
    required this.autofocus,
    required this.canRemove,
    required this.onRemove,
    required this.decoration,
    required this.onUnitChanged,
  });

  final _MedicineDraft draft;
  final int index;
  final bool autofocus;
  final bool canRemove;
  final VoidCallback onRemove;
  final InputDecoration Function(String, IconData) decoration;
  final ValueChanged<MedicineUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FE),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E6F5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE4E9FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF4F62D7),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Thuốc ${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF263653),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: 'Xóa thuốc này',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFC44955),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: draft.name,
          autofocus: autofocus,
          textInputAction: TextInputAction.next,
          decoration: decoration('Tên thuốc *', Icons.medication_outlined),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Vui lòng nhập tên thuốc' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: draft.genericName,
          textInputAction: TextInputAction.next,
          decoration: decoration('Tên hoạt chất', Icons.science_outlined),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<MedicineUnit>(
          initialValue: draft.unit,
          decoration: decoration('Đơn vị *', Icons.straighten_rounded),
          items: MedicineUnit.values
              .map(
                (unit) =>
                    DropdownMenuItem(value: unit, child: Text(unit.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onUnitChanged(value);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: draft.note,
          maxLines: 2,
          decoration: decoration('Hướng dẫn sử dụng', Icons.notes_rounded),
        ),
      ],
    ),
  );
}

class _MedicineImage extends StatelessWidget {
  const _MedicineImage({required this.url, required this.size});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: size,
      height: size,
      color: const Color(0xFFE8EEFC),
      child: url?.isNotEmpty == true
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.medication_rounded,
                color: Color(0xFF536EB1),
              ),
            )
          : const Icon(Icons.medication_rounded, color: Color(0xFF536EB1)),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(label, style: const TextStyle(color: Color(0xFF718096))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

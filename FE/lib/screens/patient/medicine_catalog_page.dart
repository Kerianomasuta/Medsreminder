import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/medicine.dart';
import '../../services/medicine_api.dart';
import '../../widgets/widgets.dart';

class MedicineCatalogPage extends StatefulWidget {
  const MedicineCatalogPage({super.key, this.api});
  final MedicineApi? api;

  @override
  State<MedicineCatalogPage> createState() => _MedicineCatalogPageState();
}

class _MedicineCatalogPageState extends State<MedicineCatalogPage> {
  late final MedicineApi _api;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Medicine> _medicines = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? MedicineApi();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.list(search: _searchController.text);
      if (mounted) setState(() => _medicines = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _openCreate() async {
    final input = await showDialog<MedicineInput>(
      context: context,
      builder: (_) => const MedicineFormDialog(),
    );
    if (input == null) return;
    await _runMutation(() => _api.create(input), 'Đã thêm thuốc mới');
  }

  Future<void> _openDetails(Medicine summary) async {
    try {
      final medicine = await _api.getById(summary.id);
      if (!mounted) return;
      final edit = await showDialog<bool>(
        context: context,
        builder: (_) => MedicineDetailDialog(medicine: medicine),
      );
      if (edit == true && mounted) await _openEdit(medicine);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _openEdit(Medicine medicine) async {
    final input = await showDialog<MedicineInput>(
      context: context,
      builder: (_) => MedicineFormDialog(medicine: medicine),
    );
    if (input == null) return;
    await _runMutation(
      () => _api.update(medicine.id, input),
      'Đã cập nhật thuốc',
    );
  }

  Future<void> _runMutation(
    Future<Medicine> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage);
      await _load();
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFC44955)
            : const Color(0xFF24866B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: PageIntro(
                'Danh mục thuốc',
                'Tìm nhanh theo tên thuốc hoặc hoạt chất',
              ),
            ),
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm thuốc'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Glass(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Panadol hoặc Paracetamol',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? IconButton(
                      tooltip: 'Tải lại',
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                    )
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _searchController.clear();
                        _load();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(38),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          _ErrorState(message: _error!, onRetry: _load)
        else if (_medicines.isEmpty)
          _EmptyState(onCreate: _openCreate)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 570
                  ? 2
                  : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _medicines
                    .map(
                      (medicine) => SizedBox(
                        width: width,
                        child: _MedicineCard(
                          medicine: medicine,
                          onTap: () => _openDetails(medicine),
                          onEdit: () => _openEdit(medicine),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    ),
  );
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.onTap,
    required this.onEdit,
  });
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _MedicineImage(url: medicine.imageUrl, size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF173764),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    medicine.genericName?.isNotEmpty == true
                        ? medicine.genericName!
                        : 'Chưa có tên hoạt chất',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6E7C92),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _UnitChip(unit: medicine.unit),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Chỉnh sửa',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF526DB1)),
            ),
          ],
        ),
      ),
    ),
  );
}

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
  late final TextEditingController _name;
  late final TextEditingController _genericName;
  late final TextEditingController _note;
  late final TextEditingController _imageUrl;
  late MedicineUnit _unit;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    _name = TextEditingController(text: medicine?.name);
    _genericName = TextEditingController(text: medicine?.genericName);
    _note = TextEditingController(text: medicine?.instructionNote);
    _imageUrl = TextEditingController(text: medicine?.imageUrl);
    _unit = medicine?.unit ?? MedicineUnit.vien;
  }

  @override
  void dispose() {
    _name.dispose();
    _genericName.dispose();
    _note.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    title: Text(widget.medicine == null ? 'Thêm thuốc' : 'Chỉnh sửa thuốc'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: _decoration(
                  'Tên thuốc *',
                  Icons.medication_outlined,
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Vui lòng nhập tên thuốc'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genericName,
                decoration: _decoration(
                  'Tên hoạt chất',
                  Icons.science_outlined,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MedicineUnit>(
                initialValue: _unit,
                decoration: _decoration('Đơn vị *', Icons.straighten_rounded),
                items: MedicineUnit.values
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _unit = value ?? _unit),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: _decoration(
                  'Hướng dẫn sử dụng',
                  Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                decoration: _decoration(
                  'URL hình ảnh (không bắt buộc)',
                  Icons.image_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            MedicineInput(
              name: _name.text,
              genericName: _genericName.text,
              unit: _unit,
              instructionNote: _note.text,
              imageUrl: _imageUrl.text,
            ),
          );
        },
        child: Text(widget.medicine == null ? 'Thêm thuốc' : 'Lưu thay đổi'),
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

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.unit});
  final MedicineUnit unit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F8F3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      unit.label,
      style: const TextStyle(
        color: Color(0xFF238169),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(22),
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Color(0xFFC05A62),
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.medication_liquid_rounded,
            size: 48,
            color: Color(0xFF6681BF),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chưa có thuốc phù hợp',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm thuốc đầu tiên'),
          ),
        ],
      ),
    ),
  );
}

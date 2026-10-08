import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/pharmacist_dashboard_controller.dart';
import '../../models/medicine.dart';
import '../../widgets/medicine_management_dialogs.dart';
import '../../widgets/widgets.dart';

class PharmacistMedicineCatalogPage extends StatefulWidget {
  const PharmacistMedicineCatalogPage({super.key, required this.controller});

  final PharmacistDashboardController controller;

  @override
  State<PharmacistMedicineCatalogPage> createState() =>
      _PharmacistMedicineCatalogPageState();
}

class _PharmacistMedicineCatalogPageState
    extends State<PharmacistMedicineCatalogPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searching = false;

  PharmacistDashboardController get controller => widget.controller;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search([String? value]) async {
    if (!mounted) return;
    setState(() => _searching = true);
    try {
      await controller.searchMedicines(search: value ?? _searchController.text);
    } catch (error) {
      _message(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _create() async {
    final inputs = await showDialog<List<MedicineInput>>(
      context: context,
      builder: (_) => const MedicineFormDialog(),
    );
    if (inputs == null || inputs.isEmpty || !mounted) return;
    try {
      await controller.createMedicines(inputs);
      _searchController.clear();
      _message(
        inputs.length == 1
            ? 'Đã tạo thuốc mới'
            : 'Đã tạo ${inputs.length} thuốc mới',
      );
    } catch (error) {
      _message(error.toString(), isError: true);
    }
  }

  Future<void> _details(Medicine summary) async {
    try {
      final medicine = await controller.loadMedicineDetail(summary.id);
      if (!mounted) return;
      final edit = await showDialog<bool>(
        context: context,
        builder: (_) => MedicineDetailDialog(medicine: medicine),
      );
      if (edit == true && mounted) await _edit(medicine);
    } catch (error) {
      _message(error.toString(), isError: true);
    }
  }

  Future<void> _edit(Medicine medicine) async {
    final inputs = await showDialog<List<MedicineInput>>(
      context: context,
      builder: (_) => MedicineFormDialog(medicine: medicine),
    );
    if (inputs == null || inputs.isEmpty || !mounted) return;
    try {
      await controller.updateMedicine(medicine.id, inputs.single);
      _searchController.clear();
      _message('Đã cập nhật thuốc');
    } catch (error) {
      _message(error.toString(), isError: true);
    }
  }

  void _message(String message, {bool isError = false}) {
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
  Widget build(BuildContext context) {
    final pharmacy = controller.selectedPharmacy;
    if (pharmacy == null) {
      return AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            PageIntro(
              'Danh mục thuốc',
              'Tạo nhà thuốc trước khi quản lý danh mục',
            ),
            SizedBox(height: 14),
            Glass(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_business_rounded,
                      size: 48,
                      color: Color(0xFF6681BF),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Chưa có nhà thuốc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Mở tab Nhà thuốc để đăng ký trước khi thêm thuốc.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final medicines = controller.catalogMedicines;
    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PageIntro(
                  'Danh mục thuốc',
                  '${medicines.length} thuốc · ${pharmacy.name}',
                ),
              ),
              FilledButton.icon(
                onPressed: controller.saving ? null : _create,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo thuốc'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Glass(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên thuốc hoặc hoạt chất',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: _searchController.text.isEmpty
                            ? 'Tải lại'
                            : 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                        icon: Icon(
                          _searchController.text.isEmpty
                              ? Icons.refresh_rounded
                              : Icons.close_rounded,
                        ),
                      ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (controller.error != null)
            Glass(
              padding: const EdgeInsets.all(16),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Color(0xFFC44955)),
              ),
            )
          else if (medicines.isEmpty)
            Glass(
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: controller.saving ? null : _create,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tạo thuốc đầu tiên'),
                    ),
                  ],
                ),
              ),
            )
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
                  children: medicines
                      .map(
                        (medicine) => SizedBox(
                          width: width,
                          child: _MedicineCard(
                            medicine: medicine,
                            onDetails: () => _details(medicine),
                            onEdit: () => _edit(medicine),
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
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.onDetails,
    required this.onEdit,
  });

  final Medicine medicine;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(22),
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _MedicineImage(url: medicine.imageUrl),
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
                    style: const TextStyle(color: Color(0xFF6E7C92)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicine.unit.label,
                    style: const TextStyle(
                      color: Color(0xFF238169),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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

class _MedicineImage extends StatelessWidget {
  const _MedicineImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 54,
      height: 54,
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

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class CaregiverHome extends StatelessWidget {
  const CaregiverHome({
    super.key,
    required this.tab,
    required this.doseTaken,
    required this.doseMissed,
    required this.prescriptionAdded,
    required this.linkedPatients,
    required this.activePatientIndex,
    required this.onMissed,
    required this.onPrescriptionAdded,
    required this.onAddPatient,
    required this.onRemovePatient,
    required this.onSelectPatient,
  });

  final int tab;
  final bool doseTaken, doseMissed, prescriptionAdded;
  final List<PatientProfileItem> linkedPatients;
  final int activePatientIndex;
  final VoidCallback onMissed, onPrescriptionAdded;
  final void Function(String code, {String? name, String? relation}) onAddPatient;
  final ValueChanged<int> onRemovePatient;
  final ValueChanged<int> onSelectPatient;

  @override
  Widget build(BuildContext context) {
    if (tab == 1) {
      return CaregiverPrescriptionPage(
        added: prescriptionAdded,
        onAdded: onPrescriptionAdded,
      );
    }
    if (tab == 4) {
      return CaregiverProfilePage(
        linkedPatients: linkedPatients,
        activePatientIndex: activePatientIndex,
        onAddPatient: onAddPatient,
        onRemovePatient: onRemovePatient,
        onSelectPatient: onSelectPatient,
      );
    }
    final hasPatients = linkedPatients.isNotEmpty;
    final currentPatient =
    hasPatients ? linkedPatients[activePatientIndex] : null;

    return AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro('Chào Anh!', 'Theo dõi sức khoẻ người thân'),
          if (doseMissed) const AlertCard(),
          if (!hasPatients)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Glass(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.link_off_rounded, color: Color(0xFFE2794D)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chưa liên kết bệnh nhân nào. Hãy chuyển sang tab "Hồ sơ" để nhập mã kết nối.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (linkedPatients.length > 1) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: linkedPatients.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final p = linkedPatients[idx];
                  final isSelected = idx == activePatientIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () => onSelectPatient(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5065F2)
                            : Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5065F2)
                              : const Color(0xFFD6DBF5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            p.avatarIcon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF5065F2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${p.name} (${p.relation})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2C3E6E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (currentPatient != null)
            Glass(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: currentPatient.avatarBg,
                    child: Icon(
                      currentPatient.avatarIcon,
                      color: const Color(0xFFAD6047),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentPatient.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9EDFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentPatient.relation,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF485EE8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentPatient.age} tuổi · Mã: ${currentPatient.code} · ${currentPatient.condition}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF249D76),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Liệu trình hôm nay',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '16 tháng 9',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    StatusChip(
                      doseTaken ? 'Hoàn thành 1/3' : 'Chờ xác nhận',
                      doseTaken
                          ? const Color(0xFF249D76)
                          : const Color(0xFFF09B3C),
                    ),
                  ],
                ),
                const Divider(height: 25),
                MedicationRow(
                  '07:30',
                  'Metformin + Vitamin D3',
                  doseTaken ? 'Đã uống' : 'Đang chờ',
                  doseTaken ? const Color(0xFF259F78) : const Color(0xFFF0A042),
                ),
                const SizedBox(height: 14),
                const MedicationRow(
                  '12:30',
                  'Amlodipine 5mg',
                  'Sắp tới',
                  Color(0xFF5C70F2),
                ),
                const SizedBox(height: 14),
                const MedicationRow(
                  '20:00',
                  'Atorvastatin 10mg',
                  'Sắp tới',
                  Color(0xFF5C70F2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onMissed,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Demo: quá 15 phút chưa phản hồi'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: const Color(0xFFD35A44),
              side: const BorderSide(color: Color(0xFFF0B1A5)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mức thuốc còn lại',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Glass(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.medication_liquid_rounded,
                  color: Color(0xFFE1784C),
                  size: 30,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metformin 500mg',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text('Còn khoảng 4 ngày · Nên đặt thuốc'),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF5267F4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CaregiverPrescriptionPage extends StatelessWidget {
  const CaregiverPrescriptionPage({
    super.key,
    required this.added,
    required this.onAdded,
  });

  final bool added;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Đơn thuốc của cô Lan',
          'Quản lý và thiết lập lịch nhắc',
        ),
        const Glass(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.link_rounded, color: Color(0xFF249D76)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã liên kết tài khoản PA\nNguyễn Thị Lan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.check_circle_rounded, color: Color(0xFF249D76)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PrescriptionCard(
          'Liệu trình huyết áp & tiểu đường',
          '16/09 - 16/10/2026',
          '3 thuốc · 3 khung giờ',
        ),
        const SizedBox(height: 12),
        if (added)
          const PrescriptionCard(
            'Vitamin tổng hợp',
            '16/09 - 16/11/2026',
            '1 thuốc · 08:00',
          ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => showAddMedicineModal(
            context,
            onAdded: onAdded,
            isPatient: false,
          ),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Thêm đơn thuốc & giờ nhắc'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    ),
  );
}

class CaregiverProfilePage extends StatefulWidget {
  const CaregiverProfilePage({
    super.key,
    required this.linkedPatients,
    required this.activePatientIndex,
    required this.onAddPatient,
    required this.onRemovePatient,
    required this.onSelectPatient,
  });

  final List<PatientProfileItem> linkedPatients;
  final int activePatientIndex;
  final void Function(String code, {String? name, String? relation}) onAddPatient;
  final ValueChanged<int> onRemovePatient;
  final ValueChanged<int> onSelectPatient;

  @override
  State<CaregiverProfilePage> createState() => _CaregiverProfilePageState();
}

class _CaregiverProfilePageState extends State<CaregiverProfilePage> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _relationController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _nameController = TextEditingController();
    _relationController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Hồ sơ người chăm sóc',
          'Quản lý thông tin & liên kết bệnh nhân',
        ),
        const Glass(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFDCE2FE),
                child: Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Color(0xFF5066F3),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trần Minh Anh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Người chăm sóc chính (Con gái)',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '090 123 4567 · minhanh@gmail.com',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusChip('Hoạt động', Color(0xFF249D76)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Liên kết thêm bệnh nhân mới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Color(0xFF5267F4),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Nhập mã liên kết người thân',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập mã trên màn hình của bệnh nhân (VD: PA-8899, PA-5521...) để liên kết nhiều người thân vào tài khoản chăm sóc.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEFFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'Mã bệnh nhân (VD: PA-7788)',
                    prefixIcon: Icon(
                      Icons.qr_code_rounded,
                      color: Color(0xFF5065F2),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Họ tên (VD: Bà ngoại Mai)',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: Color(0xFF5065F2),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _relationController,
                        decoration: const InputDecoration(
                          hintText: 'Mối quan hệ (VD: Bà ngoại)',
                          prefixIcon: Icon(
                            Icons.family_restroom_rounded,
                            color: Color(0xFF5065F2),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  final code = _codeController.text.trim();
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập mã bệnh nhân!'),
                      ),
                    );
                    return;
                  }
                  final exists = widget.linkedPatients.any(
                        (p) => p.code.toUpperCase() == code.toUpperCase(),
                  );
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bệnh nhân có mã $code đã có trong danh sách!',
                        ),
                      ),
                    );
                    return;
                  }
                  final name = _nameController.text.trim();
                  final rel = _relationController.text.trim();
                  widget.onAddPatient(
                    code,
                    name: name.isNotEmpty ? name : null,
                    relation: rel.isNotEmpty ? rel : null,
                  );
                  _codeController.clear();
                  _nameController.clear();
                  _relationController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã liên kết thêm bệnh nhân mới: ${name.isNotEmpty ? name : code}!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Liên kết thêm bệnh nhân'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách bệnh nhân (${widget.linkedPatients.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Đang theo dõi: ${widget.linkedPatients.isNotEmpty ? widget.linkedPatients[widget.activePatientIndex].name : "Không"}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5065F2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(widget.linkedPatients.length, (idx) {
          final patient = widget.linkedPatients[idx];
          final isActive = idx == widget.activePatientIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Glass(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: patient.avatarBg,
                        child: Icon(
                          patient.avatarIcon,
                          size: 32,
                          color: const Color(0xFFAD6047),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9EDFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    patient.relation,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF485EE8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${patient.age} tuổi · Mã: ${patient.code}',
                              style: const TextStyle(
                                color: Color(0xFF5267F4),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Tình trạng: ${patient.condition}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        const StatusChip('Đang theo dõi', Color(0xFF249D76))
                      else
                        OutlinedButton(
                          onPressed: () => widget.onSelectPatient(idx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Theo dõi',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  if (widget.linkedPatients.length > 1) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final pName = patient.name;
                            widget.onRemovePatient(idx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã hủy liên kết với $pName.'),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.link_off_rounded,
                            size: 16,
                            color: Color(0xFFD65E4A),
                          ),
                          label: const Text(
                            'Hủy liên kết',
                            style: TextStyle(
                              color: Color(0xFFD65E4A),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
        const Text(
          'Cài đặt nhắc nhở & cảnh báo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Glass(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.notification_important_rounded,
                color: Color(0xFFD65E4A),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảnh báo khẩn cấp (Unhappy case)',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Báo động đỏ khi bệnh nhân chưa uống thuốc sau 15 phút',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              StatusChip('15 phút', Color(0xFFD65E4A)),
            ],
          ),
        ),
      ],
    ),
  );
}

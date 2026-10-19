import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/care_network_controller.dart';
import '../../models/care_network.dart';
import '../../models/prescription.dart';
import '../../models/schedule_rule.dart';
import '../../services/medication_logs_api.dart';
import '../../services/pdf_download_service.dart';
import '../../services/prescription_service.dart';
import '../patient/schedule_timeline_page.dart';
import 'prescriptions/create_prescription_screen.dart';
import 'prescriptions/prescription_detail_screen.dart';
import '../../widgets/widgets.dart';

class CaregiverHome extends StatelessWidget {
  const CaregiverHome({
    super.key,
    required this.tab,
    required this.controller,
    required this.userName,
    required this.userEmail,
    this.onTabChange,
  });

  final int tab;
  final CareNetworkController controller;
  final String userName;
  final String userEmail;
  final ValueChanged<int>? onTabChange;

  void _openAllSchedules(BuildContext context, String patientId) {
    if (onTabChange != null) {
      onTabChange!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Lịch uống thuốc')),
            body: ScheduleTimelinePage(
              key: ValueKey(patientId),
              patientId: patientId,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.linksLoading && controller.linkedPatients.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.linksError != null && controller.linkedPatients.isEmpty) {
        return _CenteredMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được kết nối',
          message: controller.linksError!,
          actionLabel: 'Thử lại',
          onAction: () => controller.loadLinkedAccounts(force: true),
        );
      }
      if (controller.linkedPatients.isEmpty) {
        if (tab == 4) {
          return _ConnectPatientPage(
            controller: controller,
            userName: userName,
            userEmail: userEmail,
          );
        }
        return const _CenteredMessage(
          icon: Icons.people_outline_rounded,
          title: 'Chưa có bệnh nhân',
          message: 'Nhập mã mời của bệnh nhân tại Hồ sơ để bắt đầu kết nối.',
        );
      }

      final patientId = controller.selectedPatientId!;
      final bundle = controller.bundleFor(patientId);
      final error = controller.bundleErrorFor(patientId);
      if (bundle == null && controller.isPatientLoading(patientId)) {
        return _PatientFrame(
          controller: controller,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (bundle == null && error != null) {
        return _PatientFrame(
          controller: controller,
          child: _CenteredMessage(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được hồ sơ',
            message: error,
            actionLabel: 'Thử lại',
            onAction: () => controller.loadPatient(patientId, force: true),
          ),
        );
      }
      if (bundle == null) return const SizedBox.shrink();

      return switch (tab) {
        1 => _PatientFrame(
          controller: controller,
          child: ScheduleTimelinePage(
            key: ValueKey(patientId),
            patientId: patientId,
          ),
        ),
        2 => _PrescriptionPage(controller: controller, bundle: bundle),
        4 => _ProfilePage(
          controller: controller,
          bundle: bundle,
          userName: userName,
          userEmail: userEmail,
        ),
        _ => _OverviewPage(
          controller: controller,
          bundle: bundle,
          onViewAllSchedules: () => _openAllSchedules(context, patientId),
        ),
      };
    },
  );
}

class _ConnectPatientPage extends StatefulWidget {
  const _ConnectPatientPage({
    required this.controller,
    required this.userName,
    required this.userEmail,
  });

  final CareNetworkController controller;
  final String userName;
  final String userEmail;

  @override
  State<_ConnectPatientPage> createState() => _ConnectPatientPageState();
}

class _ConnectPatientPageState extends State<_ConnectPatientPage> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Kết nối bệnh nhân đầu tiên',
          'Nhập mã mời được bệnh nhân chia sẻ để bắt đầu chăm sóc',
        ),
        CaregiverProfileCard(
          userName: widget.userName,
          userEmail: widget.userEmail,
        ),
        const SizedBox(height: 14),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập mã kết nối',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Mã mời (UUID)',
                  prefixIcon: Icon(Icons.key_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFC64E57))),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Xác nhận kết nối'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const CaregiverVipSection(),
      ],
    ),
  );

  Future<void> _submit() async {
    final uuid = _controller.text.trim();
    if (uuid.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.controller.verifyInvitation(uuid);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PatientFrame extends StatelessWidget {
  const _PatientFrame({required this.controller, required this.child});
  final CareNetworkController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: _PatientSelector(controller: controller),
      ),
      Expanded(child: child),
    ],
  );
}

class _PatientSelector extends StatelessWidget {
  const _PatientSelector({required this.controller});
  final CareNetworkController controller;

  @override
  Widget build(BuildContext context) => Glass(
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFFFE5D0),
          child: Icon(Icons.person_rounded, color: Color(0xFFAD6047)),
        ),
        const SizedBox(width: 10),
        const Text(
          'Đang chăm sóc',
          style: TextStyle(color: Color(0xFF687195), fontSize: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedPatientId,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              items: controller.linkedPatients
                  .map(
                    (patient) => DropdownMenuItem(
                      value: patient.id,
                      child: Text(
                        patient.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.selectPatient(value);
              },
            ),
          ),
        ),
        IconButton(
          tooltip: 'Làm mới dữ liệu bệnh nhân',
          onPressed: controller.isPatientLoading(controller.selectedPatientId)
              ? null
              : controller.refreshSelectedPatient,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
  );
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.controller,
    required this.bundle,
    this.onViewAllSchedules,
  });
  final CareNetworkController controller;
  final PatientBundle bundle;
  final VoidCallback? onViewAllSchedules;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final todaySchedules = bundle.schedules
        .where((item) => item.isActive && item.daysOfWeek.contains(today))
        .toList();
    final overviewSchedules = selectOverviewSchedules(todaySchedules);
    return _PatientFrame(
      controller: controller,
      child: AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageIntro(
              'Chào ${bundle.detail.fullName}',
              'Tổng hợp dữ liệu chăm sóc mới nhất',
            ),
            Glass(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFFFD9C6),
                    child: Icon(Icons.face_3_rounded, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bundle.detail.fullName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          [
                            bundle.detail.phone,
                            bundle.detail.email,
                          ].where((value) => value.isNotEmpty).join(' · '),
                          style: const TextStyle(color: Color(0xFF687195)),
                        ),
                      ],
                    ),
                  ),
                  const StatusChip('Đã kết nối', Color(0xFF249D76)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Metric(
                  value: '${todaySchedules.length}',
                  label: 'Cữ hôm nay',
                  icon: Icons.alarm_rounded,
                  color: const Color(0xFF5267F4),
                ),
                const SizedBox(width: 10),
                _Metric(
                  value: '${bundle.activePrescriptionCount}',
                  label: 'Đơn đang dùng',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF24A87D),
                ),
                const SizedBox(width: 10),
                _Metric(
                  value: '${bundle.lowStockCount}',
                  label: 'Thuốc sắp hết',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFFE18A37),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ComplianceReportCard(
              patientId: bundle.detail.id,
              patientName: bundle.detail.fullName,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Lịch uống hôm nay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (todaySchedules.isNotEmpty && onViewAllSchedules != null)
                  TextButton.icon(
                    onPressed: onViewAllSchedules,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Xem tất cả'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5267F4),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (overviewSchedules.isEmpty)
              const _EmptyCard(message: 'Hôm nay không có cữ thuốc nào.')
            else
              ...overviewSchedules.map(_ScheduleTile.new),
            if (bundle.lowStockCount > 0) ...[
              const SizedBox(height: 14),
              const Glass(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFE18A37)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Có thuốc đã chạm ngưỡng đặt lại. Kiểm tra tab Đơn thuốc.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrescriptionPage extends StatefulWidget {
  const _PrescriptionPage({required this.controller, required this.bundle});
  final CareNetworkController controller;
  final PatientBundle bundle;

  @override
  State<_PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<_PrescriptionPage> {
  bool _scanning = false;

  Future<void> _scanPrescription() async {
    if (!await requirePremiumAccess(context) || !mounted) return;

    final patientId = widget.controller.mongoPatientId(
      widget.controller.selectedPatientId,
    );
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể quét: chưa nhận được mã bệnh nhân MongoDB hợp lệ.',
          ),
          backgroundColor: Color(0xFFD65B49),
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Chụp ảnh đơn thuốc'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    List<int>? imageBytes;
    String? filename;
    if (source == ImageSource.gallery) {
      final result = await FilePicker.pickFiles(type: FileType.image);
      final file = result.isNotEmpty ? result.first : null;
      imageBytes = file == null ? null : await file.readAsBytes();
      filename = file?.name;
    } else {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
      );
      if (image != null) {
        imageBytes = await image.readAsBytes();
        filename = image.name;
      }
    }
    if (imageBytes == null ||
        imageBytes.isEmpty ||
        filename == null ||
        !mounted) {
      return;
    }

    setState(() => _scanning = true);
    try {
      debugPrint('Scanning prescription for patientId=$patientId');
      final prescription = await PrescriptionService.instance.scan(
        imageBytes: imageBytes,
        filename: filename,
        patientId: patientId,
      );
      if (!mounted || prescription.id == null) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PrescriptionDetailScreen(prescriptionId: prescription.id!),
        ),
      );
      widget.controller.loadPatient(patientId, force: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quét đơn thuốc thất bại: $e'),
          backgroundColor: const Color(0xFFD65B49),
        ),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PatientFrame(
    controller: widget.controller,
    child: AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PageIntro(
                  'Đơn thuốc',
                  'Đơn và thuốc của ${widget.bundle.detail.fullName}',
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.document_scanner_rounded, size: 18),
                label: Text(_scanning ? 'Đang quét...' : 'Quét đơn'),
                onPressed: _scanning ? null : _scanPrescription,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tạo đơn'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5267F4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePrescriptionScreen(
                        patientId: widget.bundle.detail.id,
                        patientName: widget.bundle.detail.fullName,
                      ),
                    ),
                  );
                  if (created == true) {
                    widget.controller.loadPatient(
                      widget.bundle.detail.id,
                      force: true,
                    );
                  }
                },
              ),
            ],
          ),
          if (widget.bundle.prescriptions.isEmpty)
            const _EmptyCard(message: 'Bệnh nhân chưa có đơn thuốc.')
          else
            ...widget.bundle.prescriptions.map(
              (prescription) => _PrescriptionCard(
                prescription: prescription,
                onRefresh: () => widget.controller.loadPatient(
                  widget.bundle.detail.id,
                  force: true,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({
    required this.controller,
    required this.bundle,
    required this.userName,
    required this.userEmail,
  });
  final CareNetworkController controller;
  final PatientBundle bundle;
  final String userName;
  final String userEmail;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _invitationController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _invitationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PatientFrame(
    controller: widget.controller,
    child: AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro(
            'Hồ sơ người chăm sóc',
            'Tài khoản và các kết nối bệnh nhân',
          ),
          CaregiverProfileCard(
            userName: widget.userName,
            userEmail: widget.userEmail,
          ),
          const SizedBox(height: 14),
          const CaregiverVipSection(),
          const SizedBox(height: 10),
          const Text(
            'Kết nối thêm bệnh nhân',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  controller: _invitationController,
                  decoration: const InputDecoration(
                    labelText: 'Mã mời (UUID)',
                    prefixIcon: Icon(Icons.key_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFC64E57)),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submitInvitation,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Xác nhận kết nối'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Đang chăm sóc ${widget.controller.linkedPatients.length} bệnh nhân',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...widget.controller.linkedPatients.map(
            (patient) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Glass(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text(patient.fullName),
                  trailing: patient.id == widget.controller.selectedPatientId
                      ? const Icon(Icons.check_circle, color: Color(0xFF249D76))
                      : null,
                  onTap: () => widget.controller.selectPatient(patient.id),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submitInvitation() async {
    final uuid = _invitationController.text.trim();
    if (uuid.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.controller.verifyInvitation(uuid);
      _invitationController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kết nối bệnh nhân thành công.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: const Color(0xFF5267F4)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF687195)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile(this.rule);
  final ScheduleRule rule;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showScheduleDetailsModal(
        context,
        scheduleId: rule.id,
        initialRule: rule,
        selectedDate: DateTime.now(),
      ),
      child: Glass(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7E9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                rule.displayTime,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4659CF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.medicine.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${rule.dosagePerTime.toStringAsFixed(rule.dosagePerTime % 1 == 0 ? 0 : 1)} ${rule.medicine.unit} · ${rule.prescription.title}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF687195),
                    ),
                  ),
                  if (rule.instructions?.isNotEmpty == true)
                    Text(
                      rule.instructions!,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            StatusChip(
              rule.isActive ? 'Đang bật' : 'Đã tắt',
              rule.isActive ? const Color(0xFF249D76) : const Color(0xFF9BA3BF),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription, this.onRefresh});
  final Prescription prescription;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Glass(
      padding: const EdgeInsets.all(17),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7E9FF),
          child: Icon(Icons.receipt_long_rounded, color: Color(0xFF5267F4)),
        ),
        title: Text(
          prescription.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${prescription.startDate} → ${prescription.endDate ?? 'Không giới hạn'}',
        ),
        trailing: StatusChip(
          prescription.isActive ? 'Đang dùng' : 'Đã ngừng',
          prescription.isActive
              ? const Color(0xFF249D76)
              : const Color(0xFF9BA3BF),
        ),
        children: [
          if (prescription.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Đơn chưa có thuốc.'),
            )
          else
            ...prescription.items.map(_MedicineLine.new),
          if (prescription.id != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Xem chi tiết / Thêm thuốc'),
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrescriptionDetailScreen(
                        prescriptionId: prescription.id!,
                      ),
                    ),
                  );
                  onRefresh?.call();
                },
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MedicineLine extends StatelessWidget {
  const _MedicineLine(this.item);
  final PrescriptionItem item;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: item.isLowStock
          ? const Color(0xFFFFF3E6)
          : const Color(0xFFF5F6FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(
          item.isLowStock
              ? Icons.warning_amber_rounded
              : Icons.medication_rounded,
          color: item.isLowStock
              ? const Color(0xFFE18A37)
              : const Color(0xFF5267F4),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicineName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                '${item.dosagePerTime} ${item.unit}/lần · Còn ${item.currentStock} · Ngưỡng ${item.reorderThreshold}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF687195)),
              ),
              if (item.instructions?.isNotEmpty == true)
                Text(item.instructions!, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(22),
    child: Center(
      child: Text(message, style: const TextStyle(color: Color(0xFF687195))),
    ),
  );
}

/// Chọn tối đa [limit] cữ hiển thị trên Tổng quan:
/// - Sắp xếp tăng dần theo reminderTime.
/// - Lấy mốc thời gian tham chiếu là now - [gracePeriod] (mặc định 15 phút).
/// - Ưu tiên lấy [limit] cữ có reminderTime >= (now - gracePeriod).
/// - Fallback cuối ngày: nếu số cữ sắp tới ít hơn [limit], lấy bù các cữ gần nhất
///   trước đó để luôn hiển thị đủ tối đa [limit] cữ (hoặc toàn bộ nếu tổng số cữ < limit).
List<ScheduleRule> selectOverviewSchedules(
  List<ScheduleRule> rules, {
  DateTime? now,
  int limit = 4,
  Duration gracePeriod = const Duration(minutes: 15),
}) {
  if (rules.isEmpty) return const [];
  final sorted = List<ScheduleRule>.from(rules)
    ..sort((a, b) {
      final ma = _parseReminderMinutes(a.reminderTime);
      final mb = _parseReminderMinutes(b.reminderTime);
      final cmp = ma.compareTo(mb);
      return cmp != 0 ? cmp : a.id.compareTo(b.id);
    });

  if (sorted.length <= limit) return sorted;

  final currentTime = now ?? DateTime.now();
  final threshold = currentTime.subtract(gracePeriod);
  final thresholdMinutes = threshold.day == currentTime.day
      ? threshold.hour * 60 + threshold.minute
      : 0;

  final firstUpcoming = sorted.indexWhere(
    (r) => _parseReminderMinutes(r.reminderTime) >= thresholdMinutes,
  );

  var startIndex = firstUpcoming == -1
      ? (sorted.length - limit)
      : firstUpcoming;
  if (startIndex + limit > sorted.length) {
    startIndex = sorted.length - limit;
  }
  if (startIndex < 0) startIndex = 0;

  return sorted.sublist(startIndex, startIndex + limit);
}

int _parseReminderMinutes(String reminderTime) {
  final parts = reminderTime.split(':');
  if (parts.length < 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

class _ComplianceReportCard extends StatefulWidget {
  const _ComplianceReportCard({
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<_ComplianceReportCard> createState() => _ComplianceReportCardState();
}

class _ComplianceReportCardState extends State<_ComplianceReportCard> {
  bool _downloading = false;
  final _api = MedicationLogsApi();

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _downloadReport() async {
    if (!await requirePremiumAccess(context) || !mounted) return;

    setState(() => _downloading = true);
    try {
      final result = await _api.downloadComplianceReport(
        patientId: widget.patientId,
      );
      downloadPdfFile(result.bytes, result.filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải báo cáo tuân thủ: ${result.filename}'),
            backgroundColor: const Color(0xFF249D76),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('403') ||
                      e.toString().toLowerCase().contains('premium')
                  ? 'Tính năng xuất báo cáo PDF chỉ dành cho tài khoản VIP.'
                  : 'Tải báo cáo thất bại: $e',
            ),
            backgroundColor: const Color(0xFFD65B49),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: .14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFEA580C),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Báo cáo tuân thủ 30 ngày',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF9A3412),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Tỷ lệ đúng giờ, liều quên của ${widget.patientName}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _downloading ? null : _downloadReport,
            icon: _downloading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 16),
            label: Text(
              _downloading ? 'Đang xuất...' : 'Tải PDF',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              elevation: 2,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

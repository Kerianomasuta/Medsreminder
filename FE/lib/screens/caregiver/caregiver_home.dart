import 'package:flutter/material.dart';

import '../../controllers/care_network_controller.dart';
import '../../models/care_network.dart';
import '../../models/prescription.dart';
import '../../models/schedule_rule.dart';
import '../patient/schedule_timeline_page.dart';
import '../../widgets/widgets.dart';

class CaregiverHome extends StatelessWidget {
  const CaregiverHome({
    super.key,
    required this.tab,
    required this.controller,
    required this.userName,
    required this.userEmail,
  });

  final int tab;
  final CareNetworkController controller;
  final String userName;
  final String userEmail;

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
        _ => _OverviewPage(controller: controller, bundle: bundle),
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
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                widget.userEmail,
                style: const TextStyle(color: Color(0xFF687195)),
              ),
              const SizedBox(height: 18),
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
  const _OverviewPage({required this.controller, required this.bundle});
  final CareNetworkController controller;
  final PatientBundle bundle;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final todaySchedules = bundle.schedules
        .where((item) => item.isActive && item.daysOfWeek.contains(today))
        .toList();
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
            const SizedBox(height: 20),
            const Text(
              'Lịch uống hôm nay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (todaySchedules.isEmpty)
              const _EmptyCard(message: 'Hôm nay không có cữ thuốc nào.')
            else
              ...todaySchedules.take(4).map(_ScheduleTile.new),
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

class _PrescriptionPage extends StatelessWidget {
  const _PrescriptionPage({required this.controller, required this.bundle});
  final CareNetworkController controller;
  final PatientBundle bundle;

  @override
  Widget build(BuildContext context) => _PatientFrame(
    controller: controller,
    child: AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageIntro('Đơn thuốc', 'Đơn và thuốc của ${bundle.detail.fullName}'),
          if (bundle.prescriptions.isEmpty)
            const _EmptyCard(message: 'Bệnh nhân chưa có đơn thuốc.')
          else
            ...bundle.prescriptions.map(
              (prescription) => _PrescriptionCard(prescription: prescription),
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
          Glass(
            padding: const EdgeInsets.all(18),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFDCE2FE),
                child: Icon(Icons.person_rounded, color: Color(0xFF5066F3)),
              ),
              title: Text(
                widget.userName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(widget.userEmail),
              trailing: const StatusChip('Hoạt động', Color(0xFF249D76)),
            ),
          ),
          const SizedBox(height: 18),
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
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF687195)),
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
  const _PrescriptionCard({required this.prescription});
  final Prescription prescription;

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
        children: prescription.items.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Đơn chưa có thuốc.'),
                ),
              ]
            : prescription.items.map(_MedicineLine.new).toList(),
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

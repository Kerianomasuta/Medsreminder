import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';

import 'patient/patient_home.dart';
import 'caregiver/caregiver_home.dart';
import 'caregiver/caregiver_pharmacy_screen.dart';
import 'caregiver/caregiver_tracking_screen.dart';
import 'pharmacist/pharmacist_home.dart';
import 'pharmacist/pharmacist_verification_screen.dart';
import 'shipper/shipper_home.dart';
import 'shipper/shipper_task_screen.dart';
import 'admin/admin_home.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    required this.userName,
    required this.userEmail,
    this.userId = '',
    required this.onLogout,
    required this.doseTaken,
    required this.doseMissed,
    required this.prescriptionAdded,
    required this.orderStage,
    required this.linkedPatients,
    required this.activePatientIndex,
    required this.onRoleChanged,
    required this.onTaken,
    required this.onMissed,
    required this.onPrescriptionAdded,
    required this.onOrderStageChanged,
    required this.onAddPatient,
    required this.onRemovePatient,
    required this.onSelectPatient,
  });

  final AppRole role;
  final String userName;
  final String userEmail;
  final String userId;
  final Future<void> Function() onLogout;
  final bool doseTaken, doseMissed, prescriptionAdded;
  final List<PatientProfileItem> linkedPatients;
  final int activePatientIndex;
  final OrderStage orderStage;
  final ValueChanged<AppRole> onRoleChanged;
  final VoidCallback onTaken, onMissed, onPrescriptionAdded;
  final ValueChanged<OrderStage> onOrderStageChanged;
  final void Function(String code, {String? name, String? relation})
  onAddPatient;
  final ValueChanged<int> onRemovePatient;
  final ValueChanged<int> onSelectPatient;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int tab = 0;
  late final AnimationController _ambience;

  @override
  void initState() {
    super.initState();
    _ambience = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambience.dispose();
    super.dispose();
  }

  List<NavItem> get nav => switch (widget.role) {
    AppRole.patient => const [
      NavItem(Icons.home_rounded, 'Hôm nay'),
      NavItem(Icons.medication_rounded, 'Uống thuốc'),
      NavItem(Icons.calendar_month_rounded, 'Lịch uống'),
      NavItem(Icons.person_rounded, 'Hồ sơ'),
    ],
    AppRole.caregiver => const [
      NavItem(Icons.grid_view_rounded, 'Tổng quan'),
      NavItem(Icons.receipt_long_rounded, 'Đơn thuốc'),
      NavItem(Icons.storefront_rounded, 'Nhà thuốc'),
      NavItem(Icons.near_me_rounded, 'Theo dõi'),
      NavItem(Icons.person_rounded, 'Hồ sơ'),
    ],
    AppRole.pharmacist => const [
      NavItem(Icons.dashboard_rounded, 'Xử lý đơn'),
      NavItem(Icons.inventory_2_rounded, 'Kho thuốc'),
      NavItem(Icons.history_rounded, 'Lịch sử'),
    ],
    AppRole.shipper => const [
      NavItem(Icons.route_rounded, 'Chuyến giao'),
      NavItem(Icons.assignment_turned_in_rounded, 'Đã giao'),
      NavItem(Icons.person_rounded, 'Tài khoản'),
    ],
    AppRole.admin => const [
      NavItem(Icons.insights_rounded, 'Hệ thống'),
      NavItem(Icons.people_alt_rounded, 'Người dùng'),
      NavItem(Icons.security_rounded, 'Cảnh báo'),
    ],
  };

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) tab = 0;
  }

  @override
  Widget build(BuildContext context) => AnimatedAuroraBackground(
    animation: _ambience,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              role: widget.role,
              userName: widget.userName,
              onLogout: widget.onLogout,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .96, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: _content(),
              ),
            ),
            GlassBottomNav(
              items: nav,
              currentIndex: tab,
              onTap: (value) => setState(() => tab = value),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content() => switch (widget.role) {
    AppRole.patient => PatientHome(
      key: ValueKey('${widget.role}$tab'),
      tab: tab,
      doseTaken: widget.doseTaken,
      doseMissed: widget.doseMissed,
      prescriptionAdded: widget.prescriptionAdded,
      onPrescriptionAdded: widget.onPrescriptionAdded,
      isLinked: widget.linkedPatients.isNotEmpty,
      linkedPatientCode: widget.linkedPatients.isNotEmpty
          ? widget.linkedPatients[widget.activePatientIndex].code
          : 'PA-8899',
      patientId: widget.userId,
      onTaken: widget.onTaken,
    ),

    AppRole.caregiver =>
      tab == 2
          ? CaregiverPharmacyScreen(
              key: ValueKey('${widget.role}$tab'),
              onSendRefill: () => widget.onRoleChanged(AppRole.pharmacist),
            )
          : tab == 3
          ? CaregiverTrackingScreen(
              key: ValueKey('${widget.role}$tab'),
              onReceiptConfirmed: () => setState(() => tab = 0),
            )
          : CaregiverHome(
              key: ValueKey('${widget.role}$tab${widget.activePatientIndex}'),
              tab: tab,
              userName: widget.userName,
              userEmail: widget.userEmail,
              doseTaken: widget.doseTaken,
              doseMissed: widget.doseMissed,
              prescriptionAdded: widget.prescriptionAdded,
              linkedPatients: widget.linkedPatients,
              activePatientIndex: widget.activePatientIndex,
              onMissed: widget.onMissed,
              onPrescriptionAdded: widget.onPrescriptionAdded,
              onAddPatient: widget.onAddPatient,
              onRemovePatient: widget.onRemovePatient,
              onSelectPatient: widget.onSelectPatient,
            ),

    AppRole.pharmacist =>
      tab == 0
          ? PharmacistVerificationScreen(
              key: ValueKey('${widget.role}$tab'),
              onApproveAndDispatch: () => widget.onRoleChanged(AppRole.shipper),
            )
          : PharmacistHome(
              key: ValueKey('${widget.role}$tab'),
              tab: tab,
              orderStage: widget.orderStage,
              onOrderStageChanged: widget.onOrderStageChanged,
            ),

    AppRole.shipper =>
      tab == 0
          ? ShipperTaskScreen(
              key: ValueKey('${widget.role}$tab'),
              onConfirmPickup: () {
                widget.onRoleChanged(AppRole.caregiver);
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => tab = 3);
                });
              },
            )
          : ShipperHome(
              key: ValueKey('${widget.role}$tab'),
              tab: tab,
              orderStage: widget.orderStage,
              onOrderStageChanged: widget.onOrderStageChanged,
            ),

    AppRole.admin => AdminHome(
      key: ValueKey('${widget.role}$tab'),
      doseMissed: widget.doseMissed,
    ),
  };
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.role,
    required this.userName,
    required this.onLogout,
  });
  final AppRole role;
  final String userName;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(
      children: [
        const BrandMark(),
        const Spacer(),
        GestureDetector(
          onTap: () => _showAccount(context),
          child: Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: const Color(0xFF4D63E9),
                  child: Icon(role.icon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 145),
                  child: Text(
                    userName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  void _showAccount(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(role.label, style: const TextStyle(color: Color(0xFF66738A))),
          const SizedBox(height: 14),
          Material(
            color: const Color(0xFFFFE9EC),
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFC34B55),
              ),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';
import '../controllers/care_network_controller.dart';
import '../controllers/pharmacist_dashboard_controller.dart';

import 'patient/patient_home.dart';
import 'caregiver/caregiver_home.dart';
import 'caregiver/caregiver_pharmacy_screen.dart';
import 'pharmacist/pharmacist_home.dart';
import 'admin/admin_home.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.networkController,
    required this.pharmacistController,
    required this.onRoleChanged,
  });

  final AppRole role;
  final String userName;
  final String userEmail;
  final Future<void> Function() onLogout;
  final CareNetworkController networkController;
  final PharmacistDashboardController? pharmacistController;
  final ValueChanged<AppRole> onRoleChanged;

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
      NavItem(Icons.calendar_month_rounded, 'Lịch uống'),
      NavItem(Icons.person_rounded, 'Hồ sơ'),
    ],
    AppRole.caregiver => const [
      NavItem(Icons.grid_view_rounded, 'Tổng quan'),
      NavItem(Icons.calendar_month_rounded, 'Lịch uống'),
      NavItem(Icons.receipt_long_rounded, 'Đơn thuốc'),
      NavItem(Icons.storefront_rounded, 'Nhà thuốc'),
      NavItem(Icons.person_rounded, 'Hồ sơ'),
    ],
    AppRole.pharmacist => const [
      NavItem(Icons.dashboard_rounded, 'Xử lý đơn'),
      NavItem(Icons.history_rounded, 'Lịch sử'),
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
              userEmail: widget.userEmail,
              pharmacistController: widget.pharmacistController,
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
      networkController: widget.networkController,
    ),

    AppRole.caregiver =>
      tab == 3
          ? CaregiverPharmacyScreen(
              key: ValueKey('${widget.role}$tab'),
              controller: widget.networkController,
            )
          : CaregiverHome(
              key: ValueKey(
                '${widget.role}$tab${widget.networkController.selectedPatientId}',
              ),
              tab: tab,
              userName: widget.userName,
              userEmail: widget.userEmail,
              controller: widget.networkController,
            ),

    AppRole.pharmacist => PharmacistHome(
      key: ValueKey('${widget.role}$tab'),
      tab: tab,
      controller: widget.pharmacistController!,
    ),

    AppRole.admin => AdminHome(key: ValueKey('${widget.role}$tab')),
  };
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.role,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    this.pharmacistController,
  });
  final AppRole role;
  final String userName;
  final String userEmail;
  final Future<void> Function() onLogout;
  final PharmacistDashboardController? pharmacistController;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(
      children: [
        const BrandMark(),
        const Spacer(),
        GestureDetector(
          key: const Key('account-information-button'),
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

  void _showAccount(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AccountInformationSheet(
      role: role,
      userName: userName,
      userEmail: userEmail,
      pharmacistController: pharmacistController,
      onLogout: onLogout,
    ),
  );
}

class _AccountInformationSheet extends StatefulWidget {
  const _AccountInformationSheet({
    required this.role,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    this.pharmacistController,
  });

  final AppRole role;
  final String userName;
  final String userEmail;
  final Future<void> Function() onLogout;
  final PharmacistDashboardController? pharmacistController;

  @override
  State<_AccountInformationSheet> createState() =>
      _AccountInformationSheetState();
}

class _AccountInformationSheetState extends State<_AccountInformationSheet> {
  @override
  void initState() {
    super.initState();
    if (widget.role == AppRole.pharmacist) {
      widget.pharmacistController?.loadPharmacy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.pharmacistController;
    return Material(
      color: const Color(0xFFF6F7FF),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thông tin',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
                ),
                const SizedBox(height: 16),
                _InformationCard(
                  key: const Key('pharmacist-account-information'),
                  title: 'Thông tin dược sĩ',
                  icon: Icons.badge_outlined,
                  rows: [
                    _InformationValue('Họ và tên', widget.userName),
                    _InformationValue('Email', widget.userEmail),
                    _InformationValue('Vai trò', widget.role.label),
                  ],
                ),
                if (widget.role == AppRole.pharmacist &&
                    controller != null) ...[
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => _buildPharmacy(controller),
                  ),
                ],
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
                      widget.onLogout();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacy(PharmacistDashboardController controller) {
    final pharmacy = controller.pharmacy;
    if (controller.pharmacyLoading && pharmacy == null) {
      return const Padding(
        padding: EdgeInsets.all(22),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (pharmacy == null) {
      return Material(
        key: const Key('pharmacist-pharmacy-error'),
        color: const Color(0xFFFFF0F1),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                controller.pharmacyError ?? 'Không tìm thấy hồ sơ nhà thuốc.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC34B55)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => controller.loadPharmacy(force: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    return _InformationCard(
      key: const Key('pharmacist-pharmacy-information'),
      title: 'Thông tin nhà thuốc',
      icon: Icons.local_pharmacy_outlined,
      rows: [
        _InformationValue('Tên nhà thuốc', pharmacy.name),
        _InformationValue('Số điện thoại', pharmacy.phoneNumber),
        _InformationValue('Địa chỉ', pharmacy.addressText),
        _InformationValue(
          'Tọa độ',
          '${pharmacy.latitude.toStringAsFixed(6)}, '
              '${pharmacy.longitude.toStringAsFixed(6)}',
        ),
        _InformationValue('Geohash', pharmacy.geohash),
      ],
    );
  }
}

class _InformationValue {
  const _InformationValue(this.label, this.value);

  final String label;
  final String value;
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    super.key,
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InformationValue> rows;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .82),
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5267F4)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < rows.length; index++) ...[
            _InformationRow(value: rows[index]),
            if (index < rows.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.value});

  final _InformationValue value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 105,
        child: Text(
          value.label,
          style: const TextStyle(
            color: Color(0xFF687195),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          value.value,
          key: Key('information-${value.label}'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

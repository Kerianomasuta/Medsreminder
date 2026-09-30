import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- IMPORT CÁC MÀN HÌNH TỪ GOOGLE AI STUDIO (STITCH) ---
import 'screens/caregiver_pharmacy_screen.dart';
import 'screens/pharmacist_verification_screen.dart';
import 'screens/shipper_task_screen.dart';
import 'screens/caregiver_tracking_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Đặt thanh trạng thái iOS / Android trong suốt như yêu cầu
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MedsReminderApp());
}

class PatientProfileItem {
  final String code;
  final String name;
  final int age;
  final String relation;
  final String condition;
  final Color avatarBg;
  final IconData avatarIcon;

  const PatientProfileItem({
    required this.code,
    required this.name,
    required this.age,
    required this.relation,
    required this.condition,
    this.avatarBg = const Color(0xFFFFD9C6),
    this.avatarIcon = Icons.face_3_rounded,
  });
}

class MedsReminderApp extends StatefulWidget {
  const MedsReminderApp({super.key});

  @override
  State<MedsReminderApp> createState() => _MedsReminderAppState();
}

class _MedsReminderAppState extends State<MedsReminderApp> {
  AppRole role = AppRole.caregiver;
  bool showWelcome = true;
  bool doseTaken = false;
  bool doseMissed = false;
  bool prescriptionAdded = false;
  OrderStage orderStage = OrderStage.review;

  List<PatientProfileItem> linkedPatients = [
    const PatientProfileItem(
      code: 'PA-8899',
      name: 'Nguyễn Thị Lan',
      age: 72,
      relation: 'Mẹ ruột',
      condition: 'Huyết áp & Tiểu đường',
      avatarBg: Color(0xFFFFD9C6),
      avatarIcon: Icons.face_3_rounded,
    ),
    const PatientProfileItem(
      code: 'PA-5521',
      name: 'Trần Văn Nam',
      age: 76,
      relation: 'Bố ruột',
      condition: 'Tim mạch',
      avatarBg: Color(0xFFD6E4FF),
      avatarIcon: Icons.face_rounded,
    ),
  ];
  int activePatientIndex = 0;

  void markTaken() => setState(() {
    doseTaken = true;
    doseMissed = false;
  });
  void markMissed() => setState(() {
    doseTaken = false;
    doseMissed = true;
  });
  void addPatient(String code, {String? name, String? relation}) => setState(() {
    linkedPatients.add(
      PatientProfileItem(
        code: code,
        name: (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : 'Bệnh nhân $code',
        age: 70,
        relation: (relation != null && relation.trim().isNotEmpty)
            ? relation.trim()
            : 'Người thân',
        condition: 'Đang theo dõi',
        avatarBg: const Color(0xFFFFE5D0),
        avatarIcon: Icons.person_rounded,
      ),
    );
    activePatientIndex = linkedPatients.length - 1;
  });
  void removePatient(int index) => setState(() {
    if (linkedPatients.length > 1) {
      linkedPatients.removeAt(index);
      if (activePatientIndex >= linkedPatients.length) {
        activePatientIndex = linkedPatients.length - 1;
      }
    }
  });
  void selectPatient(int index) => setState(() {
    activePatientIndex = index;
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MedsReminder',
    theme: ThemeData(
      fontFamily: 'Arial',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A57F7),
        primary: const Color(0xFF5A57F7),
        secondary: const Color(0xFFFF6FAF),
        tertiary: const Color(0xFF24CFA6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF5B5AF7),
          elevation: 8,
          shadowColor: const Color(0xFF665EF7).withOpacity(.36),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFF63A9),
      ),
    ),
    home: AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: showWelcome
          ? WelcomeScreen(
        key: const ValueKey('welcome'),
        onFinished: () => setState(() => showWelcome = false),
      )
          : AppShell(
        key: const ValueKey('app-shell'),
        role: role,
        doseTaken: doseTaken,
        doseMissed: doseMissed,
        prescriptionAdded: prescriptionAdded,
        orderStage: orderStage,
        linkedPatients: linkedPatients,
        activePatientIndex: activePatientIndex,
        onRoleChanged: (value) => setState(() => role = value),
        onTaken: markTaken,
        onMissed: markMissed,
        onPrescriptionAdded: () =>
            setState(() => prescriptionAdded = true),
        onOrderStageChanged: (value) =>
            setState(() => orderStage = value),
        onAddPatient: addPatient,
        onRemovePatient: removePatient,
        onSelectPatient: selectPatient,
      ),
    ),
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _wave;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  void _finish() {
    if (!mounted || _hasFinished) return;
    _hasFinished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ReferenceLanding(entrance: _entrance, wave: _wave, onStart: _finish);
}

class _ReferenceLanding extends StatelessWidget {
  const _ReferenceLanding({
    required this.entrance,
    required this.wave,
    required this.onStart,
  });

  final Animation<double> entrance;
  final Animation<double> wave;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EAEF6), Color(0xFFB8D5FF), Color(0xFFF1F7FF)],
          stops: [0, .56, 1],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 132,
              right: -76,
              child: _WelcomeOrb(color: Color(0x33FFFFFF), size: 220),
            ),
            const Positioned(
              top: 345,
              left: -80,
              child: _WelcomeOrb(color: Color(0x3388B8FA), size: 190),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: entrance,
                      curve: const Interval(0, .35, curve: Curves.easeOut),
                    ),
                    child: const _LandingNav(),
                  ),
                  const SizedBox(height: 18),
                  _LandingHero(entrance: entrance, wave: wave),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: entrance,
                      curve: const Interval(.4, 1, curve: Curves.easeOut),
                    ),
                    child: const Text(
                      'MedsReminder là dự án hỗ trợ bạn chủ động hơn trong việc dùng thuốc và kết nối với người thân khi cần.',
                      style: TextStyle(
                        color: Color(0xFF18345F),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: entrance,
                      curve: const Interval(.55, 1, curve: Curves.easeOut),
                    ),
                    child: const _LandingHighlights(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: entrance,
                  curve: const Interval(.55, 1, curve: Curves.easeOut),
                ),
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF082452),
                    minimumSize: const Size.fromHeight(55),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Khám phá MedsReminder'),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LandingNav extends StatelessWidget {
  const _LandingNav();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 6),
      const Text(
        'MedsReminder',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      const Spacer(),
      const Text(
        'Giới thiệu',
        style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 11),
      ),
      const SizedBox(width: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: const BoxDecoration(
          color: Color(0xFF082452),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: const Text(
          'Bắt đầu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _LandingHero extends StatelessWidget {
  const _LandingHero({required this.entrance, required this.wave});

  final Animation<double> entrance;
  final Animation<double> wave;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 455,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 366,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: entrance,
              curve: const Interval(.2, .8, curve: Curves.easeOut),
            ),
            child: const Text(
              'An tâm mỗi ngày\nvới một lời nhắc nhỏ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF082452),
                fontSize: 29,
                height: .98,
                letterSpacing: -.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position:
            Tween<Offset>(
              begin: const Offset(.08, .1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: entrance, curve: Curves.easeOutBack),
            ),
            child: RotationTransition(
              turns: Tween<double>(
                begin: -.012,
                end: .012,
              ).animate(CurvedAnimation(parent: wave, curve: Curves.easeInOut)),
              child: Center(
                child: Image.asset(
                  'assets/images/welcome_doctor_3d.png',
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 260,
          child: Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.78),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163F7D).withOpacity(.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7',
                  style: TextStyle(
                    color: Color(0xFF082452),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Đồng hành\ncùng sức khoẻ',
                  style: TextStyle(
                    color: Color(0xFF466182),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(left: 8, top: 275, child: _HeroStamp()),
      ],
    ),
  );
}

class _HeroStamp extends StatelessWidget {
  const _HeroStamp();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.22,
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5277A9), width: 1.2),
      ),
      child: const Icon(
        Icons.medication_rounded,
        color: Color(0xFF294D83),
        size: 23,
      ),
    ),
  );
}

class _LandingHighlights extends StatelessWidget {
  const _LandingHighlights();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.68),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(.54)),
    ),
    child: const Row(
      children: [
        Expanded(
          child: _LandingHighlight(
            icon: Icons.alarm_rounded,
            label: 'Nhắc thuốc',
          ),
        ),
        _HighlightDivider(),
        Expanded(
          child: _LandingHighlight(
            icon: Icons.favorite_rounded,
            label: 'Người thân',
          ),
        ),
        _HighlightDivider(),
        Expanded(
          child: _LandingHighlight(
            icon: Icons.local_pharmacy_rounded,
            label: 'Đơn thuốc',
          ),
        ),
      ],
    ),
  );
}

class _LandingHighlight extends StatelessWidget {
  const _LandingHighlight({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFF133B70), size: 22),
      const SizedBox(height: 6),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF234C80),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _HighlightDivider extends StatelessWidget {
  const _HighlightDivider();

  @override
  Widget build(BuildContext context) =>
       Container(width: 1, height: 38, color: Color(0x3355739F));
}

class _WelcomeOrb extends StatelessWidget {
  const _WelcomeOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

enum AppRole { patient, caregiver, pharmacist, shipper, admin }
enum OrderStage { review, verified, pickedUp, delivering, delivered }

extension RoleData on AppRole {
  String get label => switch (this) {
    AppRole.patient => 'Bệnh nhân',
    AppRole.caregiver => 'Người chăm sóc',
    AppRole.pharmacist => 'Dược sĩ',
    AppRole.shipper => 'Người giao thuốc',
    AppRole.admin => 'Quản trị viên',
  };
  String get code => switch (this) {
    AppRole.patient => 'PA',
    AppRole.caregiver => 'CG',
    AppRole.pharmacist => 'P',
    AppRole.shipper => 'DS',
    AppRole.admin => 'SA',
  };
  IconData get icon => switch (this) {
    AppRole.patient => Icons.favorite_rounded,
    AppRole.caregiver => Icons.volunteer_activism_rounded,
    AppRole.pharmacist => Icons.medication_rounded,
    AppRole.shipper => Icons.local_shipping_rounded,
    AppRole.admin => Icons.admin_panel_settings_rounded,
  };
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
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
  final bool doseTaken, doseMissed, prescriptionAdded;
  final List<PatientProfileItem> linkedPatients;
  final int activePatientIndex;
  final OrderStage orderStage;
  final ValueChanged<AppRole> onRoleChanged;
  final VoidCallback onTaken, onMissed, onPrescriptionAdded;
  final ValueChanged<OrderStage> onOrderStageChanged;
  final void Function(String code, {String? name, String? relation}) onAddPatient;
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

  // --- CẬP NHẬT NAV ĐỂ THÊM TAB THEO DÕI CHO CAREGIVER ---
  List<_NavItem> get nav => switch (widget.role) {
    AppRole.patient => const [
      _NavItem(Icons.home_rounded, 'Hôm nay'),
      _NavItem(Icons.medication_rounded, 'Uống thuốc'),
      _NavItem(Icons.calendar_month_rounded, 'Lịch uống'),
      _NavItem(Icons.person_rounded, 'Hồ sơ'),
    ],
    AppRole.caregiver => const [
      _NavItem(Icons.grid_view_rounded, 'Tổng quan'),
      _NavItem(Icons.receipt_long_rounded, 'Đơn thuốc'),
      _NavItem(Icons.storefront_rounded, 'Nhà thuốc'),
      _NavItem(Icons.near_me_rounded, 'Theo dõi'),
      _NavItem(Icons.person_rounded, 'Hồ sơ'),
    ],
    AppRole.pharmacist => const [
      _NavItem(Icons.dashboard_rounded, 'Xử lý đơn'),
      _NavItem(Icons.inventory_2_rounded, 'Kho thuốc'),
      _NavItem(Icons.history_rounded, 'Lịch sử'),
    ],
    AppRole.shipper => const [
      _NavItem(Icons.route_rounded, 'Chuyến giao'),
      _NavItem(Icons.assignment_turned_in_rounded, 'Đã giao'),
      _NavItem(Icons.person_rounded, 'Tài khoản'),
    ],
    AppRole.admin => const [
      _NavItem(Icons.insights_rounded, 'Hệ thống'),
      _NavItem(Icons.people_alt_rounded, 'Người dùng'),
      _NavItem(Icons.security_rounded, 'Cảnh báo'),
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
            _TopBar(role: widget.role, onRoleChanged: widget.onRoleChanged),
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
            _GlassBottomNav(
              items: nav,
              currentIndex: tab,
              onTap: (value) => setState(() => tab = value),
            ),
          ],
        ),
      ),
    ),
  );

  // --- TÍCH HỢP CÁC FILE .DART TỪ AI STUDIO ---
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
      onTaken: widget.onTaken,
    ),

  // --- CAREGIVER: CHÈN NHÀ THUỐC VÀ TRACKING VÀO ĐÂY ---
    AppRole.caregiver => tab == 2
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

  // --- PHARMACIST: CHÈN XÁC NHẬN ĐƠN VÀO ĐÂY ---
    AppRole.pharmacist => tab == 0
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

  // --- SHIPPER: CHÈN TÀI XẾ NHẬN CHUYẾN VÀO ĐÂY ---
    AppRole.shipper => tab == 0
        ? ShipperTaskScreen(
      key: ValueKey('${widget.role}$tab'),
      onConfirmPickup: () {
        // Khi tài xế xác nhận, tự nhảy về Caregiver và mở tab Bản Đồ (3)
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.role, required this.onRoleChanged});
  final AppRole role;
  final ValueChanged<AppRole> onRoleChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(
      children: [
        const _BrandMark(),
        const Spacer(),
        GestureDetector(
          onTap: () => _showRoles(context),
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
                Text(
                  role.code,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  void _showRoles(BuildContext context) => showModalBottomSheet(
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
          const Text(
            'Chuyển vai trò demo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 10),
          ...AppRole.values.map(
                (item) => ListTile(
              leading: CircleAvatar(
                backgroundColor: item == role
                    ? const Color(0xFF5268F5)
                    : const Color(0xFFE6E9FF),
                child: Icon(
                  item.icon,
                  color: item == role ? Colors.white : const Color(0xFF33418C),
                ),
              ),
              title: Text(
                item.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: item == role
                  ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF5268F5),
              )
                  : null,
              onTap: () {
                Navigator.pop(context);
                onRoleChanged(item);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class PatientHome extends StatelessWidget {
  const PatientHome({
    super.key,
    required this.tab,
    required this.doseTaken,
    required this.doseMissed,
    required this.onTaken,
    this.prescriptionAdded = false,
    this.onPrescriptionAdded,
    this.isLinked = true,
    this.linkedPatientCode = 'PA-8899',
  });
  final int tab;
  final bool doseTaken, doseMissed, prescriptionAdded, isLinked;
  final String linkedPatientCode;
  final VoidCallback onTaken;
  final VoidCallback? onPrescriptionAdded;

  @override
  Widget build(BuildContext context) {
    if (tab == 1) {
      return _Scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              'Uống thuốc theo đơn',
              'Chi tiết đơn thuốc và cữ uống của cô Lan',
            ),
            Glass(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE7E9FF),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Color(0xFF5267F4),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Người chăm sóc: Trần Minh Anh (Con gái)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Đã liên kết · Đang đồng bộ đơn thuốc',
                          style: TextStyle(
                            color: Color(0xFF249D76),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, color: Color(0xFF249D76)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cữ thuốc cần uống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _DoseCard(taken: doseTaken, missed: doseMissed, onTaken: onTaken),
            const SizedBox(height: 18),
            const Text(
              'Toa thuốc đang điều trị',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const _PrescriptionCard(
              'Liệu trình huyết áp & tiểu đường',
              '16/09 - 16/10/2026',
              '3 thuốc · 3 khung giờ (Sáng, Trưa, Tối)',
            ),
            if (prescriptionAdded) ...[
              const SizedBox(height: 10),
              const _PrescriptionCard(
                'Vitamin tổng hợp',
                '16/09 - 16/11/2026',
                '1 thuốc · 08:00 sáng',
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _showAddMedicineModal(
                context,
                onAdded: () => onPrescriptionAdded?.call(),
                isPatient: true,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Thêm thuốc mới / thuốc ngoài đơn'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 14),
            Glass(
              padding: const EdgeInsets.all(14),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF5267F4),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lưu ý: Uống thuốc đúng giờ sau bữa ăn. Bấm "Tôi đã uống đủ thuốc" để tự động thông báo đến người chăm sóc.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (tab == 2) {
      return _Scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro('Lịch uống thuốc', 'Thứ Hai, 16 tháng 9'),
            _DayStrip(),
            const SizedBox(height: 18),
            _TimelineItem(
              '07:30',
              'Sáng',
              'Metformin · Vitamin D3',
              doseTaken ? 'Đã hoàn thành' : 'Đã đến giờ',
              doseTaken ? const Color(0xFF259F78) : const Color(0xFF5469F5),
            ),
            _TimelineItem(
              '12:30',
              'Trưa',
              'Amlodipine 5mg',
              'Sắp tới',
              const Color(0xFFF0A042),
            ),
            _TimelineItem(
              '20:00',
              'Tối',
              'Atorvastatin 10mg',
              'Sắp tới',
              const Color(0xFF9A72DB),
            ),
          ],
        ),
      );
    }
    if (tab == 3) {
      return _Scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              'Hồ sơ sức khoẻ',
              'Thông tin cá nhân & mã liên kết',
            ),
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: Color(0xFF5267F4),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Mã liên kết của bạn',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      _StatusChip(
                        isLinked ? 'Đã liên kết' : 'Chưa liên kết',
                        isLinked
                            ? const Color(0xFF249D76)
                            : const Color(0xFFF09B3C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        linkedPatientCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5065F2),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLinked
                        ? 'Đã kết nối với người chăm sóc: Trần Minh Anh (Con gái).'
                        : 'Đưa mã này cho người chăm sóc để liên kết tài khoản và nhận lịch nhắc thuốc.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E7590),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Glass(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: Color(0xFFFFD9C6),
                    child: Icon(
                      Icons.face_3_rounded,
                      size: 38,
                      color: Color(0xFFAD6047),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyễn Thị Lan',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('72 tuổi · Nhóm máu O+'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Glass(
              padding: const EdgeInsets.all(18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Người liên hệ khẩn cấp',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Trần Minh Anh'),
                    subtitle: Text('Con gái · 090 123 4567'),
                    trailing: Icon(
                      Icons.call_rounded,
                      color: Color(0xFF5065F2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Glass(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: Color(0xFF5065F2)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Âm lượng chuông nhắc',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Đang đặt mức tối đa cho người lớn tuổi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF717993),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip('Tối đa', Color(0xFF249D76)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _Scroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro(
            'Chào buổi sáng, cô Lan',
            'Hôm nay là một ngày tuyệt vời',
          ),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF5368F4), Color(0xFF8068DD)],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFFFE39A),
                  size: 35,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '16 tháng 9',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Hôm nay có 3 liều thuốc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (doseMissed) _EmergencyPatientCard(),
          Text(
            doseTaken ? 'Tuyệt vời, cô đã hoàn thành!' : 'Đến giờ uống thuốc',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _DoseCard(taken: doseTaken, missed: doseMissed, onTaken: onTaken),
          const SizedBox(height: 20),
          const Text(
            'Tiến độ hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: doseTaken ? .34 : 0.0,
                        strokeWidth: 7,
                        backgroundColor: const Color(0xFFE6E8F8),
                      ),
                      Text(
                        doseTaken ? '1/3' : '0/3',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chăm sóc sức khoẻ mỗi ngày',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 3),
                      Text('Còn 2 liều thuốc trong hôm nay'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      return _PrescriptionPage(
        added: prescriptionAdded,
        onAdded: onPrescriptionAdded,
      );
    }
    // LƯU Ý: tab == 2 (Nhà thuốc) và tab == 3 (Theo dõi) đã được xử lý ở _content() phía trên
    if (tab == 4) {
      return _CaregiverProfilePage(
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

    return _Scroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro('Chào Anh!', 'Theo dõi sức khoẻ người thân'),
          if (doseMissed) _AlertCard(),
          if (!hasPatients)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Glass(
                padding: const EdgeInsets.all(14),
                child: const Row(
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
                            : Colors.white.withOpacity(.7),
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
                    _StatusChip(
                      doseTaken ? 'Hoàn thành 1/3' : 'Chờ xác nhận',
                      doseTaken
                          ? const Color(0xFF249D76)
                          : const Color(0xFFF09B3C),
                    ),
                  ],
                ),
                const Divider(height: 25),
                _MedicationRow(
                  '07:30',
                  'Metformin + Vitamin D3',
                  doseTaken ? 'Đã uống' : 'Đang chờ',
                  doseTaken ? const Color(0xFF259F78) : const Color(0xFFF0A042),
                ),
                const SizedBox(height: 14),
                _MedicationRow(
                  '12:30',
                  'Amlodipine 5mg',
                  'Sắp tới',
                  const Color(0xFF5C70F2),
                ),
                const SizedBox(height: 14),
                _MedicationRow(
                  '20:00',
                  'Atorvastatin 10mg',
                  'Sắp tới',
                  const Color(0xFF5C70F2),
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
          Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.medication_liquid_rounded,
                  color: Color(0xFFE1784C),
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Expanded(
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
                const Icon(
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

class _CaregiverProfilePage extends StatefulWidget {
  const _CaregiverProfilePage({
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
  State<_CaregiverProfilePage> createState() => _CaregiverProfilePageState();
}

class _CaregiverProfilePageState extends State<_CaregiverProfilePage> {
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
  Widget build(BuildContext context) => _Scroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Hồ sơ người chăm sóc',
          'Quản lý thông tin & liên kết bệnh nhân',
        ),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFDCE2FE),
                child: Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Color(0xFF5066F3),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
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
              _StatusChip('Hoạt động', const Color(0xFF249D76)),
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
                        _StatusChip('Đang theo dõi', const Color(0xFF249D76))
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
        Glass(
          padding: const EdgeInsets.all(16),
          child: const Row(
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
              _StatusChip('15 phút', Color(0xFFD65E4A)),
            ],
          ),
        ),
      ],
    ),
  );
}

class PharmacistHome extends StatelessWidget {
  const PharmacistHome({
    super.key,
    required this.tab,
    required this.orderStage,
    required this.onOrderStageChanged,
  });
  final int tab;
  final OrderStage orderStage;
  final ValueChanged<OrderStage> onOrderStageChanged;
  @override
  Widget build(BuildContext context) {
    if (tab == 1) return _WarehousePage();
    return _Scroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro('Quầy dược An Tâm', 'Có 3 đơn cần xử lý hôm nay'),
          Glass(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFF5066F5),
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Đơn #MR-20260916-018\nNguyễn Thị Lan · Từ Trần Minh Anh',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusChip(_stageText(orderStage), _stageColor(orderStage)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kiểm tra đơn thuốc',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CheckLine('Đơn bác sĩ hợp lệ', true),
                const _CheckLine('Không trùng hoạt chất', true),
                const _CheckLine('Tương tác thuốc: thấp', true),
                const Divider(height: 25),
                const Text(
                  'Thuốc trong đơn',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const _SmallDrug(
                  'Metformin 500mg',
                  '60 viên',
                  'Có sẵn · 42 hộp',
                ),
                const _SmallDrug(
                  'Vitamin D3 1000IU',
                  '30 viên',
                  'Có sẵn · 18 hộp',
                ),
                const _SmallDrug(
                  'Amlodipine 5mg',
                  '30 viên',
                  'Sắp hết · 5 hộp',
                ),
                const SizedBox(height: 12),
                if (orderStage == OrderStage.review)
                  FilledButton.icon(
                    onPressed: () {
                      onOrderStageChanged(OrderStage.verified);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đơn đã được duyệt và chuyển kho.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Duyệt & chuyển kho'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                if (orderStage == OrderStage.verified)
                  FilledButton.icon(
                    onPressed: () => onOrderStageChanged(OrderStage.pickedUp),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('Bàn giao cho shipper'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShipperHome extends StatelessWidget {
  const ShipperHome({
    super.key,
    required this.tab,
    required this.orderStage,
    required this.onOrderStageChanged,
  });
  final int tab;
  final OrderStage orderStage;
  final ValueChanged<OrderStage> onOrderStageChanged;
  @override
  Widget build(BuildContext context) => _Scroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro('Chào Huy!', 'Bạn có 2 chuyến giao hôm nay'),
        Glass(
          padding: const EdgeInsets.all(17),
          gradient: const LinearGradient(
            colors: [Color(0xFF5469F5), Color(0xFF739BEC)],
          ),
          child: const Row(
            children: [
              Icon(Icons.route_rounded, color: Colors.white, size: 35),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điểm giao tiếp theo',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Nhà cô Nguyễn Thị Lan',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '#MR-20260916-018',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  _StatusChip(_stageText(orderStage), _stageColor(orderStage)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '12 Nguyễn Huệ, P. Bến Nghé, Q.1\nNgười nhận: Cô Lan / chị Minh Anh · 090 123 4567',
              ),
              const Divider(height: 25),
              const Row(
                children: [
                  Icon(Icons.medication_rounded, color: Color(0xFF5066F5)),
                  SizedBox(width: 9),
                  Text('3 loại thuốc · Thanh toán online'),
                ],
              ),
              const SizedBox(height: 15),
              if (orderStage == OrderStage.verified)
                FilledButton.icon(
                  onPressed: () => onOrderStageChanged(OrderStage.pickedUp),
                  icon: const Icon(Icons.inventory_rounded),
                  label: const Text('Xác nhận đã lấy đơn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(47),
                  ),
                ),
              if (orderStage == OrderStage.pickedUp)
                FilledButton.icon(
                  onPressed: () => onOrderStageChanged(OrderStage.delivering),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Bắt đầu giao hàng'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(47),
                  ),
                ),
              if (orderStage == OrderStage.delivering)
                FilledButton.icon(
                  onPressed: () => onOrderStageChanged(OrderStage.delivered),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Xác nhận đã giao thuốc'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(47),
                  ),
                ),
              if (orderStage == OrderStage.delivered)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Đơn đã giao thành công ✓',
                      style: TextStyle(
                        color: Color(0xFF21996E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key, required this.doseMissed});
  final bool doseMissed;
  @override
  Widget build(BuildContext context) => _Scroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Trung tâm điều hành',
          'Tổng quan hệ thống MedsReminder',
        ),
        Row(
          children: [
            const _Metric(
              '1,248',
              'Bệnh nhân',
              Icons.favorite_rounded,
              Color(0xFF566BF5),
            ),
            const SizedBox(width: 10),
            const _Metric(
              '96.8%',
              'Tuân thủ',
              Icons.trending_up_rounded,
              Color(0xFF28A378),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const _Metric(
              '87',
              'Người chăm sóc',
              Icons.volunteer_activism_rounded,
              Color(0xFF9A70DB),
            ),
            const SizedBox(width: 10),
            _Metric(
              doseMissed ? '1' : '0',
              'Cảnh báo mới',
              Icons.warning_rounded,
              const Color(0xFFD65E4A),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Glass(
          padding: const EdgeInsets.all(15),
          child: const Column(
            children: [
              _Activity(
                Icons.check_circle_rounded,
                'Cô Nguyễn Thị Lan đã uống liều sáng',
                '07:38',
                Color(0xFF28A378),
              ),
              _Activity(
                Icons.link_rounded,
                'Một tài khoản PA vừa được liên kết',
                '07:20',
                Color(0xFF556AF4),
              ),
              _Activity(
                Icons.local_shipping_rounded,
                'Đơn #MR-018 được tạo',
                '07:06',
                Color(0xFF9A70DB),
              ),
            ],
          ),
        ),
        if (doseMissed)
          Padding(padding: const EdgeInsets.only(top: 14), child: _AlertCard()),
      ],
    ),
  );
}

class _PrescriptionPage extends StatelessWidget {
  const _PrescriptionPage({required this.added, required this.onAdded});
  final bool added;
  final VoidCallback onAdded;
  @override
  Widget build(BuildContext context) => _Scroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Đơn thuốc của cô Lan',
          'Quản lý và thiết lập lịch nhắc',
        ),
        Glass(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFF249D76)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đã liên kết tài khoản PA\nNguyễn Thị Lan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF249D76)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _PrescriptionCard(
          'Liệu trình huyết áp & tiểu đường',
          '16/09 - 16/10/2026',
          '3 thuốc · 3 khung giờ',
        ),
        const SizedBox(height: 12),
        if (added)
          const _PrescriptionCard(
            'Vitamin tổng hợp',
            '16/09 - 16/11/2026',
            '1 thuốc · 08:00',
          ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _showAddMedicineModal(
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

void _showAddMedicineModal(
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
        child: _AddMedicineSheet(
          onAdded: onAdded,
          isPatient: isPatient,
        ),
      ),
    ),
  );
}

class _MedicineFormItem {
  const _MedicineFormItem({
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

const List<_MedicineFormItem> _medicineForms = [
  _MedicineFormItem(
    name: 'Viên nang',
    icon: Icons.medication_liquid_rounded,
    defaultDose: '1 viên / lần',
    dosageHints: ['1 viên', '2 viên', '1/2 viên'],
    suggestedNote: 'Uống nguyên viên cùng nước lọc',
  ),
  _MedicineFormItem(
    name: 'Viên nén',
    icon: Icons.circle_rounded,
    defaultDose: '1 viên / lần',
    dosageHints: ['1 viên', '2 viên', '1/2 viên'],
    suggestedNote: 'Uống sau bữa ăn no',
  ),
  _MedicineFormItem(
    name: 'Dạng nước / siro',
    icon: Icons.water_drop_rounded,
    defaultDose: '10 ml / lần',
    dosageHints: ['5 ml', '10 ml', '15 ml', '1 nắp'],
    suggestedNote: 'Lắc đều trước khi uống, dùng cốc đong',
  ),
  _MedicineFormItem(
    name: 'Dạng bột / gói',
    icon: Icons.all_inbox_rounded,
    defaultDose: '1 gói / lần',
    dosageHints: ['1 gói', '2 gói', '1/2 gói'],
    suggestedNote: 'Pha tan với 100ml nước ấm',
  ),
  _MedicineFormItem(
    name: 'Dạng xịt / hít',
    icon: Icons.air_rounded,
    defaultDose: '2 nhát xịt / lần',
    dosageHints: ['1 nhát', '2 nhát', '3 nhát'],
    suggestedNote: 'Xịt thẳng vào vòm họng / khoang mũi',
  ),
  _MedicineFormItem(
    name: 'Dạng bôi ngoài da',
    icon: Icons.healing_rounded,
    defaultDose: 'Thoa 1 lớp mỏng',
    dosageHints: ['1 lớp mỏng', '2 lần / ngày'],
    suggestedNote: 'Vệ sinh sạch da trước khi thoa thuốc',
  ),
];

class _AddMedicineSheet extends StatefulWidget {
  const _AddMedicineSheet({
    required this.onAdded,
    this.isPatient = false,
  });
  final VoidCallback onAdded;
  final bool isPatient;

  @override
  State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
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
      text: _medicineForms[0].defaultDose,
    );
    _timeController = TextEditingController(text: '08:00 sáng');
    _noteController = TextEditingController(
      text: 'Uống Sau bữa ăn, ${_medicineForms[0].suggestedNote}',
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
      _doseController.text = _medicineForms[index].defaultDose;
      _noteController.text = 'Uống $_selectedMealTiming, ${_medicineForms[index].suggestedNote}';
    });
  }

  Widget _mealTimingBox(String title, IconData icon) {
    final isSelected = _selectedMealTiming == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMealTiming = title;
            _noteController.text = 'Uống $title, ${_medicineForms[_selectedFormIndex].suggestedNote}';
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
                color: const Color(0xFF5168F4).withOpacity(0.25),
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
    final currentForm = _medicineForms[_selectedFormIndex];

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
              children: List.generate(_medicineForms.length, (index) {
                final form = _medicineForms[index];
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
                          color: const Color(0xFF5168F4).withOpacity(0.28),
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
            // Dòng "Lưu ý khi uống" gồm 3 ô để chọn: "Trước bữa ăn, Sau bữa ăn, Trong khi ăn"
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

class _WarehousePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Scroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro('Kho thuốc', 'Cập nhật lúc 08:15 hôm nay'),
        const _Inventory(
          'Metformin 500mg',
          '42 hộp',
          'Đủ hàng',
          .74,
          Color(0xFF269E77),
        ),
        const _Inventory(
          'Vitamin D3 1000IU',
          '18 hộp',
          'Đủ hàng',
          .43,
          Color(0xFF556AF4),
        ),
        const _Inventory(
          'Amlodipine 5mg',
          '5 hộp',
          'Sắp hết',
          .13,
          Color(0xFFE88C44),
        ),
        const _Inventory(
          'Atorvastatin 10mg',
          '0 hộp',
          'Hết hàng',
          0,
          Color(0xFFD75F4D),
        ),
      ],
    ),
  );
}

class AnimatedAuroraBackground extends StatelessWidget {
  const AnimatedAuroraBackground({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final drift = Curves.easeInOut.transform(animation.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                const Color(0xFFE7ECFF),
                const Color(0xFFFFE8F5),
                drift,
              )!,
              Color.lerp(
                const Color(0xFFF9F1FF),
                const Color(0xFFE9F7FF),
                drift,
              )!,
              Color.lerp(
                const Color(0xFFD8FAF1),
                const Color(0xFFE4DFFF),
                drift,
              )!,
            ],
          ),
        ),
        child: Stack(
          children: [
            _AuroraOrb(
              alignment: Alignment(-1.12 + drift * .22, -.92 + drift * .12),
              size: 250,
              color: const Color(0xFF88A0FF).withOpacity(.34),
            ),
            _AuroraOrb(
              alignment: Alignment(.98 - drift * .18, -.36 + drift * .22),
              size: 205,
              color: const Color(0xFFD19EFF).withOpacity(.28),
            ),
            _AuroraOrb(
              alignment: Alignment(.52 + drift * .20, 1.08 - drift * .10),
              size: 270,
              color: const Color(0xFF6EE5C7).withOpacity(.25),
            ),
            _FloatingPill(
              alignment: Alignment(-.92 + drift * .13, .20),
              turn: drift * .55,
              color: const Color(0xFFFF86B9),
              icon: Icons.favorite_rounded,
            ),
            _FloatingPill(
              alignment: Alignment(.94 - drift * .12, .62),
              turn: -.22 - drift * .48,
              color: const Color(0xFF736BFF),
              icon: Icons.medication_rounded,
            ),
            _Sparkle(
              alignment: Alignment(-.58, -.45 + drift * .16),
              color: const Color(0xFFFFB742),
              size: 18,
            ),
            _Sparkle(
              alignment: Alignment(.78, -.80 + drift * .12),
              color: const Color(0xFF37DDBD),
              size: 14,
            ),
            _Sparkle(
              alignment: Alignment(.12 + drift * .18, .87),
              color: const Color(0xFFFF72B4),
              size: 13,
            ),
            Positioned.fill(child: child!),
          ],
        ),
      );
    },
  );
}

class _AuroraOrb extends StatelessWidget {
  const _AuroraOrb({
    required this.alignment,
    required this.size,
    required this.color,
  });
  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}

class _FloatingPill extends StatelessWidget {
  const _FloatingPill({
    required this.alignment,
    required this.turn,
    required this.color,
    required this.icon,
  });
  final Alignment alignment;
  final double turn;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: turn,
        child: Container(
          width: 46,
          height: 31,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(.92), color],
            ),
            border: Border.all(color: Colors.white.withOpacity(.78)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.48),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -turn,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
      ),
    ),
  );
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.alignment,
    required this.color,
    required this.size,
  });
  final Alignment alignment;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: Icon(Icons.auto_awesome_rounded, color: color, size: size),
    ),
  );
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.gradient,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Gradient? gradient;
  @override
  Widget build(BuildContext context) => Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()
      ..setEntry(3, 2, .001)
      ..rotateX(.008),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33477F).withOpacity(.14),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(.75),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient:
              gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(.76),
                      Colors.white.withOpacity(.42),
                    ],
                  ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withOpacity(.88)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.82),
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  right: -25,
                  child: IgnorePointer(
                    child: Container(
                      width: 120,
                      height: 85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(80),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(.30),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) => setState(() => pressed = true),
    onTapCancel: () => setState(() => pressed = false),
    onTapUp: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: pressed ? .96 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
        child: widget.child,
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC99433).withOpacity(.32),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Image.asset('assets/images/medsreminder_logo.png'), // Bạn nhớ thêm ảnh vào tài nguyên nhé!
      ),
      const SizedBox(width: 7),
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MedsReminder',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              height: .95,
              letterSpacing: -.4,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A70),
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Nhắc thuốc đều đều, sức khỏe thêm nhiều.',
            style: TextStyle(
              fontSize: 8.2,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8F692F),
            ),
          ),
        ],
      ),
    ],
  );
}

class PageIntro extends StatelessWidget {
  const PageIntro(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2A54),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF687195), fontSize: 14),
        ),
      ],
    ),
  );
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 115),
    child: child,
  );
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Glass(
      radius: 25,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(
                horizontal: items.length > 3 ? 9 : 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: active
                    ? const LinearGradient(
                  colors: [Color(0xFFEAF0FF), Color(0xFFC9D3FF)],
                )
                    : null,
                boxShadow: active
                    ? [
                  BoxShadow(
                    color: const Color(0xFF586FF3).withOpacity(.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    color: active
                        ? const Color(0xFF5066F3)
                        : const Color(0xFF7B839E),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF4459D9)
                          : const Color(0xFF747D98),
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(.13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800),
    ),
  );
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.taken,
    required this.missed,
    required this.onTaken,
  });
  final bool taken, missed;
  final VoidCallback onTaken;
  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Color(0xFF5167F2),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liều buổi sáng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text('07:30 · Sau khi ăn sáng'),
                ],
              ),
            ),
            _StatusChip(
              taken
                  ? 'Đã uống'
                  : missed
                  ? 'Đã trễ'
                  : 'Đến giờ',
              taken
                  ? const Color(0xFF249D76)
                  : missed
                  ? const Color(0xFFD65E4A)
                  : const Color(0xFFF0A042),
            ),
          ],
        ),
        const Divider(height: 26),
        const _SmallDrug('Metformin 500mg', '1 viên', ''),
        const _SmallDrug('Vitamin D3 1000IU', '1 viên', ''),
        const SizedBox(height: 14),
        if (!taken)
          Pressable(
            child: FilledButton.icon(
              onPressed: onTaken,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                missed ? 'Tôi đã uống thuốc' : 'Tôi đã uống đủ thuốc',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: missed
                    ? const Color(0xFFD65E4A)
                    : const Color(0xFF299B73),
                elevation: 9,
                shadowColor:
                (missed ? const Color(0xFFD65E4A) : const Color(0xFF299B73))
                    .withOpacity(.42),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        if (taken)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Đã gửi xác nhận đến người chăm sóc',
                style: TextStyle(
                  color: Color(0xFF249D76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _EmergencyPatientCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Glass(
      padding: const EdgeInsets.all(15),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: Color(0xFFD65D4A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cảnh báo: đã quá 15 phút. Hãy uống thuốc và xác nhận ngay.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF9B3F34),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Glass(
      padding: const EdgeInsets.all(15),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD35A46), size: 29),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo cần chú ý',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFA64335),
                  ),
                ),
                Text(
                  'Cô Lan chưa xác nhận liều 07:30 sau 15 phút. Hãy gọi nhắc ngay.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow(this.time, this.name, this.status, this.color);
  final String time, name, status;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        time,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF26355F),
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      _StatusChip(status, color),
    ],
  );
}

class _DayStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['T2\n16', 'T3\n17', 'T4\n18', 'T5\n19', 'T6\n20']
          .asMap()
          .entries
          .map(
            (e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: e.key == 0
                ? const Color(0xFF5368F4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            e.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: e.key == 0 ? Colors.white : const Color(0xFF566080),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      )
          .toList(),
    ),
  );
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem(
      this.time,
      this.title,
      this.detail,
      this.status,
      this.color,
      );
  final String time, title, detail, status;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Glass(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(detail),
              ],
            ),
          ),
          _StatusChip(status, color),
        ],
      ),
    ),
  );
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text, this.pass);
  final String text;
  final bool pass;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          pass ? Icons.check_circle_rounded : Icons.error_rounded,
          color: pass ? const Color(0xFF289D76) : const Color(0xFFD65B49),
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    ),
  );
}

class _SmallDrug extends StatelessWidget {
  const _SmallDrug(this.name, this.dose, this.extra);
  final String name, dose, extra;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF5368F4)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$dose ${extra.isNotEmpty ? '· $extra' : ''}',
          style: const TextStyle(color: Color(0xFF6B7492), fontSize: 12),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.number, this.label, this.icon, this.color);
  final String number, label;
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
          const SizedBox(height: 10),
          Text(
            number,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF69728F), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _Activity extends StatelessWidget {
  const _Activity(this.icon, this.text, this.time, this.color);
  final IconData icon;
  final String text, time;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 11, color: Color(0xFF78809B)),
        ),
      ],
    ),
  );
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard(this.title, this.date, this.detail);
  final String title, date, detail;
  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFE7E9FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Color(0xFF5267F4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(color: Color(0xFF717993), fontSize: 12),
              ),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF717993), fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _Inventory extends StatelessWidget {
  const _Inventory(this.name, this.qty, this.status, this.value, this.color);
  final String name, qty, status;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              _StatusChip(status, color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(7),
                  color: color,
                  backgroundColor: const Color(0xFFE5E8F2),
                ),
              ),
              const SizedBox(width: 10),
              Text(qty, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ),
  );
}

String _stageText(OrderStage stage) => switch (stage) {
  OrderStage.review => 'Chờ duyệt',
  OrderStage.verified => 'Chờ lấy hàng',
  OrderStage.pickedUp => 'Đã lấy đơn',
  OrderStage.delivering => 'Đang giao',
  OrderStage.delivered => 'Đã giao',
};

Color _stageColor(OrderStage stage) => switch (stage) {
  OrderStage.review => const Color(0xFFF0A042),
  OrderStage.verified => const Color(0xFF586CF4),
  OrderStage.pickedUp => const Color(0xFF9B72D9),
  OrderStage.delivering => const Color(0xFF297DCE),
  OrderStage.delivered => const Color(0xFF249D76),
};
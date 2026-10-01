import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/models.dart';
import 'routing/url_strategy.dart';
import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'services/auth_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  // Đặt thanh trạng thái iOS / Android trong suốt như yêu cầu
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MedsReminderApp());
}

class MedsReminderApp extends StatefulWidget {
  const MedsReminderApp({super.key, this.authApi});

  final AuthApi? authApi;

  @override
  State<MedsReminderApp> createState() => _MedsReminderAppState();
}

class _MedsReminderAppState extends State<MedsReminderApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthApi _authApi;
  AuthUser? _currentUser;
  bool _checkingSession = true;
  AppRole role = AppRole.patient;
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

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    var authenticated = false;
    try {
      await Future.wait<Object?>([
        _authApi.refreshSession(),
        Future<void>.delayed(const Duration(milliseconds: 900)),
      ]);
      authenticated = true;
    } catch (_) {
      authenticated = false;
    }
    if (!mounted) return;
    setState(() {
      _currentUser = authenticated
          ? const AuthUser(
              id: '',
              email: '',
              fullName: 'Bệnh nhân',
              role: AppRole.patient,
            )
          : null;
      role = AppRole.patient;
      _checkingSession = false;
    });
    _replaceRoute(authenticated ? '/patient' : '/login');
  }

  Future<void> _login(String email, String password) async {
    await _authApi.login(email: email, password: password);
    if (!mounted) return;
    setState(() {
      _currentUser = AuthUser(
        id: '',
        email: email,
        fullName: email.split('@').first,
        role: AppRole.patient,
      );
      role = AppRole.patient;
    });
    _replaceRoute('/patient');
  }

  Future<void> _logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // The server session may already be expired; still clear local UI state.
    } finally {
      if (mounted) setState(() => _currentUser = null);
      _replaceRoute('/login');
    }
  }

  void _replaceRoute(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  @override
  void dispose() {
    _authApi.close();
    super.dispose();
  }

  void markTaken() => setState(() {
    doseTaken = true;
    doseMissed = false;
  });

  void markMissed() => setState(() {
    doseTaken = false;
    doseMissed = true;
  });

  void addPatient(String code, {String? name, String? relation}) =>
      setState(() {
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
    navigatorKey: _navigatorKey,
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
          shadowColor: const Color(0xFF665EF7).withValues(alpha: .36),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFF63A9),
      ),
    ),
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _authGate(),
    ),
  );

  Widget _authGate() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 550),
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    child: _checkingSession
        ? const SplashScreen(key: ValueKey('splash'))
        : _currentUser == null
        ? LoginScreen(key: const ValueKey('login'), onLogin: _login)
        : AppShell(
            key: const ValueKey('app-shell'),
            role: role,
            userName: _currentUser!.fullName,
            onLogout: _logout,
            doseTaken: doseTaken,
            doseMissed: doseMissed,
            prescriptionAdded: prescriptionAdded,
            orderStage: orderStage,
            linkedPatients: linkedPatients,
            activePatientIndex: activePatientIndex,
            onRoleChanged: (_) {},
            onTaken: markTaken,
            onMissed: markMissed,
            onPrescriptionAdded: () => setState(() => prescriptionAdded = true),
            onOrderStageChanged: (value) => setState(() => orderStage = value),
            onAddPatient: addPatient,
            onRemovePatient: removePatient,
            onSelectPatient: selectPatient,
          ),
  );
}

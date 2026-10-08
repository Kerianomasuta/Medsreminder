import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/care_network_controller.dart';
import 'controllers/pharmacist_dashboard_controller.dart';
import 'models/models.dart';
import 'routing/url_strategy.dart';
import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/invitation/invitation_screen.dart';
import 'services/auth_api.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await NotificationService.instance.init();
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
  CareNetworkController? _networkController;
  PharmacistDashboardController? _pharmacistController;
  String? _pendingInvitationUuid;
  bool _checkingSession = true;
  bool _showingRegistration = false;
  AppRole role = AppRole.patient;
  bool doseTaken = false;
  bool doseMissed = false;
  bool prescriptionAdded = false;
  OrderStage orderStage = OrderStage.review;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _pendingInvitationUuid = Uri.base.queryParameters['invitationUUID'];
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    AuthUser? restoredUser;
    try {
      final results = await Future.wait<Object?>([
        _authApi.refreshSession(),
        Future<void>.delayed(const Duration(milliseconds: 900)),
      ]);
      restoredUser = results.first as AuthUser;
    } catch (_) {}
    if (!mounted) return;
    _replaceNetworkController(restoredUser);
    setState(() {
      _currentUser = restoredUser;
      if (restoredUser != null) role = restoredUser.role;
      _checkingSession = false;
    });
    _replaceRoute(_routeFor(restoredUser));
  }

  Future<void> _login(String email, String password) async {
    final user = await _authApi.login(email: email, password: password);
    if (!mounted) return;
    _replaceNetworkController(user);
    setState(() {
      _currentUser = user;
      role = user.role;
      _showingRegistration = false;
    });
    _replaceRoute(_routeFor(user));
  }

  Future<void> _register(
    String email,
    String password,
    String fullName,
    String phone,
    AppRole selectedRole,
  ) async {
    await _authApi.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: selectedRole,
    );
    await _login(email, password);
  }

  Future<void> _logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // The server session may already be expired; still clear local UI state.
    } finally {
      if (mounted) {
        setState(() {
          _currentUser = null;
          _showingRegistration = false;
          _pendingInvitationUuid = null;
        });
        _replaceNetworkController(null);
      }
      _replaceRoute('/login');
    }
  }

  void _replaceRoute(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  String _routeFor(AuthUser? user) {
    if (user == null) return '/login';
    if (_pendingInvitationUuid != null) {
      return '/invitation?invitationUUID=$_pendingInvitationUuid';
    }
    return user.role.route;
  }

  void _replaceNetworkController(AuthUser? user) {
    _networkController?.dispose();
    _pharmacistController?.dispose();
    _pharmacistController = null;
    _networkController = user == null
        ? null
        : CareNetworkController(user: user);
    if (user?.role == AppRole.patient || user?.role == AppRole.caregiver) {
      _networkController!.initialize();
    }
    if (user?.role == AppRole.pharmacist) {
      _pharmacistController = PharmacistDashboardController(user: user!)
        ..initialize();
    }
  }

  void _closeInvitation() {
    setState(() => _pendingInvitationUuid = null);
    _replaceRoute(_currentUser!.role.route);
  }

  @override
  void dispose() {
    _authApi.close();
    _networkController?.dispose();
    _pharmacistController?.dispose();
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
        ? _showingRegistration
              ? RegisterScreen(
                  key: const ValueKey('register'),
                  onRegister: _register,
                  onBackToLogin: () {
                    setState(() => _showingRegistration = false);
                    _replaceRoute('/login');
                  },
                )
              : LoginScreen(
                  key: const ValueKey('login'),
                  onLogin: _login,
                  onOpenRegister: () {
                    setState(() => _showingRegistration = true);
                    _replaceRoute('/register');
                  },
                )
        : _signedInContent(),
  );

  Widget _signedInContent() {
    final user = _currentUser!;
    final controller = _networkController!;
    final invitationUuid = _pendingInvitationUuid;
    if (invitationUuid != null) {
      return InvitationScreen(
        key: const ValueKey('invitation'),
        invitationUuid: invitationUuid,
        user: user,
        controller: controller,
        onCompleted: _closeInvitation,
        onCancel: _closeInvitation,
      );
    }
    return AppShell(
      key: const ValueKey('app-shell'),
      role: role,
      userName: user.fullName,
      userEmail: user.email,
      networkController: controller,
      pharmacistController: _pharmacistController,
      onLogout: _logout,
      doseTaken: doseTaken,
      doseMissed: doseMissed,
      prescriptionAdded: prescriptionAdded,
      orderStage: orderStage,
      onRoleChanged: (_) {},
      onTaken: markTaken,
      onMissed: markMissed,
      onPrescriptionAdded: () => setState(() => prescriptionAdded = true),
      onOrderStageChanged: (value) => setState(() => orderStage = value),
    );
  }
}

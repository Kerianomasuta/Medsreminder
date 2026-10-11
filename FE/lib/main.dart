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
import 'services/auth_cookie_adapter.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await AuthCookieAdapter().restore();
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

class _MedsReminderAppState extends State<MedsReminderApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthApi _authApi;
  AuthUser? _currentUser;
  CareNetworkController? _networkController;
  PharmacistDashboardController? _pharmacistController;
  String? _pendingInvitationUuid;
  bool _checkingSession = true;
  bool _showingRegistration = false;
  bool _showingSkipReason = false;
  AppRole role = AppRole.patient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.skipReasonRequest.addListener(
      _onSkipReasonRequested,
    );
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
    if (restoredUser?.role == AppRole.patient) {
      NotificationService.instance.refreshUpcomingMedicationLogs();
    }
    _replaceRoute(_routeFor(restoredUser));
    _scheduleSkipReasonDialog();
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
    if (user.role == AppRole.patient) {
      NotificationService.instance.refreshUpcomingMedicationLogs();
    }
    _replaceRoute(_routeFor(user));
    _scheduleSkipReasonDialog();
  }

  Future<void> _register(RegistrationInput input) async {
    await _authApi.register(input);
    await _login(input.email, input.password);
  }

  Future<void> _logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // The server session may already be expired; still clear local UI state.
    } finally {
      AuthCookieAdapter().clear();
      await NotificationService.instance.clearMedicationState();
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
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.skipReasonRequest.removeListener(
      _onSkipReasonRequested,
    );
    _authApi.close();
    _networkController?.dispose();
    _pharmacistController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _currentUser?.role == AppRole.patient) {
      NotificationService.instance.refreshUpcomingMedicationLogs();
      _scheduleSkipReasonDialog();
    }
  }

  void _onSkipReasonRequested() => _scheduleSkipReasonDialog();

  void _scheduleSkipReasonDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSkipReasonDialogIfNeeded();
    });
  }

  Future<void> _showSkipReasonDialogIfNeeded() async {
    final request = NotificationService.instance.skipReasonRequest.value;
    if (!mounted ||
        request == null ||
        _showingSkipReason ||
        _checkingSession ||
        _currentUser?.role != AppRole.patient) {
      return;
    }
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    _showingSkipReason = true;
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SkipMedicationDialog(),
    );
    try {
      if (reason != null) {
        await NotificationService.instance.submitSkipReason(request, reason);
      }
    } finally {
      NotificationService.instance.clearSkipReasonRequest(request);
      _showingSkipReason = false;
    }
  }

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
      onRoleChanged: (_) {},
    );
  }
}

class _SkipMedicationDialog extends StatefulWidget {
  const _SkipMedicationDialog();

  @override
  State<_SkipMedicationDialog> createState() => _SkipMedicationDialogState();
}

class _SkipMedicationDialogState extends State<_SkipMedicationDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Bỏ qua cữ thuốc'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhập lý do nếu có. Cữ thuốc chỉ được đánh dấu bỏ qua sau khi bạn xác nhận.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('skip-reason-field'),
          controller: _reasonController,
          autofocus: true,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do bỏ qua (không bắt buộc)',
            hintText: 'Ví dụ: Buồn nôn',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        key: const Key('confirm-skip-dose'),
        onPressed: () => Navigator.pop(context, _reasonController.text.trim()),
        child: const Text('Xác nhận bỏ qua'),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/main.dart';
import 'package:meds_reminder/screens/app_shell.dart';
import 'package:meds_reminder/screens/auth/login_screen.dart';
import 'package:meds_reminder/screens/auth/splash_screen.dart';
import 'package:meds_reminder/services/auth_api.dart';
import 'package:meds_reminder/models/auth_user.dart';
import 'package:meds_reminder/models/app_role.dart';

class FakeAuthApi extends AuthApi {
  @override
  Future<AuthUser> refreshSession() async {
    throw const AuthApiException('No session');
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async => AuthUser(
    id: 'user-1',
    email: email,
    fullName: 'Dược sĩ Demo',
    role: AppRole.pharmacist,
  );

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('shows logo splash, login, then the user dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(MedsReminderApp(authApi: FakeAuthApi()));

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 901));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).at(0),
      'memaybeo@gmail.com',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Dược sĩ Demo'), findsOneWidget);
    expect(find.text('Xử lý đơn'), findsOneWidget);
  });
}

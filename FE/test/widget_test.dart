import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/main.dart';
import 'package:meds_reminder/screens/app_shell.dart';
import 'package:meds_reminder/screens/auth/login_screen.dart';
import 'package:meds_reminder/screens/auth/splash_screen.dart';
import 'package:meds_reminder/services/auth_api.dart';

class FakeAuthApi extends AuthApi {
  @override
  Future<void> refreshSession() async {
    throw const AuthApiException('No session');
  }

  @override
  Future<void> login({required String email, required String password}) async {}

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
    expect(find.text('memaybeo'), findsOneWidget);
  });
}

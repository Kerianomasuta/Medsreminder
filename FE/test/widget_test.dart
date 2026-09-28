// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meds_reminder/main.dart';

void main() {
  testWidgets('shows welcome screen before opening the caregiver dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedsReminderApp());

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });
}

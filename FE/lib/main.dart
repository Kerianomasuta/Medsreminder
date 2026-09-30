import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/models.dart';
import 'screens/app_shell.dart';
import 'screens/welcome/welcome_screen.dart';

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
          shadowColor: const Color(0xFF665EF7).withValues(alpha: .36),
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
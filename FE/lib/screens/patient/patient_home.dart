import 'package:flutter/material.dart';

import '../../controllers/care_network_controller.dart';
import 'patient_connections_page.dart';
import 'patient_today_view.dart';
import 'schedule_timeline_page.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({
    super.key,
    required this.tab,
    required this.networkController,
  });

  final int tab;
  final CareNetworkController networkController;

  @override
  Widget build(BuildContext context) => switch (tab) {
    1 => ScheduleTimelinePage(patientId: networkController.user.id),
    2 => PatientConnectionsPage(controller: networkController),
    _ => PatientTodayView(patientId: networkController.user.id),
  };
}

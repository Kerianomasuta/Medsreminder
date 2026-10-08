import 'package:flutter/material.dart';

import '../../controllers/care_network_controller.dart';
import 'medication_log_timeline_page.dart';
import 'patient_connections_page.dart';
import 'patient_today_view.dart';

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
    1 => const MedicationLogTimelinePage(),
    2 => PatientConnectionsPage(controller: networkController),
    _ => const PatientTodayView(),
  };
}

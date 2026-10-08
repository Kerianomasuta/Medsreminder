import 'package:flutter/material.dart';

import '../../controllers/care_network_controller.dart';
import 'medicine_catalog_page.dart';
import 'patient_connections_page.dart';
import 'patient_today_view.dart';
import 'schedule_timeline_page.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({
    super.key,
    required this.tab,
    required this.patientId,
    required this.networkController,
    required this.doseTaken,
    required this.doseMissed,
    required this.onTaken,
    this.prescriptionAdded = false,
    this.onPrescriptionAdded,
  });

  final int tab;
  final String patientId;
  final CareNetworkController networkController;
  final bool doseTaken;
  final bool doseMissed;
  final bool prescriptionAdded;
  final VoidCallback onTaken;
  final VoidCallback? onPrescriptionAdded;

  @override
  Widget build(BuildContext context) => switch (tab) {
    1 => const MedicineCatalogPage(),
    2 => ScheduleTimelinePage(patientId: patientId),
    3 => PatientConnectionsPage(controller: networkController),
    _ => PatientTodayView(
      patientId: patientId,
      doseTaken: doseTaken,
      doseMissed: doseMissed,
      onTaken: onTaken,
    ),
  };
}

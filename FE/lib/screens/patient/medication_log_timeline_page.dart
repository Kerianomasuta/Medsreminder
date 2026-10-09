import 'package:flutter/material.dart';

import '../../controllers/medication_logs_controller.dart';
import 'schedule_timeline_page.dart';

/// Backwards-compatible route name. Schedule rules are now the primary data
/// source for every medication timeline; medication logs are loaded lazily by
/// the schedule detail sheet.
class MedicationLogTimelinePage extends StatelessWidget {
  const MedicationLogTimelinePage({super.key, this.controller, this.patientId});

  @Deprecated('Schedule pages no longer use MedicationLogsController')
  final MedicationLogsController? controller;
  final String? patientId;

  @override
  Widget build(BuildContext context) =>
      ScheduleTimelinePage(patientId: patientId);
}

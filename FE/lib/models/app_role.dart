import 'package:flutter/material.dart';

enum AppRole { patient, caregiver, pharmacist, shipper, admin }

enum OrderStage { review, verified, pickedUp, delivering, delivered }

extension RoleData on AppRole {
  String get label => switch (this) {
    AppRole.patient => 'Bệnh nhân',
    AppRole.caregiver => 'Người chăm sóc',
    AppRole.pharmacist => 'Dược sĩ',
    AppRole.shipper => 'Người giao thuốc',
    AppRole.admin => 'Quản trị viên',
  };

  String get code => switch (this) {
    AppRole.patient => 'PA',
    AppRole.caregiver => 'CG',
    AppRole.pharmacist => 'P',
    AppRole.shipper => 'DS',
    AppRole.admin => 'SA',
  };

  IconData get icon => switch (this) {
    AppRole.patient => Icons.favorite_rounded,
    AppRole.caregiver => Icons.volunteer_activism_rounded,
    AppRole.pharmacist => Icons.medication_rounded,
    AppRole.shipper => Icons.local_shipping_rounded,
    AppRole.admin => Icons.admin_panel_settings_rounded,
  };
}

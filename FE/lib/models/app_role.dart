import 'package:flutter/material.dart';

enum AppRole { patient, caregiver, pharmacist, admin }

extension RoleData on AppRole {
  String get apiValue => switch (this) {
    AppRole.patient => 'PATIENT',
    AppRole.caregiver => 'CARE_GIVER',
    AppRole.pharmacist => 'PHARMACIST',
    AppRole.admin => 'ADMIN',
  };

  String get route => switch (this) {
    AppRole.patient => '/patient',
    AppRole.caregiver => '/caregiver',
    AppRole.pharmacist => '/pharmacist',
    AppRole.admin => '/admin',
  };

  String get label => switch (this) {
    AppRole.patient => 'Bệnh nhân',
    AppRole.caregiver => 'Người chăm sóc',
    AppRole.pharmacist => 'Dược sĩ',
    AppRole.admin => 'Quản trị viên',
  };

  String get code => switch (this) {
    AppRole.patient => 'PA',
    AppRole.caregiver => 'CG',
    AppRole.pharmacist => 'P',
    AppRole.admin => 'SA',
  };

  IconData get icon => switch (this) {
    AppRole.patient => Icons.favorite_rounded,
    AppRole.caregiver => Icons.volunteer_activism_rounded,
    AppRole.pharmacist => Icons.medication_rounded,
    AppRole.admin => Icons.admin_panel_settings_rounded,
  };
}

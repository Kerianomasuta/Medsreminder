import 'app_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final AppRole role;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? 'Người dùng',
    role: _roleFromApi(json['role']?.toString()),
    avatarUrl: json['avatarUrl']?.toString(),
  );

  static AppRole _roleFromApi(String? role) => switch (role?.toUpperCase()) {
    'PATIENT' => AppRole.patient,
    'CARE_GIVER' || 'CAREGIVER' => AppRole.caregiver,
    'PHARMACIST' => AppRole.pharmacist,
    'ADMIN' => AppRole.admin,
    _ => throw FormatException('Unsupported user role: $role'),
  };
}

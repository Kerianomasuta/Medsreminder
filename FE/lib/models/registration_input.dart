import 'app_role.dart';

class RegistrationInput {
  const RegistrationInput({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
    this.pharmacyName,
    this.addressText,
    this.latitude,
    this.longitude,
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;
  final AppRole role;
  final String? pharmacyName;
  final String? addressText;
  final double? latitude;
  final double? longitude;

  Map<String, Object> toJson() {
    final payload = <String, Object>{
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role.apiValue,
    };
    if (role != AppRole.pharmacist) return payload;

    final name = pharmacyName?.trim() ?? '';
    final address = addressText?.trim() ?? '';
    final lat = latitude;
    final lng = longitude;
    if (name.isEmpty || address.isEmpty || lat == null || lng == null) {
      throw ArgumentError(
        'Pharmacist registration requires pharmacy name and location.',
      );
    }
    payload.addAll({
      'pharmacyName': name,
      'addressText': address,
      'latitude': lat,
      'longitude': lng,
    });
    return payload;
  }
}

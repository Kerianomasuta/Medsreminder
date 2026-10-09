import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/pharmacist_dashboard.dart';
import '../../models/registration_input.dart';
import '../../services/geocoding_api.dart';
import '../../services/device_location_service.dart';
import '../../widgets/pharmacy_location_picker.dart';
import 'auth_backdrop.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onBackToLogin,
    this.geocodingApi,
    this.locationProvider,
    this.showLocationMap = true,
  });

  final Future<void> Function(RegistrationInput input) onRegister;
  final VoidCallback onBackToLogin;
  final GeocodingApi? geocodingApi;
  final DeviceLocationProvider? locationProvider;
  final bool showLocationMap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  PharmacyLocationSelection? _pharmacyLocation;
  AppRole _role = AppRole.patient;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  static const _registerableRoles = [
    AppRole.patient,
    AppRole.caregiver,
    AppRole.pharmacist,
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pharmacyNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_role == AppRole.pharmacist && _pharmacyLocation == null) {
        setState(() {
          _loading = false;
          _error = 'Vui lòng tìm và xác nhận vị trí nhà thuốc.';
        });
        return;
      }
      await widget.onRegister(
        RegistrationInput(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _role,
          pharmacyName: _role == AppRole.pharmacist
              ? _pharmacyNameController.text.trim()
              : null,
          addressText: _pharmacyLocation?.addressText,
          latitude: _pharmacyLocation?.latitude,
          longitude: _pharmacyLocation?.longitude,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x245075A9),
                  blurRadius: 36,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tạo tài khoản',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF102F60),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Họ và tên', Icons.person_outline),
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      return length < 2 || length > 30
                          ? 'Họ tên cần từ 2 đến 30 ký tự'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Email', Icons.alternate_email),
                    validator: (value) =>
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Vui lòng nhập email hợp lệ',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      'Số điện thoại',
                      Icons.phone_outlined,
                    ),
                    validator: (value) =>
                        RegExp(r'^0[235789][0-9]{8}$')
                            .hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Vui lòng nhập số điện thoại Việt Nam hợp lệ',
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AppRole>(
                    key: const Key('registration-role'),
                    initialValue: _role,
                    decoration: _decoration('Vai trò', Icons.badge_outlined),
                    items: _registerableRoles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.label),
                          ),
                        )
                        .toList(),
                    onChanged: _loading
                        ? null
                        : (value) => setState(() {
                            _role = value!;
                            if (_role != AppRole.pharmacist) {
                              _pharmacyLocation = null;
                            }
                          }),
                  ),
                  if (_role == AppRole.pharmacist) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('pharmacy-name'),
                      controller: _pharmacyNameController,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                        'Tên nhà thuốc',
                        Icons.local_pharmacy_outlined,
                      ),
                      validator: (value) {
                        if (_role != AppRole.pharmacist) {
                          return null;
                        }
                        final length = value?.trim().length ?? 0;
                        if (length == 0) return 'Vui lòng nhập tên nhà thuốc';
                        if (length > 150) {
                          return 'Tên nhà thuốc tối đa 150 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    PharmacyLocationPicker(
                      key: const Key('registration-pharmacy-location'),
                      geocodingApi: widget.geocodingApi,
                      locationProvider: widget.locationProvider,
                      showMap: widget.showLocationMap,
                      onChanged: (location) =>
                          setState(() => _pharmacyLocation = location),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Mật khẩu', Icons.lock_outline)
                        .copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Mật khẩu cần ít nhất 8 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                    decoration: _decoration(
                      'Xác nhận mật khẩu',
                      Icons.lock_reset_rounded,
                    ),
                    validator: (value) => value != _passwordController.text
                        ? 'Mật khẩu xác nhận không khớp'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF9B3434)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('registration-submit'),
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Đăng ký'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : widget.onBackToLogin,
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF496DAA)),
    filled: true,
    fillColor: const Color(0xFFF3F7FD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide.none,
    ),
  );
}

import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import 'auth_backdrop.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onBackToLogin,
  });

  final Future<void> Function(
    String email,
    String password,
    String fullName,
    String phone,
    AppRole role,
  )
  onRegister;
  final VoidCallback onBackToLogin;

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
  AppRole _role = AppRole.patient;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  static const _registerableRoles = [
    AppRole.patient,
    AppRole.caregiver,
    AppRole.pharmacist,
    AppRole.shipper,
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onRegister(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        _role,
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
                        : (value) => setState(() => _role = value!),
                  ),
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

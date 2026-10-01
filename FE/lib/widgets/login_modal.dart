import 'package:flutter/material.dart';
import '../models/app_role.dart';
import '../services/auth_service.dart';

void showLoginModal(
  BuildContext context, {
  required ValueChanged<AuthUser> onSuccess,
  VoidCallback? onSkip,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black45,
    builder: (ctx) => _LoginModalSheet(onSuccess: onSuccess, onSkip: onSkip),
  );
}

class _RoleOption {
  final AppRole role;
  final String label;
  final IconData icon;
  final Color color;

  const _RoleOption(this.role, this.label, this.icon, this.color);
}

class _LoginModalSheet extends StatefulWidget {
  const _LoginModalSheet({required this.onSuccess, this.onSkip});

  final ValueChanged<AuthUser> onSuccess;
  final VoidCallback? onSkip;

  @override
  State<_LoginModalSheet> createState() => _LoginModalSheetState();
}

class _LoginModalSheetState extends State<_LoginModalSheet> {
  // Để trống theo yêu cầu của người dùng
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AppRole _selectedRole = AppRole.patient;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  static const _roleOptions = [
    _RoleOption(
      AppRole.patient,
      'Bệnh nhân',
      Icons.elderly_rounded,
      Color(0xFF5065F2),
    ),
    _RoleOption(
      AppRole.caregiver,
      'Người chăm sóc',
      Icons.volunteer_activism_rounded,
      Color(0xFFE05688),
    ),
    _RoleOption(
      AppRole.pharmacist,
      'Dược sĩ',
      Icons.local_pharmacy_rounded,
      Color(0xFF10B981),
    ),
    _RoleOption(
      AppRole.shipper,
      'Giao thuốc',
      Icons.delivery_dining_rounded,
      Color(0xFFF59E0B),
    ),
    _RoleOption(
      AppRole.admin,
      'Quản trị',
      Icons.admin_panel_settings_rounded,
      Color(0xFF6366F1),
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ Email và Mật khẩu.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.login(email: email, password: password);

    if (!mounted) return;

    if (result.isSuccess && result.user != null) {
      Navigator.of(context).pop();
      // Ưu tiên role của tài khoản đăng nhập hoặc role đã chọn
      final finalUser = AuthUser(
        userId: result.user!.userId,
        deviceId: result.user!.deviceId,
        fullName: result.user!.fullName,
        rawRole: result.user!.rawRole,
        role: _selectedRole, // Dùng role mà người dùng đã chọn
        accessToken: result.user!.accessToken,
        refreshToken: result.user!.refreshToken,
      );
      widget.onSuccess(finalUser);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message;
      });
    }
  }

  void _handleDemoSkip() {
    Navigator.of(context).pop();
    final demoUser = AuthUser(
      userId: 'demo-user',
      deviceId: 'demo-device',
      fullName: 'Người dùng thử nghiệm',
      rawRole: _selectedRole.name,
      role: _selectedRole,
    );
    widget.onSuccess(demoUser);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Color(0xFF5065F2),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng nhập MedsReminder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Chọn vai trò & nhập tài khoản',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Ô chọn Role trên field Email
            const Text(
              'Chọn vai trò của bạn',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roleOptions.map((opt) {
                final isSelected = _selectedRole == opt.role;
                return InkWell(
                  onTap: () => setState(() => _selectedRole = opt.role),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? opt.color.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? opt.color : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: opt.color.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 17,
                          color: isSelected ? opt.color : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? opt.color
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB4B4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFD32F2F), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Email / Tài khoản',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Nhập email...',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF5065F2), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mật khẩu',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu...',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF5065F2), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF082452),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.login_rounded, size: 20),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _handleDemoSkip,
              child: const Text(
                'Bỏ qua & Xem thử giao diện theo vai trò đã chọn',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

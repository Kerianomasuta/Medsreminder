import 'package:flutter/material.dart';

import '../../controllers/care_network_controller.dart';
import '../../models/app_role.dart';
import '../../models/auth_user.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({
    super.key,
    required this.invitationUuid,
    required this.user,
    required this.controller,
    required this.onCompleted,
    required this.onCancel,
  });

  final String invitationUuid;
  final AuthUser user;
  final CareNetworkController controller;
  final VoidCallback onCompleted;
  final VoidCallback onCancel;

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final validRole = widget.user.role == AppRole.caregiver;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 18,
                shadowColor: const Color(0xFF5A57F7).withValues(alpha: .18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE7E9FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          validRole
                              ? Icons.volunteer_activism_rounded
                              : Icons.lock_person_rounded,
                          size: 42,
                          color: const Color(0xFF5267F4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        validRole
                            ? 'Lời mời chăm sóc'
                            : 'Cần tài khoản người chăm sóc',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2A54),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        validRole
                            ? '${widget.user.fullName}, hãy xác nhận để kết nối và theo dõi lịch uống thuốc của bệnh nhân.'
                            : 'Link này chỉ có thể được xác nhận bằng tài khoản CARE_GIVER.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF687195)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFC64E57)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (validRole)
                        FilledButton.icon(
                          onPressed: _submitting ? null : _confirm,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.link_rounded),
                          label: const Text('Xác nhận kết nối'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.controller.verifyInvitation(widget.invitationUuid);
      if (mounted) widget.onCompleted();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

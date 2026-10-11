import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/care_network_controller.dart';
import '../../widgets/widgets.dart';

class PatientConnectionsPage extends StatefulWidget {
  const PatientConnectionsPage({super.key, required this.controller});

  final CareNetworkController controller;

  @override
  State<PatientConnectionsPage> createState() => _PatientConnectionsPageState();
}

class _PatientConnectionsPageState extends State<PatientConnectionsPage> {
  bool _creating = false;
  String? _error;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => AppScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro(
            'Kết nối người chăm sóc',
            'Chia sẻ lời mời bảo mật và quản lý tài khoản đã liên kết',
          ),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFFE7E9FF),
                      child: Icon(Icons.link_rounded, color: Color(0xFF5267F4)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mời người chăm sóc',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Mã mời có hiệu lực tối đa 15 phút',
                            style: TextStyle(
                              color: Color(0xFF6E7590),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.controller.invitationUuid != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      widget.controller.invitationUuid!,
                      style: const TextStyle(
                        color: Color(0xFF3D4FC2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _copyUuid,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Sao chép mã mời'),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _creating ? null : _createInvitation,
                    icon: _creating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Tạo mã mời'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFC64E57)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Người chăm sóc đã kết nối',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              StatusChip(
                '${widget.controller.linkedCaregivers.length}',
                const Color(0xFF249D76),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.controller.linksLoading)
            const Center(child: CircularProgressIndicator())
          else if (widget.controller.linksError != null)
            _ErrorCard(
              message: widget.controller.linksError!,
              onRetry: () => widget.controller.loadLinkedAccounts(force: true),
            )
          else if (widget.controller.linkedCaregivers.isEmpty)
            const Glass(
              padding: EdgeInsets.all(22),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, color: Color(0xFF74809E)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chưa có người chăm sóc nào. Hãy tạo và gửi mã mời.',
                      style: TextStyle(color: Color(0xFF687195)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.controller.linkedCaregivers.map(
              (caregiver) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Glass(
                  padding: const EdgeInsets.all(15),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDDF7EE),
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        color: Color(0xFF249D76),
                      ),
                    ),
                    title: Text(
                      caregiver.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Đang kết nối'),
                    trailing: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF249D76),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _createInvitation() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await widget.controller.createInvitation();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _copyUuid() async {
    await Clipboard.setData(
      ClipboardData(text: widget.controller.invitationUuid!),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã sao chép mã mời.')));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFC64E57)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
  );
}

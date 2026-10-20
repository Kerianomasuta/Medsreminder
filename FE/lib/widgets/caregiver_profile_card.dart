import 'package:flutter/material.dart';

import '../services/billing_api.dart';
import 'pressable.dart';

/// Thẻ hiển thị hồ sơ người dùng kết hợp gọi API:
/// GET https://medsreminder.duckdns.org/api/v1/users/profile
class CaregiverProfileCard extends StatefulWidget {
  const CaregiverProfileCard({
    super.key,
    required this.userName,
    required this.userEmail,
    this.roleName = 'Người chăm sóc',
    this.billingApi,
    this.onUpgradeTap,
    this.onProfileRefreshed,
  });

  final String userName;
  final String userEmail;
  final String roleName;
  final BillingApi? billingApi;
  final VoidCallback? onUpgradeTap;
  final ValueChanged<UserVipProfile>? onProfileRefreshed;

  @override
  State<CaregiverProfileCard> createState() => CaregiverProfileCardState();
}

class CaregiverProfileCardState extends State<CaregiverProfileCard> {
  late final BillingApi _billingApi = widget.billingApi ?? BillingApi();

  UserVipProfile? _profile;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    refreshProfile(silent: false);
  }

  /// Gọi API GET https://medsreminder.duckdns.org/api/v1/users/profile
  Future<void> refreshProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final profile = await _billingApi.getUserVipProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _errorMessage = null;
      });
      widget.onProfileRefreshed?.call(profile);
      if (silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin hồ sơ người dùng'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVip = _profile?.isPremium == true;
    final expiry = _profile?.premiumExpiresAt;
    final expiryText = expiry != null
        ? '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVip
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: isVip ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isVip
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Email, Refresh Button
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isVip
                          ? const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: isVip
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isVip
                          ? const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFFFD700),
                              size: 32,
                            )
                          : const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF4F46E5),
                              size: 32,
                            ),
                    ),
                  ),
                  if (isVip)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF4C1D95),
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName
                                : 'Người dùng',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isVip)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.userEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Nút làm mới profile qua API
              Tooltip(
                message: 'Tải lại thông tin hồ sơ (GET /api/v1/users/profile)',
                child: Pressable(
                  onTap: _loading ? null : () => refreshProfile(silent: true),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: Color(0xFF475569),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Thông tin Vai trò & Gói tài khoản
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Vai trò',
                  value: widget.roleName,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: isVip
                      ? Icons.workspace_premium_rounded
                      : Icons.account_circle_outlined,
                  label: 'Gói tài khoản',
                  value: isVip
                      ? (expiryText != null ? 'VIP • Hết hạn $expiryText' : 'VIP')
                      : 'Tiêu chuẩn',
                  badgeColor: isVip ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                  color: isVip ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              'Không thể lấy thông tin profile: $_errorMessage',
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

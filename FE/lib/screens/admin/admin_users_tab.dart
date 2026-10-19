import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_api.dart';
import '../../widgets/glass.dart';
import '../../widgets/pressable.dart';

/// Tab Quản lý người dùng - Giao diện hiện đại, Glassmorphism, đầy đủ bộ lọc và chi tiết tài khoản
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key, required this.adminApi});

  final AdminApi adminApi;

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchController = TextEditingController();

  String _selectedRole = 'ALL';
  String _selectedActive = 'ALL'; // ALL, TRUE, FALSE
  int _currentPage = 1;
  static const int _limit = 20;

  bool _loading = false;
  String? _error;
  AdminUserListResponse? _userResponse;

  // Overview summary for quick stats at the top
  AdminSummary? _summary;
  bool _summaryLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final s = await widget.adminApi.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = s;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    bool? isActiveFilter;
    if (_selectedActive == 'TRUE') isActiveFilter = true;
    if (_selectedActive == 'FALSE') isActiveFilter = false;

    try {
      final res = await widget.adminApi.getUsers(
        role: _selectedRole == 'ALL' ? null : _selectedRole,
        q: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        isActive: isActiveFilter,
        page: _currentPage,
        limit: _limit,
      );

      if (!mounted) return;
      setState(() {
        _userResponse = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openUserDetailModal(String userId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        userId: userId,
        adminApi: widget.adminApi,
        onEditRequested: () {
          Navigator.of(context).pop();
          _openUserEditModal(userId);
        },
      ),
    );
  }

  void _openUserEditModal(String userId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserEditSheet(
        userId: userId,
        adminApi: widget.adminApi,
        onUserUpdated: () {
          _fetchSummary();
          _fetchUsers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _userResponse?.users ?? const [];
    final total = _userResponse?.total ?? 0;
    final totalPages = total > 0 ? ((total - 1) ~/ _limit) + 1 : 1;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Nút làm mới
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý người dùng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Phân quyền, kiểm tra VIP và khóa/mở tài khoản',
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
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () {
                  _fetchSummary();
                  _fetchUsers();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: _loading
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Làm mới',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thẻ thống kê nhanh người dùng (Quick Stats Glass)
          if (_summary != null) ...[
            _buildUserSummaryCards(_summary!),
            const SizedBox(height: 16),
          ],

          // Thanh tìm kiếm và bộ lọc (Search & Filters Card)
          Glass(
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ô tìm kiếm
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên, email, số điện thoại...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _currentPage = 1;
                                      _fetchUsers();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            _currentPage = 1;
                            _fetchUsers();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      onTap: _loading
                          ? null
                          : () {
                              _currentPage = 1;
                              _fetchUsers();
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Tìm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bộ lọc theo Vai trò
                Row(
                  children: [
                    const Text(
                      'Vai trò:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRoleChip('Tất cả', 'ALL', Icons.apps_rounded),
                            _buildRoleChip(
                              'Bệnh nhân',
                              'PATIENT',
                              Icons.person_rounded,
                            ),
                            _buildRoleChip(
                              'Người chăm sóc',
                              'CARE_GIVER',
                              Icons.favorite_rounded,
                            ),
                            _buildRoleChip(
                              'Dược sĩ',
                              'PHARMACIST',
                              Icons.local_pharmacy_rounded,
                            ),
                            _buildRoleChip(
                              'Admin',
                              'ADMIN',
                              Icons.admin_panel_settings_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bộ lọc theo Trạng thái hoạt động
                Row(
                  children: [
                    const Text(
                      'Trạng thái:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildActiveChip('Tất cả', 'ALL', null),
                            _buildActiveChip(
                              'Đang hoạt động',
                              'TRUE',
                              const Color(0xFF10B981),
                            ),
                            _buildActiveChip(
                              'Đã tắt / khóa',
                              'FALSE',
                              const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kết quả danh sách
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _buildErrorState()
          else if (users.isEmpty)
            _buildEmptyState()
          else ...[
            // Tổng số kết quả
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Hiển thị ${users.length} / $total tài khoản',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),

            // Danh sách các User Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserListItemCard(
                  user: user,
                  onTap: () => _openUserDetailModal(user.id),
                  onEdit: () => _openUserEditModal(user.id),
                );
              },
            ),

            const SizedBox(height: 16),

            // Thanh phân trang (Pagination)
            if (total > 0)
              _buildPaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                totalItems: total,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserSummaryCards(AdminSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            label: 'Tổng tài khoản',
            value: '${summary.totalUsers}',
            sub: '+${summary.registeredLast7Days} trong 7 ngày',
            icon: Icons.group_rounded,
            color: const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniCard(
            label: 'Hội viên VIP',
            value: '${summary.premiumCount}',
            sub: 'Đang trả phí',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFFD97706),
            isGold: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniCard(
            label: 'Bị khóa',
            value: '${summary.inactiveCount}',
            sub: 'Cần xử lý',
            icon: Icons.lock_person_rounded,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String label, String value, IconData icon) {
    final isSelected = _selectedRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Pressable(
        onTap: () {
          setState(() {
            _selectedRole = value;
            _currentPage = 1;
          });
          _fetchUsers();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFCBD5E1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChip(String label, String value, Color? dotColor) {
    final isSelected = _selectedActive == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Pressable(
        onTap: () {
          setState(() {
            _selectedActive = value;
            _currentPage = 1;
          });
          _fetchUsers();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalPages,
    required int totalItems,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang $currentPage / $totalPages (Tổng $totalItems)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 20,
                color: const Color(0xFF334155),
                disabledColor: const Color(0xFFCBD5E1),
                onPressed: currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _fetchUsers();
                      }
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currentPage',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 20,
                color: const Color(0xFF334155),
                disabledColor: const Color(0xFFCBD5E1),
                onPressed: currentPage < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _fetchUsers();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 48,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Không tìm thấy người dùng phù hợp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hãy thử điều chỉnh từ khóa tìm kiếm hoặc bỏ bớt các bộ lọc.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            'Lỗi tải danh sách người dùng: $_error',
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _fetchUsers,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.isGold = false,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGold
              ? const Color(0xFFFDE68A)
              : color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isGold ? const Color(0xFF92400E) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Thẻ User Card hiện đại với hiệu ứng Glassmorphism, nút Cập nhật riêng và tương tác chạm
class _UserListItemCard extends StatelessWidget {
  const _UserListItemCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
  });

  final AdminUserItem user;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFE11D48); // Rose
      case 'CARE_GIVER':
        return const Color(0xFF7C3AED); // Purple
      case 'PHARMACIST':
        return const Color(0xFF0D9488); // Teal
      case 'PATIENT':
      default:
        return const Color(0xFF2563EB); // Blue
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'CARE_GIVER':
        return 'Người chăm sóc';
      case 'PHARMACIST':
        return 'Dược sĩ';
      case 'PATIENT':
      default:
        return 'Bệnh nhân';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: user.isPremium
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE2E8F0),
            width: user.isPremium ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: user.isPremium
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar với gradient vòng tròn & huy hiệu VIP
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withValues(alpha: 0.8),
                        roleColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.characters.first.toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (user.isPremium)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Thông tin chính: Tên, Email, SĐT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.phone!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Nhãn vai trò, Trạng thái hoạt động & Nút Cập nhật gộp chung vào 1 cột bên phải
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _getRoleLabel(user.role),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: user.isActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                          : const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Hoạt động' : 'Đã khóa',
                        style: TextStyle(
                          color: user.isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Pressable(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Sửa',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet: Chỉ xem chi tiết đầy đủ tài khoản (Read-Only)
class _UserDetailSheet extends StatefulWidget {
  const _UserDetailSheet({
    required this.userId,
    required this.adminApi,
    required this.onEditRequested,
  });

  final String userId;
  final AdminApi adminApi;
  final VoidCallback onEditRequested;

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _loading = true;
  String? _error;
  AdminUserDetail? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await widget.adminApi.getUserDetail(widget.userId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFE11D48);
      case 'CARE_GIVER':
        return const Color(0xFF7C3AED);
      case 'PHARMACIST':
        return const Color(0xFF0D9488);
      case 'PATIENT':
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Quản trị viên (Admin)';
      case 'CARE_GIVER':
        return 'Người chăm sóc (Caregiver)';
      case 'PHARMACIST':
        return 'Dược sĩ (Pharmacist)';
      case 'PATIENT':
      default:
        return 'Bệnh nhân (Patient)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _detail?.user;
    final roleColor = user != null ? _getRoleColor(user.role) : const Color(0xFF4F46E5);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _loading
              ? const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? SizedBox(
                  height: 220,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text('Lỗi: $_error'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _fetchDetail,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh kéo drag handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header của modal: Avatar, Tên, và nút đóng
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  roleColor.withValues(alpha: 0.8),
                                  roleColor,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user?.fullName.isNotEmpty == true
                                  ? user!.fullName.characters.first.toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user?.fullName ?? '',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user?.isPremium == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'VIP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Thông tin chi tiết tài khoản',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Khối thông tin chi tiết (Read Only)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'User ID:',
                              widget.userId,
                              trailing: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: widget.userId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép User ID vào bộ nhớ tạm'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                              isMonospace: true,
                            ),
                            const Divider(height: 18, color: Color(0xFFE2E8F0)),
                            _buildInfoRow('Email đăng ký:', user?.email ?? ''),
                            const Divider(height: 18, color: Color(0xFFE2E8F0)),
                            _buildInfoRow(
                              'Số điện thoại:',
                              (user?.phone != null && user!.phone!.isNotEmpty)
                                  ? user.phone!
                                  : 'Chưa cập nhật',
                            ),
                            const Divider(height: 18, color: Color(0xFFE2E8F0)),
                            _buildInfoRow(
                              'Vai trò hệ thống:',
                              _getRoleLabel(user?.role ?? ''),
                              valueColor: roleColor,
                            ),
                            const Divider(height: 18, color: Color(0xFFE2E8F0)),
                            _buildInfoRow(
                              'Trạng thái tài khoản:',
                              user?.isActive == true ? 'Đang hoạt động' : 'Đã bị khóa',
                              valueColor: user?.isActive == true
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                            const Divider(height: 18, color: Color(0xFFE2E8F0)),
                            _buildInfoRow(
                              'Hạng thành viên:',
                              user?.isPremium == true ? 'Hội viên VIP (Có trả phí)' : 'Tài khoản thường (Miễn phí)',
                              valueColor: user?.isPremium == true
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF475569),
                            ),
                            if (user?.createdAt != null) ...[
                              const Divider(height: 18, color: Color(0xFFE2E8F0)),
                              _buildInfoRow(
                                'Ngày tham gia:',
                                '${user!.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}',
                              ),
                            ],
                            if ((_detail?.links.length ?? 0) > 0) ...[
                              const Divider(height: 18, color: Color(0xFFE2E8F0)),
                              _buildInfoRow(
                                'Số liên kết Chăm sóc/Bệnh nhân:',
                                '${_detail?.links.length} liên kết',
                                valueColor: const Color(0xFF7C3AED),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // 2 Nút hành động: "Đóng" và "Cập nhật tài khoản"
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              child: const Text(
                                'Đóng',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: widget.onEditRequested,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text(
                                'Cập nhật tài khoản',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isMonospace = false,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF0F172A),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    );
  }
}

/// Modal Bottom Sheet: Cập nhật thông tin người dùng (Form Edit & Save PATCH)
class _UserEditSheet extends StatefulWidget {
  const _UserEditSheet({
    required this.userId,
    required this.adminApi,
    required this.onUserUpdated,
  });

  final String userId;
  final AdminApi adminApi;
  final VoidCallback onUserUpdated;

  @override
  State<_UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<_UserEditSheet> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  AdminUserDetail? _detail;

  late final _nameController = TextEditingController();
  late final _phoneController = TextEditingController();
  String _role = 'PATIENT';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await widget.adminApi.getUserDetail(widget.userId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _nameController.text = detail.user.fullName;
        _phoneController.text = detail.user.phone ?? '';
        _role = detail.user.role;
        _isActive = detail.user.isActive;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      await widget.adminApi.updateUser(
        widget.userId,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _role,
        isActive: _isActive,
      );

      if (!mounted) return;
      widget.onUserUpdated();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin người dùng thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật thất bại: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _loading
              ? const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? SizedBox(
                  height: 220,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text('Lỗi: $_error'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _fetchDetail,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh kéo drag handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header của modal
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFF4F46E5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cập nhật thông tin tài khoản',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sửa họ tên, số điện thoại, vai trò hoặc khóa tài khoản',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Khối ID và Email tham chiếu
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Email: ${_detail?.user.email}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ID: ${widget.userId.length > 8 ? widget.userId.substring(widget.userId.length - 8) : widget.userId}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form Chỉnh sửa: Họ và tên
                      const Text(
                        'Họ và tên người dùng',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Form Chỉnh sửa: Số điện thoại
                      const Text(
                        'Số điện thoại',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Form Chỉnh sửa: Vai trò (Role)
                      const Text(
                        'Phân quyền vai trò (Role)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PATIENT',
                            child: Text('Bệnh nhân (PATIENT)'),
                          ),
                          DropdownMenuItem(
                            value: 'CARE_GIVER',
                            child: Text('Người chăm sóc (CARE_GIVER)'),
                          ),
                          DropdownMenuItem(
                            value: 'PHARMACIST',
                            child: Text('Dược sĩ nhà thuốc (PHARMACIST)'),
                          ),
                          DropdownMenuItem(
                            value: 'ADMIN',
                            child: Text('Quản trị viên hệ thống (ADMIN)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _role = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Trạng thái kích hoạt (isActive switch)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                : const Color(0xFFEF4444).withValues(alpha: 0.25),
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _isActive
                                ? 'Tài khoản ĐANG HOẠT ĐỘNG'
                                : 'Tài khoản ĐÃ BỊ KHÓA',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: _isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                          subtitle: Text(
                            _isActive
                                ? 'Người dùng có thể đăng nhập và sử dụng toàn bộ tính năng.'
                                : 'Người dùng sẽ bị chặn truy cập và không thể đăng nhập vào ứng dụng.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          value: _isActive,
                          activeTrackColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nút hành động: Lưu thay đổi (PATCH)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveChanges,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(
                            _saving ? 'Đang cập nhật...' : 'Lưu thay đổi (PATCH)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../widgets/animated_aurora_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/glass.dart';

/// Màn hình Admin Dashboard (Trung tâm điều hành)
class AdminHome extends StatefulWidget {
  const AdminHome({
    super.key,
    this.adminName = 'Quy chợ lớn',
    this.standalone,
  });

  final String adminName;
  final bool? standalone;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _auroraController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStandalone =
        widget.standalone ?? (Scaffold.maybeOf(context) == null);

    // Khi được nhúng trong AppShell (đã có sẵn TopBar và GlassBottomNav)
    if (!isStandalone) {
      return Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _AdminTitle(),
                SizedBox(height: 16),
                _AdminStatsGrid(),
                SizedBox(height: 22),
                _AdminRecentActivities(),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 12,
            child: _AdminFloatingActionButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tạo tác vụ mới'),
                    duration: Duration(milliseconds: 1200),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Khi chạy độc lập (Standalone)
    return AnimatedAuroraBackground(
      animation: _auroraController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _AdminHeader(adminName: widget.adminName),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 95),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _AdminTitle(),
                          SizedBox(height: 16),
                          _AdminStatsGrid(),
                          SizedBox(height: 22),
                          _AdminRecentActivities(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 78,
                child: _AdminFloatingActionButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tạo tác vụ mới'),
                        duration: Duration(milliseconds: 1200),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _AdminBottomNavBar(
                  currentIndex: _currentTab,
                  onTap: (index) => setState(() => _currentTab = index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header trên cùng chứa BrandMark và nút dropdown người dùng/nhà thuốc
class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.adminName});

  final String adminName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          const BrandMark(),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Glass(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4361EE),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        adminName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E284A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề chính "Trung tâm điều hành" cùng sparkle icon và phụ đề
class _AdminTitle extends StatelessWidget {
  const _AdminTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Trung tâm điều hành',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E284A),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tổng quan hệ thống MedsReminder',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.auto_awesome,
            color: Color(0xFF2DD4BF),
            size: 20,
          ),
        ),
      ],
    );
  }
}

/// Lưới thống kê 4 thẻ số liệu kính mờ (Stats Grid)
class _AdminStatsGrid extends StatelessWidget {
  const _AdminStatsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(
              child: _AdminStatCard(
                icon: Icons.favorite_rounded,
                iconColor: Color(0xFF4F6EF7),
                number: '1,248',
                label: 'Bệnh nhân',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AdminStatCard(
                icon: Icons.trending_up_rounded,
                iconColor: Color(0xFF10B981),
                number: '96.8%',
                label: 'Tuân thủ',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AdminStatCard(
                icon: Icons.volunteer_activism_rounded,
                iconColor: Color(0xFF8B5CF6),
                number: '87',
                label: 'Người chăm sóc',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AdminStatCard(
                icon: Icons.warning_rounded,
                iconColor: Color(0xFFEF4444),
                number: '0',
                label: 'Cảnh báo mới',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Thẻ số liệu thống kê đơn lẻ
class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E284A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Danh sách "Hoạt động gần đây" bọc trong container Glassmorphism
class _AdminRecentActivities extends StatelessWidget {
  const _AdminRecentActivities();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E284A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Glass(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: const [
              _AdminActivityItem(
                icon: Icons.check_circle_rounded,
                iconColor: Color(0xFF10B981),
                backgroundColor: Color(0xFFD1FAE5),
                title: 'Cô Nguyễn Thị Lan đã uống liều sáng',
                time: '07:38',
              ),
              SizedBox(height: 14),
              _AdminActivityItem(
                icon: Icons.link_rounded,
                iconColor: Color(0xFF3B82F6),
                backgroundColor: Color(0xFFDBEAFE),
                title: 'Một tài khoản PA vừa được liên kết',
                time: '07:20',
              ),
              SizedBox(height: 14),
              _AdminActivityItem(
                icon: Icons.local_shipping_rounded,
                iconColor: Color(0xFF8B5CF6),
                backgroundColor: Color(0xFFEDE9FE),
                title: 'Đơn #MR-018 được tạo',
                time: '07:06',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Từng dòng trong danh sách hoạt động gần đây
class _AdminActivityItem extends StatelessWidget {
  const _AdminActivityItem({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

/// Nút bấm nổi hình tròn màu tím nhạt mờ (Floating Action Button)
class _AdminFloatingActionButton extends StatelessWidget {
  const _AdminFloatingActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD8B4FE).withValues(alpha: 0.85),
            const Color(0xFFA78BFA).withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh điều hướng nổi bo góc tròn ở dưới cùng (Floating Bottom Navigation Bar)
class _AdminBottomNavBar extends StatelessWidget {
  const _AdminBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItemData> _items = [
    _NavItemData(Icons.insights_rounded, 'Hệ thống'),
    _NavItemData(Icons.people_alt_rounded, 'Người dùng'),
    _NavItemData(Icons.shield_outlined, 'Cảnh báo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Glass(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            final item = _items[i];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFFEAF0FF), Color(0xFFC9D3FF)],
                        )
                      : null,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0xFF586FF3).withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: active
                          ? const Color(0xFF5066F3)
                          : const Color(0xFF7B839E),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        color: active
                            ? const Color(0xFF4459D9)
                            : const Color(0xFF747D98),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.label);
  final IconData icon;
  final String label;
}

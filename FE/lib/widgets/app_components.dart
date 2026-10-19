import 'package:flutter/material.dart';

import '../services/billing_api.dart';
import 'glass.dart';
import 'pressable.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC99433).withValues(alpha: .32),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Image.asset('assets/images/medsreminder_logo.png'),
      ),
      const SizedBox(width: 7),
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MedsReminder',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              height: .95,
              letterSpacing: -.4,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A70),
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Nhắc thuốc đều đều, sức khỏe thêm nhiều.',
            style: TextStyle(
              fontSize: 8.2,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8F692F),
            ),
          ),
        ],
      ),
    ],
  );
}

class PageIntro extends StatelessWidget {
  const PageIntro(this.title, this.subtitle, {super.key});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2A54),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF687195), fontSize: 14),
        ),
      ],
    ),
  );
}

class AppScroll extends StatelessWidget {
  const AppScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 115),
    child: child,
  );
}

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Glass(
      radius: 25,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(i),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: items.length > 3 ? 2 : 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFFEAF0FF), Color(0xFFC9D3FF)],
                        )
                      : null,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0xFF586FF3)
                                .withValues(alpha: .22),
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
                      items[i].icon,
                      size: items.length > 3 ? 20 : 24,
                      color: active
                          ? const Color(0xFF5066F3)
                          : const Color(0xFF7B839E),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF4459D9)
                            : const Color(0xFF747D98),
                        fontSize: items.length > 3 ? 10 : 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800),
    ),
  );
}

Future<bool> requirePremiumAccess(BuildContext context) async {
  try {
    final profile = await BillingApi().getUserVipProfile();
    if (profile.isPremium) return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể kiểm tra gói Premium: $error'),
          backgroundColor: const Color(0xFFD65B49),
        ),
      );
    }
    return false;
  }

  if (!context.mounted) return false;
  await showPremiumRequiredDialog(context);
  return false;
}

Future<bool> isPremiumAccount() async {
  try {
    return (await BillingApi().getUserVipProfile()).isPremium;
  } catch (error) {
    debugPrint('Could not check Premium status: $error');
    return false;
  }
}

Future<void> showPremiumRequiredDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF3B82F6),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Yêu cầu tài khoản Premium',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'Tính năng này chỉ mở cho tài khoản Premium. Vui lòng đăng ký Premium để tiếp tục.',
        style: TextStyle(
          fontSize: 13.5,
          color: Color(0xFF334155),
          height: 1.35,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tôi đã hiểu'),
        ),
      ],
    ),
  );
}

class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.taken,
    required this.missed,
    required this.onTaken,
  });

  final bool taken, missed;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Color(0xFF5167F2),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liều buổi sáng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text('07:30 · Sau khi ăn sáng'),
                ],
              ),
            ),
            StatusChip(
              taken
                  ? 'Đã uống'
                  : missed
                  ? 'Đã trễ'
                  : 'Đến giờ',
              taken
                  ? const Color(0xFF249D76)
                  : missed
                  ? const Color(0xFFD65E4A)
                  : const Color(0xFFF0A042),
            ),
          ],
        ),
        const Divider(height: 26),
        const SmallDrug('Metformin 500mg', '1 viên', ''),
        const SmallDrug('Vitamin D3 1000IU', '1 viên', ''),
        const SizedBox(height: 14),
        if (!taken)
          Pressable(
            child: FilledButton.icon(
              onPressed: onTaken,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                missed ? 'Tôi đã uống thuốc' : 'Tôi đã uống đủ thuốc',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: missed
                    ? const Color(0xFFD65E4A)
                    : const Color(0xFF299B73),
                elevation: 9,
                shadowColor:
                    (missed ? const Color(0xFFD65E4A) : const Color(0xFF299B73))
                        .withValues(alpha: .42),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        if (taken)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Đã gửi xác nhận đến người chăm sóc',
                style: TextStyle(
                  color: Color(0xFF249D76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class EmergencyPatientCard extends StatelessWidget {
  const EmergencyPatientCard({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: Glass(
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: Color(0xFFD65D4A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cảnh báo: đã quá 15 phút. Hãy uống thuốc và xác nhận ngay.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF9B3F34),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Glass(
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD35A46), size: 29),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo cần chú ý',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFA64335),
                  ),
                ),
                Text(
                  'Cô Lan chưa xác nhận liều 07:30 sau 15 phút. Hãy gọi nhắc ngay.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MedicationRow extends StatelessWidget {
  const MedicationRow(
    this.time,
    this.name,
    this.status,
    this.color, {
    super.key,
  });
  final String time, name, status;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        time,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF26355F),
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      StatusChip(status, color),
    ],
  );
}

class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    this.selectedDay,
    this.onDaySelected,
    this.badgeCounts,
  });

  /// 1 = Thứ 2, 2 = Thứ 3, ..., 7 = Chủ Nhật
  final int? selectedDay;
  final ValueChanged<int>? onDaySelected;
  final Map<int, int>? badgeCounts;

  static const List<Map<String, dynamic>> _days = [
    {'day': 1, 'label': 'T2'},
    {'day': 2, 'label': 'T3'},
    {'day': 3, 'label': 'T4'},
    {'day': 4, 'label': 'T5'},
    {'day': 5, 'label': 'T6'},
    {'day': 6, 'label': 'T7'},
    {'day': 7, 'label': 'CN'},
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final activeDay = selectedDay ?? now.weekday;

    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: _days.map((item) {
          final int day = item['day'] as int;
          final String label = item['label'] as String;
          final bool isSelected = day == activeDay;
          final bool isToday = day == now.weekday;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDaySelected != null
                      ? () => onDaySelected!(day)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5368F4)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF5368F4)
                                    .withValues(alpha: .32),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                  ? const Color(0xFF5167F2)
                                  : const Color(0xFF566080)),
                        fontWeight: isSelected || isToday
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  const TimelineItem(
    this.time,
    this.title,
    this.detail,
    this.status,
    this.color, {
    super.key,
  });
  final String time, title, detail, status;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Glass(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(detail),
              ],
            ),
          ),
          StatusChip(status, color),
        ],
      ),
    ),
  );
}

class CheckLine extends StatelessWidget {
  const CheckLine(this.text, this.pass, {super.key});
  final String text;
  final bool pass;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          pass ? Icons.check_circle_rounded : Icons.error_rounded,
          color: pass ? const Color(0xFF289D76) : const Color(0xFFD65B49),
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    ),
  );
}

class SmallDrug extends StatelessWidget {
  const SmallDrug(this.name, this.dose, this.extra, {super.key});
  final String name, dose, extra;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF5368F4)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$dose ${extra.isNotEmpty ? '· $extra' : ''}',
          style: const TextStyle(color: Color(0xFF6B7492), fontSize: 12),
        ),
      ],
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard(this.number, this.label, this.icon, this.color, {super.key});
  final String number, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            number,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF69728F), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class ActivityItem extends StatelessWidget {
  const ActivityItem(this.icon, this.text, this.time, this.color, {super.key});
  final IconData icon;
  final String text, time;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 11, color: Color(0xFF78809B)),
        ),
      ],
    ),
  );
}

class PrescriptionCard extends StatelessWidget {
  const PrescriptionCard(this.title, this.date, this.detail, {super.key});
  final String title, date, detail;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFE7E9FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Color(0xFF5267F4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(color: Color(0xFF717993), fontSize: 12),
              ),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF717993), fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class InventoryItem extends StatelessWidget {
  const InventoryItem(
    this.name,
    this.qty,
    this.status,
    this.value,
    this.color, {
    super.key,
  });
  final String name, qty, status;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              StatusChip(status, color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(7),
                  color: color,
                  backgroundColor: const Color(0xFFE5E8F2),
                ),
              ),
              const SizedBox(width: 10),
              Text(qty, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Helper function to show a drug interaction warning dialog
Future<void> showDrugInteractionDialog({
  required BuildContext context,
  required String summary,
  String title = 'Cảnh báo tương tác thuốc!',
  bool isWarning = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWarning
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: isWarning
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF3B82F6),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isWarning
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWarning
                ? 'Hệ thống AI đã phát hiện nguy cơ tương tác thuốc giữa các loại thuốc trong đơn:'
                : 'Thông tin kiểm tra tương tác thuốc từ hệ thống AI:',
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isWarning
                  ? const Color(0xFFFFF1F2)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isWarning
                    ? const Color(0xFFFECDD3)
                    : const Color(0xFFBBF7D0),
                width: 1.2,
              ),
            ),
            child: Text(
              summary.trim().isEmpty
                  ? (isWarning
                        ? 'Có tương tác nghiêm trọng được phát hiện giữa các thuốc này.'
                        : 'Không phát hiện tương tác nguy hiểm.')
                  : summary,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: isWarning
                    ? const Color(0xFF9F1239)
                    : const Color(0xFF166534),
              ),
            ),
          ),
          if (isWarning) ...[
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vui lòng tham khảo ý kiến bác sĩ hoặc dược sĩ trước khi cho người bệnh dùng đồng thời các loại thuốc này.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isWarning
                ? const Color(0xFFE11D48)
                : const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            'Tôi đã hiểu',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

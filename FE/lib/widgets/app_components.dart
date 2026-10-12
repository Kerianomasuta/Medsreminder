import 'package:flutter/material.dart';
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
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(
                horizontal: items.length > 3 ? 9 : 14,
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
                    color: const Color(0xFF586FF3).withValues(alpha: .22),
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
                    color: active
                        ? const Color(0xFF5066F3)
                        : const Color(0xFF7B839E),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF4459D9)
                          : const Color(0xFF747D98),
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
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
  const MedicationRow(this.time, this.name, this.status, this.color, {super.key});
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
                  onTap: onDaySelected != null ? () => onDaySelected!(day) : null,
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
                                color: const Color(0xFF5368F4).withValues(alpha: .32),
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
                            : (isToday ? const Color(0xFF5167F2) : const Color(0xFF566080)),
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w700,
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
  const InventoryItem(this.name, this.qty, this.status, this.value, this.color, {super.key});
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

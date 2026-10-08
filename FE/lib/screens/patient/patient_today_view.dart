import 'package:flutter/material.dart';

import '../../controllers/medication_logs_controller.dart';
import '../../models/medication_log.dart';
import '../../services/notification_service.dart';
import '../../widgets/widgets.dart';

class PatientTodayView extends StatefulWidget {
  const PatientTodayView({super.key, this.controller});

  final MedicationLogsController? controller;

  @override
  State<PatientTodayView> createState() => _PatientTodayViewState();
}

class _PatientTodayViewState extends State<PatientTodayView> {
  late final MedicationLogsController _controller =
      widget.controller ?? MedicationLogsController();
  late final bool _ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _controller.loadToday();
    if (!mounted) return;
    if (_controller.loadError == null) {
      await NotificationService.instance.refreshUpcomingMedicationLogs();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _take(MedicationLog log) async {
    await _runAction(() async {
      await _controller.take(log.id);
      await NotificationService.instance.cancelMedicationLog(log.id);
    }, success: 'Đã ghi nhận cữ thuốc.');
  }

  Future<void> _snooze(MedicationLog log) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nhắc lại sau bao lâu?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context, 5),
                child: const Text('Sau 5 phút'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 10),
                child: const Text('Sau 10 phút'),
              ),
            ],
          ),
        ),
      ),
    );
    if (minutes == null || !mounted) return;
    await _runAction(() async {
      final updated = await _controller.snooze(log.id, minutes);
      await NotificationService.instance.scheduleMedicationLog(updated);
    }, success: 'Đã hoãn cữ thuốc $minutes phút.');
  }

  Future<void> _skip(MedicationLog log) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ qua cữ thuốc'),
        content: TextField(
          controller: reasonController,
          maxLength: 500,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Lý do (không bắt buộc)',
            hintText: 'Ví dụ: Buồn nôn',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Xác nhận bỏ qua'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    await _runAction(() async {
      await _controller.skip(log.id, reason: reason);
      await NotificationService.instance.cancelMedicationLog(log.id);
    }, success: 'Đã bỏ qua cữ thuốc.');
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFD65D4A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final logs = _controller.logs;
      final takenCount = logs
          .where((item) => item.status == DoseStatus.taken)
          .length;
      final hasMissed = logs.any((item) => item.status == DoseStatus.missed);
      final openLogs = logs.where((item) => item.isOpen).toList()
        ..sort(
          (a, b) => a.effectiveReminderAt.compareTo(b.effectiveReminderAt),
        );
      final nextDose = openLogs.isEmpty ? null : openLogs.first;
      final now = DateTime.now();
      final nextDoseTitle = _controller.loading && logs.isEmpty
          ? 'Đang tải cữ thuốc'
          : _controller.loadError != null && logs.isEmpty
          ? 'Không thể tải cữ thuốc'
          : nextDose == null
          ? 'Không còn cữ đang chờ'
          : 'Cữ thuốc tiếp theo';

      return AppScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PageIntro(
                  'Lịch uống hôm nay',
                  'Theo dõi từng cữ thuốc trong ngày',
                ),
                IconButton(
                  onPressed: _controller.loading ? null : _load,
                  tooltip: 'Làm mới',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF5167F2),
                  ),
                ),
              ],
            ),
            Glass(
              padding: const EdgeInsets.all(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF5368F4), Color(0xFF8068DD)],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${now.day} tháng ${now.month}, ${now.year}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _controller.loading
                              ? 'Đang cập nhật...'
                              : '$takenCount/${logs.length} cữ đã uống',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasMissed) ...[
              const SizedBox(height: 14),
              const EmergencyPatientCard(),
            ],
            const SizedBox(height: 20),
            Text(
              nextDoseTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (_controller.loading && logs.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_controller.loadError != null && logs.isEmpty)
              _ErrorCard(message: _controller.loadError!, onRetry: _load)
            else if (nextDose != null)
              _DoseLogCard(
                log: nextDose,
                processing: _controller.isProcessing(nextDose.id),
                emphasized: true,
                onTaken: () => _take(nextDose),
                onSnooze: () => _snooze(nextDose),
                onSkip: () => _skip(nextDose),
              )
            else
              const Glass(
                padding: EdgeInsets.all(18),
                child: Center(child: Text('Các cữ hôm nay đã được xử lý.')),
              ),
            const SizedBox(height: 22),
            const Text(
              'Tất cả cữ thuốc hôm nay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (!_controller.loading &&
                logs.isEmpty &&
                _controller.loadError == null)
              const Glass(
                padding: EdgeInsets.all(18),
                child: Center(child: Text('Hôm nay chưa có cữ thuốc nào.')),
              )
            else
              ...logs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DoseLogCard(
                    log: log,
                    processing: _controller.isProcessing(log.id),
                    onTaken: () => _take(log),
                    onSnooze: () => _snooze(log),
                    onSkip: () => _skip(log),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class _DoseLogCard extends StatelessWidget {
  const _DoseLogCard({
    required this.log,
    required this.processing,
    required this.onTaken,
    required this.onSnooze,
    required this.onSkip,
    this.emphasized = false,
  });

  final MedicationLog log;
  final bool processing;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(log.status);
    final medicine = log.medicine?.name ?? 'Thuốc';
    final unit = log.medicine?.unit ?? '';
    final amount = log.dosagePerTime;
    final dose = amount == null
        ? null
        : '${amount == amount.roundToDouble() ? amount.toInt() : amount} $unit';
    final reminder = log.effectiveReminderAt;

    return Glass(
      padding: EdgeInsets.all(emphasized ? 18 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_time(reminder)}${dose == null ? '' : ' · $dose'}'
                      '${log.instructions == null ? '' : ' · ${log.instructions}'}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              StatusChip(log.status.label, color),
            ],
          ),
          if (log.status == DoseStatus.snoozed && log.snoozeUntil != null) ...[
            const SizedBox(height: 8),
            Text(
              'Chuông sẽ reo lại lúc ${_time(log.snoozeUntil!)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
          if (log.status == DoseStatus.skipped &&
              (log.skipReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text('Lý do: ${log.skipReason}'),
          ],
          if (log.status == DoseStatus.taken && log.actualTakenAt != null) ...[
            const SizedBox(height: 8),
            Text('Đã uống lúc ${_time(log.actualTakenAt!)}'),
          ],
          if (log.isOpen) ...[
            const SizedBox(height: 14),
            if (processing)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onTaken,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Đã uống'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.snooze_rounded),
                    label: const Text('Nhắc lại'),
                  ),
                  TextButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Bỏ qua'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  static Color _statusColor(DoseStatus status) => switch (status) {
    DoseStatus.scheduled => const Color(0xFF5065F2),
    DoseStatus.snoozed => const Color(0xFFF0A042),
    DoseStatus.taken => const Color(0xFF239E77),
    DoseStatus.skipped => const Color(0xFF8B6BC4),
    DoseStatus.missed => const Color(0xFFD65D4A),
  };
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(message, style: const TextStyle(color: Color(0xFFD65D4A))),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

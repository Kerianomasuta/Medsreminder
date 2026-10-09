import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/models/medication_log.dart';
import 'package:meds_reminder/services/notification_service.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);

  test(
    'only schedules open medication logs whose effective time is future',
    () {
      expect(
        shouldScheduleMedicationLog(
          _log(
            status: DoseStatus.scheduled,
            scheduledAt: now.add(const Duration(minutes: 1)),
          ),
          now,
        ),
        isTrue,
      );
      expect(
        shouldScheduleMedicationLog(
          _log(status: DoseStatus.scheduled, scheduledAt: now),
          now,
        ),
        isFalse,
      );
      expect(
        shouldScheduleMedicationLog(
          _log(
            status: DoseStatus.scheduled,
            scheduledAt: now.subtract(const Duration(hours: 4)),
          ),
          now,
        ),
        isFalse,
      );
      expect(
        shouldScheduleMedicationLog(
          _log(
            status: DoseStatus.taken,
            scheduledAt: now.add(const Duration(hours: 1)),
          ),
          now,
        ),
        isFalse,
      );
    },
  );

  test(
    'alarm uses the updated scheduledAt supplied by the regenerated log',
    () {
      final original = _log(
        status: DoseStatus.scheduled,
        scheduledAt: DateTime(2026, 10, 9, 8),
      );
      final updated = _log(
        status: DoseStatus.scheduled,
        scheduledAt: DateTime(2026, 10, 9, 20, 30),
      );

      expect(medicationAlarmTriggerAt(original), DateTime(2026, 10, 9, 8));
      expect(medicationAlarmTriggerAt(updated), DateTime(2026, 10, 9, 20, 30));
    },
  );

  test('snooze time takes priority over the scheduled dose time', () {
    final log = _log(
      status: DoseStatus.snoozed,
      scheduledAt: DateTime(2026, 10, 9, 8),
      snoozeUntil: DateTime(2026, 10, 9, 8, 10),
    );

    expect(medicationAlarmTriggerAt(log), DateTime(2026, 10, 9, 8, 10));
  });

  test('uses snoozeUntil as the effective reminder time', () {
    expect(
      shouldScheduleMedicationLog(
        _log(
          status: DoseStatus.snoozed,
          scheduledAt: now.subtract(const Duration(hours: 1)),
          snoozeUntil: now.add(const Duration(minutes: 5)),
        ),
        now,
      ),
      isTrue,
    );
    expect(
      shouldScheduleMedicationLog(
        _log(
          status: DoseStatus.snoozed,
          scheduledAt: now.subtract(const Duration(hours: 1)),
          snoozeUntil: now.subtract(const Duration(minutes: 1)),
        ),
        now,
      ),
      isFalse,
    );
  });
}

MedicationLog _log({
  required DoseStatus status,
  required DateTime scheduledAt,
  DateTime? snoozeUntil,
}) => MedicationLog(
  id: 'log-id',
  scheduleRuleId: 'rule-id',
  patientId: 'patient-id',
  scheduledAt: scheduledAt,
  status: status,
  snoozeUntil: snoozeUntil,
  escalationLevel: 0,
);

import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/models/schedule_rule.dart';
import 'package:meds_reminder/screens/caregiver/caregiver_home.dart';

ScheduleRule _fakeRule(String id, String reminderTime) => ScheduleRule(
  id: id,
  prescriptionItemId: 'item-$id',
  patientId: 'patient-1',
  reminderTime: reminderTime,
  daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
  isActive: true,
  dosagePerTime: 1.0,
  medicine: const ScheduleMedicine(id: 'm-1', name: 'Med', unit: 'VIEN'),
  prescription: const SchedulePrescription(
    id: 'p-1',
    title: 'Don',
    startDate: '2026-10-01',
    isActive: true,
  ),
);

void main() {
  group('selectOverviewSchedules', () {
    test('returns empty when rules list is empty', () {
      expect(selectOverviewSchedules([]), isEmpty);
    });

    test('returns all elements when total <= 4', () {
      final rules = [
        _fakeRule('1', '08:00'),
        _fakeRule('2', '12:00'),
        _fakeRule('3', '20:00'),
      ];
      final result = selectOverviewSchedules(rules);
      expect(result.map((r) => r.id).toList(), ['1', '2', '3']);
    });

    test('sorts rules and returns first 4 in early morning', () {
      final rules = [
        _fakeRule('3', '20:00'),
        _fakeRule('1', '08:00'),
        _fakeRule('4', '22:00'),
        _fakeRule('2', '12:00'),
        _fakeRule('5', '22:30'),
      ];
      final now = DateTime(2026, 10, 14, 7, 30);
      final result = selectOverviewSchedules(rules, now: now);
      expect(result.map((r) => r.id).toList(), ['1', '2', '3', '4']);
    });

    test('grace period: includes dose at 20:03 when current time is 20:04', () {
      final rules = [
        _fakeRule('1', '08:00'),
        _fakeRule('2', '12:00'),
        _fakeRule('3', '18:00'),
        _fakeRule('4', '20:03'),
        _fakeRule('5', '21:25'),
        _fakeRule('6', '22:13'),
        _fakeRule('7', '22:18'),
      ];
      final now = DateTime(2026, 10, 14, 20, 4);
      final result = selectOverviewSchedules(rules, now: now);
      expect(result.map((r) => r.reminderTime).toList(), [
        '20:03',
        '21:25',
        '22:13',
        '22:18',
      ]);
    });

    test('excludes dose older than 15 minutes', () {
      final rules = [
        _fakeRule('1', '08:00'),
        _fakeRule('2', '12:00'),
        _fakeRule('3', '19:40'),
        _fakeRule('4', '20:03'),
        _fakeRule('5', '21:25'),
        _fakeRule('6', '22:13'),
        _fakeRule('7', '22:18'),
      ];
      // At 20:00, threshold is 19:45 -> 19:40 is excluded
      final now = DateTime(2026, 10, 14, 20, 0);
      final result = selectOverviewSchedules(rules, now: now);
      expect(result.first.reminderTime, '20:03');
    });

    test(
      'end-of-day fallback: backfills to 4 when fewer than 4 upcoming remain',
      () {
        final rules = [
          _fakeRule('1', '08:00'),
          _fakeRule('2', '12:00'),
          _fakeRule('3', '18:00'),
          _fakeRule('4', '20:03'),
          _fakeRule('5', '21:25'),
          _fakeRule('6', '22:13'),
          _fakeRule('7', '22:52'),
        ];
        // At 22:30, only 22:52 remains -> backfills with 20:03, 21:25, 22:13, 22:52
        final now = DateTime(2026, 10, 14, 22, 30);
        final result = selectOverviewSchedules(rules, now: now);
        expect(result.map((r) => r.reminderTime).toList(), [
          '20:03',
          '21:25',
          '22:13',
          '22:52',
        ]);
      },
    );

    test('all passed fallback: returns last 4 doses of the day', () {
      final rules = [
        _fakeRule('1', '08:00'),
        _fakeRule('2', '12:00'),
        _fakeRule('3', '18:00'),
        _fakeRule('4', '20:03'),
        _fakeRule('5', '21:25'),
        _fakeRule('6', '22:13'),
        _fakeRule('7', '22:52'),
      ];
      // At 23:45, all doses passed
      final now = DateTime(2026, 10, 14, 23, 45);
      final result = selectOverviewSchedules(rules, now: now);
      expect(result.map((r) => r.reminderTime).toList(), [
        '20:03',
        '21:25',
        '22:13',
        '22:52',
      ]);
    });
  });
}

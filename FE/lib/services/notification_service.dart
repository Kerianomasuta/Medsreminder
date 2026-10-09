import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_log.dart';
import 'medication_logs_api.dart';

class SkipReasonRequest {
  const SkipReasonRequest({
    required this.medicationLogId,
    required this.notificationId,
  });

  final String medicationLogId;
  final int notificationId;
}

@visibleForTesting
bool shouldScheduleMedicationLog(MedicationLog log, DateTime now) =>
    log.isOpen && medicationAlarmTriggerAt(log).isAfter(now);

@visibleForTesting
DateTime medicationAlarmTriggerAt(MedicationLog log) => log.effectiveReminderAt;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final MedicationLogsApi _medicationLogsApi = MedicationLogsApi();
  static const MethodChannel _wakeChannel = MethodChannel(
    'com.medsreminder/wake_lock',
  );
  bool _isInitialized = false;
  bool _processingDoseActions = false;
  Future<void>? _refreshInFlight;
  final ValueNotifier<SkipReasonRequest?> skipReasonRequest = ValueNotifier(
    null,
  );

  static const String channelId = 'meds_reminder_channel';
  static const String channelName = 'Nhắc uống thuốc';
  static const String channelDesc =
      'Thông báo nhắc uống thuốc đúng cữ trên màn hình khóa';

  bool get _isSupported =>
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Bật sáng màn hình điện thoại (Đánh thức màn hình khóa)
  Future<void> turnScreenOn() async {
    if (!_isSupported) return;
    try {
      await _wakeChannel.invokeMethod('turnScreenOn');
    } catch (e) {
      debugPrint('turnScreenOn error: $e');
    }
  }

  /// Hiển thị thẻ nổi nhắc thuốc chuyên biệt trên màn hình khóa
  Future<void> showLockScreenReminder({
    required String medicineName,
    required String dosage,
    String? time,
  }) async {
    if (!_isSupported) return;
    try {
      await _wakeChannel.invokeMethod('showLockScreenReminder', {
        'medicineName': medicineName,
        'dosage': dosage,
        'time': time ?? '',
      });
    } catch (e) {
      debugPrint('showLockScreenReminder error: $e');
    }
  }

  /// Khởi tạo dịch vụ thông báo
  Future<void> init() async {
    if (_isInitialized) return;
    if (!_isSupported) {
      _isInitialized = true;
      return;
    }

    _wakeChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'doseActionQueued':
          await refreshUpcomingMedicationLogs();
          return;
        case 'openSkipReason':
          _publishSkipReasonRequest(call.arguments);
          return;
      }
    });

    if (Platform.isAndroid) {
      try {
        AndroidFlutterLocalNotificationsPlugin.registerWith();
      } catch (e) {
        debugPrint('registerWith error: $e');
      }
    }

    tz.initializeTimeZones();
    try {
      final String? timeZoneName = await _wakeChannel.invokeMethod<String>(
        'getTimeZoneName',
      );
      if (timeZoneName != null &&
          tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('NotificationService: Thiết lập TimeZone = $timeZoneName');
      } else {
        final offset = DateTime.now().timeZoneOffset;
        final matchedLoc = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == offset,
          orElse: () => tz.getLocation('Asia/Ho_Chi_Minh'),
        );
        tz.setLocalLocation(matchedLoc);
        debugPrint(
          'NotificationService: Fallback TimeZone = ${matchedLoc.name}',
        );
      }
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
      debugPrint('NotificationService: Timezone init fallback error: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Bấm vào thông báo: ${response.payload}');
        },
      );
    } catch (e) {
      debugPrint('Plugin initialize error: $e');
    }

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        // Tạo notification channel với độ ưu tiên cao nhất cho màn hình khóa
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}
      }
    }

    _isInitialized = true;
    await _consumePendingSkipReasonRequest();
  }

  /// Gửi các thao tác được bấm từ màn hình khóa lên backend. Native giữ queue
  /// cho tới khi Dart xác nhận từng action, nên mất mạng không làm mất dữ liệu.
  Future<void> processPendingDoseActions() async {
    if (!_isSupported || !Platform.isAndroid || _processingDoseActions) return;
    _processingDoseActions = true;
    try {
      final raw = await _wakeChannel.invokeMethod<List<dynamic>>(
        'peekPendingDoseActions',
      );
      for (final value in raw ?? const <dynamic>[]) {
        final action = Map<String, dynamic>.from(value as Map);
        final actionId = action['actionId']?.toString();
        final logId = action['logId']?.toString();
        final type = action['action']?.toString();
        if (actionId == null || logId == null || type == null) continue;
        try {
          final MedicationLog? updated = switch (type) {
            'taken' => await _medicationLogsApi.markTaken(logId),
            'snooze' => await _medicationLogsApi.snooze(
              logId,
              minutes: (action['minutes'] as num?)?.toInt() ?? 5,
            ),
            'skip' => await _medicationLogsApi.skip(
              logId,
              reason: action['reason']?.toString(),
            ),
            'missed' => await _medicationLogsApi.markMissed(logId),
            _ => null,
          };
          if (updated == null) continue;
          if (updated.isOpen) {
            await scheduleMedicationLog(updated);
          } else {
            await cancelMedicationLog(logId);
          }
          await _wakeChannel.invokeMethod<void>('ackPendingDoseAction', {
            'actionId': actionId,
          });
        } on MedicationLogsApiException catch (error) {
          // A final dose returns 400 for duplicate notification taps. Reconcile
          // by dropping that stale action; early MISSED stays queued to retry.
          final tooEarlyMiss =
              type == 'missed' &&
              error.statusCode == 400 &&
              error.message.contains('20 minutes');
          if (error.statusCode == 400 && !tooEarlyMiss) {
            await _wakeChannel.invokeMethod<void>('ackPendingDoseAction', {
              'actionId': actionId,
            });
          }
          if (tooEarlyMiss) {
            Future<void>.delayed(
              const Duration(minutes: 1),
              processPendingDoseActions,
            );
            break;
          }
        } catch (error) {
          debugPrint('Pending medication action failed: $error');
          break;
        }
      }
    } catch (error) {
      debugPrint('Could not process pending medication actions: $error');
    } finally {
      _processingDoseActions = false;
    }
  }

  Future<void> syncMedicationLogs(List<MedicationLog> logs) async {
    if (!_isSupported) return;
    await init();
    await cancelAll();
    final now = DateTime.now();
    for (final log in logs.where(
      (item) => shouldScheduleMedicationLog(item, now),
    )) {
      await scheduleMedicationLog(log);
    }
  }

  Future<void> refreshUpcomingMedicationLogs({bool force = false}) {
    if (!_isSupported) return Future.value();
    final current = _refreshInFlight;
    if (current != null) {
      if (!force) return current;
      return () async {
        await current;
        await refreshUpcomingMedicationLogs();
      }();
    }
    final refresh = _refreshUpcomingMedicationLogs();
    _refreshInFlight = refresh;
    refresh.whenComplete(() => _refreshInFlight = null);
    return refresh;
  }

  Future<void> _refreshUpcomingMedicationLogs() async {
    try {
      await processPendingDoseActions();
      final logs = await _medicationLogsApi.list(from: DateTime.now());
      await syncMedicationLogs(logs);
    } catch (error) {
      debugPrint('Could not refresh upcoming medication alarms: $error');
    }
  }

  Future<void> scheduleMedicationLog(MedicationLog log) async {
    if (!_isSupported || !log.isOpen) return;
    await init();
    final reminderAt = medicationAlarmTriggerAt(log);
    if (!reminderAt.isAfter(DateTime.now())) return;
    final triggerAt = reminderAt;
    final medicine = log.medicine?.name ?? 'Đến giờ uống thuốc';
    final amount = log.dosagePerTime;
    final unit = log.medicine?.unit ?? '';
    final dose = amount == null
        ? (log.instructions ?? '')
        : '${amount == amount.roundToDouble() ? amount.toInt() : amount} $unit'
              '${log.instructions == null ? '' : ' · ${log.instructions}'}';
    final id = _notificationId(log.id);
    if (Platform.isAndroid) {
      await _wakeChannel.invokeMethod<void>('scheduleExactAlarm', {
        'id': id,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'medicineName': medicine,
        'dosage': dose,
        'time': _clock(reminderAt),
        'medicationLogId': log.id,
        'alarmRound': 1,
      });
    } else {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Đến giờ uống thuốc',
        body: '$medicine · $dose',
        scheduledDate: tz.TZDateTime.from(triggerAt, tz.local),
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: log.id,
      );
    }
  }

  Future<void> cancelMedicationLog(String logId) async {
    if (!_isSupported) return;
    final id = _notificationId(logId);
    await _plugin.cancel(id: id);
    if (Platform.isAndroid) {
      await _wakeChannel.invokeMethod<void>('cancelAlarm', {'id': id});
    }
  }

  Future<void> clearMedicationState() async {
    if (!_isSupported) return;
    skipReasonRequest.value = null;
    await cancelAll();
    if (Platform.isAndroid) {
      await _wakeChannel.invokeMethod<void>('clearPendingDoseActions');
    }
  }

  int _notificationId(String logId) => logId.hashCode.abs() % 1000000000;

  Future<void> submitSkipReason(
    SkipReasonRequest request,
    String reason,
  ) async {
    if (!_isSupported || !Platform.isAndroid) return;
    await _wakeChannel.invokeMethod<void>('submitSkipReason', {
      'medicationLogId': request.medicationLogId,
      'notificationId': request.notificationId,
      'reason': reason.trim(),
    });
  }

  void clearSkipReasonRequest(SkipReasonRequest request) {
    if (skipReasonRequest.value?.medicationLogId == request.medicationLogId) {
      skipReasonRequest.value = null;
    }
  }

  Future<void> _consumePendingSkipReasonRequest() async {
    if (!_isSupported || !Platform.isAndroid) return;
    try {
      final raw = await _wakeChannel.invokeMethod<Map<dynamic, dynamic>>(
        'consumePendingSkipRequest',
      );
      _publishSkipReasonRequest(raw);
    } catch (error) {
      debugPrint('Could not consume pending skip request: $error');
    }
  }

  void _publishSkipReasonRequest(Object? raw) {
    if (raw is! Map) return;
    final logId = raw['medicationLogId']?.toString() ?? '';
    final notificationId = (raw['notificationId'] as num?)?.toInt();
    if (logId.isEmpty || notificationId == null) return;
    skipReasonRequest.value = SkipReasonRequest(
      medicationLogId: logId,
      notificationId: notificationId,
    );
  }

  String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  /// Cấu hình chi tiết thông báo hiển thị trên màn hình khóa
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      // 👉 Hiển thị đầy đủ nội dung thẻ trên màn hình khóa
      visibility: NotificationVisibility.public,
      // 👉 Để false để hiển thị dạng THẺ trên màn hình khóa, không tự động bật bung app
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(''),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  /// Gửi ngay thông báo thử nghiệm
  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 9999,
    String? medicineName,
    String? dosage,
  }) async {
    if (!_isSupported) return;
    await init();
    await turnScreenOn();
    if (medicineName != null) {
      await showLockScreenReminder(
        medicineName: medicineName,
        dosage: dosage ?? '',
      );
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  /// Hủy tất cả thông báo và báo thức
  Future<void> cancelAll() async {
    if (!_isSupported) return;
    await _plugin.cancelAll();
    if (Platform.isAndroid) {
      try {
        await _wakeChannel.invokeMethod('cancelAllAlarms');
      } catch (e) {
        debugPrint('Lỗi cancelAllAlarms: $e');
      }
    }
  }
}

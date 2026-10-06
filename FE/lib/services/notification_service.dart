import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/schedule_rule.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const MethodChannel _wakeChannel = MethodChannel('com.medsreminder/wake_lock');
  bool _isInitialized = false;

  static const String channelId = 'meds_reminder_channel';
  static const String channelName = 'Nhắc uống thuốc';
  static const String channelDesc = 'Thông báo nhắc uống thuốc đúng cữ trên màn hình khóa';

  bool get _isSupported => !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

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

    if (Platform.isAndroid) {
      try {
        AndroidFlutterLocalNotificationsPlugin.registerWith();
      } catch (e) {
        debugPrint('registerWith error: $e');
      }
    }

    tz.initializeTimeZones();
    try {
      final String? timeZoneName = await _wakeChannel.invokeMethod<String>('getTimeZoneName');
      if (timeZoneName != null && tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('NotificationService: Thiết lập TimeZone = $timeZoneName');
      } else {
        final offset = DateTime.now().timeZoneOffset;
        final matchedLoc = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.getLocation('Asia/Ho_Chi_Minh'),
        );
        tz.setLocalLocation(matchedLoc);
        debugPrint('NotificationService: Fallback TimeZone = ${matchedLoc.name}');
      }
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
      debugPrint('NotificationService: Timezone init fallback error: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
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
  }

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
      await showLockScreenReminder(medicineName: medicineName, dosage: dosage ?? '');
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  /// Hẹn giờ báo thức cho một cữ thuốc cụ thể theo ScheduleRule
  Future<void> scheduleMedicationRule(ScheduleRule rule) async {
    if (!_isSupported || !rule.isActive) return;
    await init();

    final parts = rule.reminderTime.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = tz.TZDateTime.now(tz.local);

    // Lên lịch cho các thứ trong tuần
    for (final day in rule.daysOfWeek) {
      // 1 = Monday, ..., 7 = Sunday
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Điều chỉnh theo ngày trong tuần: nếu ngày đã qua trong tuần hoặc giờ đã qua hôm nay, nhảy sang tuần tới
      while (scheduledDate.weekday != day || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // ID duy nhất dựa trên rule ID hash và thứ
      final notifId = (rule.id.hashCode ^ (day * 100)).abs() % 100000;

      final title = '⏰ Đến giờ uống thuốc (${rule.period})';
      final drug = rule.medicine.name;
      final dose = '${rule.dosagePerTime.toInt()} ${rule.medicine.unit}'
          '${rule.instructions != null ? " · ${rule.instructions}" : ""}';

      if (Platform.isAndroid) {
        // Trên Android: Sử dụng Exact Alarm native để đánh thức máy, phát chuông lặp và mở màn hình khóa
        try {
          await _wakeChannel.invokeMethod('scheduleExactAlarm', {
            'id': notifId,
            'triggerAtMillis': scheduledDate.millisecondsSinceEpoch,
            'medicineName': drug,
            'dosage': dose,
            'time': rule.reminderTime,
          });
          debugPrint('Đã hẹn báo thức Android cho $drug lúc ${scheduledDate.toString()} (ID: $notifId)');
        } catch (e) {
          debugPrint('Lỗi hẹn báo thức exact alarm: $e');
        }
      } else {
        // Trên iOS hoặc nền tảng khác: Fallback qua FlutterLocalNotifications
        await _plugin.zonedSchedule(
          id: notifId,
          title: title,
          body: '$drug - $dose',
          scheduledDate: scheduledDate,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Đồng bộ toàn bộ danh sách cữ thuốc từ backend với báo thức điện thoại
  Future<void> syncAllSchedules(List<ScheduleRule> rules) async {
    if (!_isSupported) return;
    await init();

    // Hủy các lịch hẹn cũ để đồng bộ mới chính xác
    await cancelAll();

    for (final rule in rules) {
      if (rule.isActive) {
        await scheduleMedicationRule(rule);
      }
    }
    debugPrint('Đã đồng bộ ${rules.length} cữ thuốc vào hệ thống thông báo báo thức.');
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

package com.medsreminder.meds_reminder

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

class ReminderAlarmService : Service() {

    companion object {
        private const val TAG = "ReminderAlarmService"
        const val CHANNEL_ID = "meds_alarm_wake_channel"
        const val SNOOZE_CHANNEL_ID = "meds_snooze_channel"
        const val NOTIF_ID = 9998
        const val ACTION_STOP_ALARM = "STOP_ALARM"
        const val ACTION_SNOOZE = "SNOOZE_ALARM"
        const val ACTION_TAKEN = "TAKEN_ALARM"
        const val MAX_SNOOZE_COUNT = 5
        private const val SNOOZE_DELAY_MS = 5 * 60 * 1000L // 5 phút nhắc lại
        private const val AUTO_STOP_DELAY_MS = 180_000L // 3 phút tự tắt và chuyển sang nhắc lại
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var alarmPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val autoStopHandler = Handler(Looper.getMainLooper())

    private var currentMedicineName: String = "Đến giờ uống thuốc!"
    private var currentDosage: String = "Hãy uống thuốc đúng cữ"
    private var currentTime: String = ""
    private var currentNotifId: Int = NOTIF_ID
    private var currentSnoozeCount: Int = 0

    // Khi chuông reo đủ 3 phút mà người dùng không bấm gì -> Tự động chuyển sang Nhắc lại sau 5 phút
    private val autoStopRunnable = Runnable {
        Log.d(TAG, "Alarm auto-stopped after 3 minutes — auto snoozing for 5 minutes")
        executeSnooze()
    }

    @Suppress("DEPRECATION")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val receivedAction = intent?.action
        Log.d(TAG, "ReminderAlarmService onStartCommand: action=$receivedAction")

        val notifId = intent?.getIntExtra("notification_id", currentNotifId) ?: currentNotifId

        // 1. Người dùng bấm "✓ ĐÃ UỐNG" hoặc "Bỏ qua cữ này (Tắt hẳn)"
        if (receivedAction == ACTION_TAKEN || receivedAction == ACTION_STOP_ALARM) {
            Log.d(TAG, "Stop or Taken received — canceling all alarms and stopping service")
            stopAlarm()
            cancelPendingSnoozeAlarm(notifId)
            dismissNotification(notifId)
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        // 2. Người dùng chủ động bấm "⏰ Nhắc lại"
        if (receivedAction == ACTION_SNOOZE) {
            currentMedicineName = intent?.getStringExtra("medicine_name") ?: currentMedicineName
            currentDosage = intent?.getStringExtra("dosage") ?: currentDosage
            currentTime = intent?.getStringExtra("time") ?: currentTime
            currentNotifId = notifId
            currentSnoozeCount = intent?.getIntExtra("snooze_count", currentSnoozeCount) ?: currentSnoozeCount

            executeSnooze()
            return START_NOT_STICKY
        }

        // 3. Khởi động chuông báo thức mới hoặc lần reo tiếp theo của Snooze
        currentMedicineName = intent?.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        currentDosage = intent?.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        currentTime = intent?.getStringExtra("time") ?: ""
        currentNotifId = notifId
        currentSnoozeCount = intent?.getIntExtra("snooze_count", 0) ?: 0

        // Bật sáng màn hình ngay lập tức bằng WakeLock
        acquireWakeLock()

        // Tạo Notification Channels
        createNotificationChannels()

        // Intent mở Activity đè lên màn hình khóa
        val activityIntent = Intent(this, ReminderLockActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("medicine_name", currentMedicineName)
            putExtra("dosage", currentDosage)
            putExtra("time", currentTime)
            putExtra("notification_id", currentNotifId)
            putExtra("snooze_count", currentSnoozeCount)
        }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, currentNotifId, activityIntent, pendingFlags
        )

        // Intent: Tắt hẳn / Bỏ qua
        val stopIntent = Intent(this, ReminderAlarmService::class.java).apply {
            setAction(ACTION_STOP_ALARM)
            putExtra("notification_id", currentNotifId)
        }
        val stopPendingIntent = PendingIntent.getService(
            this, currentNotifId + 1, stopIntent, pendingFlags
        )

        // Intent: Nhắc lại (Snooze)
        val snoozeIntent = Intent(this, ReminderAlarmService::class.java).apply {
            setAction(ACTION_SNOOZE)
            putExtra("medicine_name", currentMedicineName)
            putExtra("dosage", currentDosage)
            putExtra("time", currentTime)
            putExtra("notification_id", currentNotifId)
            putExtra("snooze_count", currentSnoozeCount)
        }
        val snoozePendingIntent = PendingIntent.getService(
            this, currentNotifId + 2, snoozeIntent, pendingFlags
        )

        // Intent: Đã uống
        val takenIntent = Intent(this, ReminderAlarmService::class.java).apply {
            setAction(ACTION_TAKEN)
            putExtra("notification_id", currentNotifId)
        }
        val takenPendingIntent = PendingIntent.getService(
            this, currentNotifId + 3, takenIntent, pendingFlags
        )

        // Tiêu đề & nội dung notification
        val titleText = if (currentTime.isNotBlank()) "⏰ Đến giờ uống thuốc! ($currentTime)" else "⏰ Đến giờ uống thuốc!"
        val snoozeSuffix = if (currentSnoozeCount > 0) " (Nhắc lại lần $currentSnoozeCount/$MAX_SNOOZE_COUNT)" else ""
        val bodyText = "$currentMedicineName · $currentDosage$snoozeSuffix"

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(titleText)
            .setContentText(bodyText)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_input_add, "✓ ĐÃ UỐNG", takenPendingIntent)
            .addAction(android.R.drawable.ic_popup_reminder, "⏰ Nhắc lại (5p)", snoozePendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Tắt", stopPendingIntent)
            .build()

        startForeground(currentNotifId, notification)

        // Phát nhạc báo thức lặp liên tục & rung
        startAlarmSound()
        startVibration()

        // Mở ReminderLockActivity
        try {
            startActivity(activityIntent)
            Log.d(TAG, "ReminderLockActivity started from Service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start ReminderLockActivity from service", e)
        }

        // Hẹn giờ tự ngắt sau 3 phút nếu không tương tác -> Tự chuyển sang Snooze
        autoStopHandler.removeCallbacks(autoStopRunnable)
        autoStopHandler.postDelayed(autoStopRunnable, AUTO_STOP_DELAY_MS)

        return START_NOT_STICKY
    }

    private fun executeSnooze() {
        autoStopHandler.removeCallbacks(autoStopRunnable)
        stopAlarm()
        stopForeground(true)

        if (currentSnoozeCount < MAX_SNOOZE_COUNT) {
            val nextCount = currentSnoozeCount + 1
            val triggerAtMillis = System.currentTimeMillis() + SNOOZE_DELAY_MS

            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val snoozeIntent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.medsreminder.ALARM_TRIGGER"
                putExtra("medicine_name", currentMedicineName)
                putExtra("dosage", currentDosage)
                putExtra("time", currentTime)
                putExtra("notification_id", currentNotifId)
                putExtra("snooze_count", nextCount)
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getBroadcast(this, currentNotifId, snoozeIntent, flags)

            try {
                if (alarmManager != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent
                        )
                    }
                }
                Log.d(TAG, "Snoozed alarm $currentNotifId for 5 min (Count $nextCount/$MAX_SNOOZE_COUNT)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to schedule snooze alarm", e)
            }

            showSnoozedNotification(currentNotifId, currentMedicineName, nextCount)
        } else {
            Log.d(TAG, "Max snooze reached ($MAX_SNOOZE_COUNT times). Marking as missed.")
            showMissedNotification(currentNotifId, currentMedicineName, currentTime)
        }

        stopSelf()
    }

    private fun cancelPendingSnoozeAlarm(notifId: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.medsreminder.ALARM_TRIGGER"
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_NO_CREATE
            }
            val pendingIntent = PendingIntent.getBroadcast(this, notifId, intent, flags)
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
                Log.d(TAG, "Canceled pending snooze alarm for id $notifId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error canceling snooze alarm", e)
        }
    }

    private fun showSnoozedNotification(notifId: Int, medicineName: String, snoozeCount: Int) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val takenIntent = Intent(this, ReminderAlarmService::class.java).apply {
                setAction(ACTION_TAKEN)
                putExtra("notification_id", notifId)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val takenPendingIntent = PendingIntent.getService(this, notifId + 10, takenIntent, flags)

            val notification = NotificationCompat.Builder(this, SNOOZE_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_popup_reminder)
                .setContentTitle("⏰ Đã hoãn: Nhắc lại sau 5 phút ($snoozeCount/$MAX_SNOOZE_COUNT)")
                .setContentText("$medicineName · Chuông sẽ tự động reo lại")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .addAction(android.R.drawable.ic_input_add, "✓ Đã uống", takenPendingIntent)
                .build()

            nm.notify(notifId, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing snoozed notification", e)
        }
    }

    private fun showMissedNotification(notifId: Int, medicineName: String, time: String) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val timeText = if (time.isNotBlank()) " lúc $time" else ""
            val notification = NotificationCompat.Builder(this, SNOOZE_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_notify_error)
                .setContentTitle("⚠️ Đã bỏ lỡ cữ thuốc: $medicineName")
                .setContentText("Đã nhắc nhở 5 lần$timeText nhưng chưa có xác nhận uống.")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            nm.notify(notifId, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing missed notification", e)
        }
    }

    private fun dismissNotification(notifId: Int) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(notifId)
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing notification", e)
        }
    }

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "medsreminder:alarm_service_wake"
            )
            wakeLock?.acquire(AUTO_STOP_DELAY_MS)
            Log.d(TAG, "WakeLock acquired in ReminderAlarmService")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock", e)
        }
    }

    private fun startAlarmSound() {
        try {
            stopAlarmSound()
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            alarmPlayer = MediaPlayer().apply {
                setDataSource(this@ReminderAlarmService, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
            Log.d(TAG, "Alarm sound started (looping)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start alarm sound", e)
        }
    }

    private fun stopAlarmSound() {
        try {
            alarmPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            alarmPlayer = null
            Log.d(TAG, "Alarm sound stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping alarm sound", e)
        }
    }

    private fun startVibration() {
        try {
            stopVibration()
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            val pattern = longArrayOf(0, 1000, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
            Log.d(TAG, "Vibration started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start vibration", e)
        }
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
            vibrator = null
            Log.d(TAG, "Vibration stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping vibration", e)
        }
    }

    private fun stopAlarm() {
        autoStopHandler.removeCallbacks(autoStopRunnable)
        stopAlarmSound()
        stopVibration()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            // Kênh báo thức reo
            val alarmChannel = NotificationChannel(
                CHANNEL_ID,
                "Nhắc uống thuốc (Báo thức)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo chuông báo thức nhắc uống thuốc"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(false)
            }
            nm.createNotificationChannel(alarmChannel)

            // Kênh thông báo hoãn / bỏ lỡ
            val snoozeChannel = NotificationChannel(
                SNOOZE_CHANNEL_ID,
                "Trạng thái nhắc lại thuốc",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo trạng thái hoãn nhắc lại hoặc bỏ lỡ thuốc"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(snoozeChannel)
        }
    }

    override fun onDestroy() {
        stopAlarm()
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock", e)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

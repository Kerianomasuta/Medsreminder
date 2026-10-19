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
        const val ACTION_SKIP = "SKIP_ALARM"
        const val ACTION_OPEN_SKIP_REASON = "OPEN_SKIP_REASON"
        const val ALARM_ROUNDS = 2
        private const val ALARM_WINDOW_MS = 3 * 60 * 1000L
        private const val RETRY_INTERVAL_MS = 5 * 60 * 1000L

        @Volatile
        var currentInstance: ReminderAlarmService? = null
    }

    override fun onCreate() {
        super.onCreate()
        currentInstance = this
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
    private var currentMedicationLogId: String = ""
    private var currentAlarmRound: Int = 1

    // Mỗi đợt reo 3 phút. Nếu không phản hồi, 5 phút sau reo đợt 2 (tối đa 2 đợt). Hết đợt 2 thì ghi nhận MISSED.
    private val autoStopRunnable = Runnable {
        handleNoResponse()
    }

    @Suppress("DEPRECATION")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val receivedAction = intent?.action
        Log.d(TAG, "ReminderAlarmService onStartCommand: action=$receivedAction")

        val notifId = intent?.getIntExtra("notification_id", currentNotifId) ?: currentNotifId

        // Notification chỉ mở app để nhập lý do; chưa đánh dấu SKIPPED.
        if (receivedAction == ACTION_OPEN_SKIP_REASON) {
            val appIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("open_skip_reason", true)
                putExtra("medication_log_id", intent?.getStringExtra("medication_log_id") ?: "")
                putExtra("notification_id", notifId)
            }
            startActivity(appIntent)
            return START_NOT_STICKY
        }

        // 1. Người dùng bấm "Đã uống" hoặc "Bỏ qua".
        if (receivedAction == ACTION_TAKEN || receivedAction == ACTION_SKIP || receivedAction == ACTION_STOP_ALARM) {
            val logId = intent?.getStringExtra("medication_log_id") ?: currentMedicationLogId
            val prefs = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            if (logId.isNotBlank()) {
                editor.remove("snooze_$logId")
            }
            editor.remove("snooze_notif_$notifId").apply()
            val apiAction = if (receivedAction == ACTION_TAKEN) "taken" else "skip"
            val reason = intent?.getStringExtra("skip_reason")
            DoseActionQueue.enqueue(this, logId, apiAction, reason = reason)
            notifyFlutterOfQueuedAction()
            stopAlarm()
            ReminderLockActivity.closeIfOpen()
            cancelPendingSnoozeAlarm(notifId)
            dismissNotification(notifId)
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        // 2. Người dùng chủ động bấm "⏰ Nhắc lại" (Tối đa 1 lần)
        if (receivedAction == ACTION_SNOOZE) {
            stopAlarm()
            currentMedicineName = intent?.getStringExtra("medicine_name") ?: currentMedicineName
            currentDosage = intent?.getStringExtra("dosage") ?: currentDosage
            currentTime = intent?.getStringExtra("time") ?: currentTime
            currentNotifId = notifId
            currentMedicationLogId = intent?.getStringExtra("medication_log_id") ?: currentMedicationLogId
            val stateKey = if (currentMedicationLogId.isNotBlank()) "snooze_$currentMedicationLogId" else "snooze_notif_$currentNotifId"
            val prefs = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
            val savedSnooze = prefs.getInt(stateKey, 0)
            val incomingSnoozeCount = intent?.getIntExtra("snooze_count", 0) ?: 0
            val intentRound = intent?.getIntExtra("alarm_round", 1) ?: 1
            val minutes = intent?.getIntExtra("snooze_minutes", 5) ?: 5

            if (savedSnooze >= 1 || incomingSnoozeCount >= 1 || intentRound >= ALARM_ROUNDS) {
                Log.w(TAG, "Snooze rejected: maximum 1 snooze allowed")
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }

            prefs.edit().putInt(stateKey, 1).apply()
            currentSnoozeCount = 1
            DoseActionQueue.enqueue(this, currentMedicationLogId, "snooze", minutes)
            notifyFlutterOfQueuedAction()
            executeSnooze(minutes)
            return START_NOT_STICKY
        }

        // 3. Khởi động chuông báo thức mới hoặc lần reo tiếp theo của Snooze
        currentMedicineName = intent?.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        currentDosage = intent?.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        currentTime = intent?.getStringExtra("time") ?: ""
        currentNotifId = notifId
        currentMedicationLogId = intent?.getStringExtra("medication_log_id") ?: ""

        val stateKey = if (currentMedicationLogId.isNotBlank()) "snooze_$currentMedicationLogId" else "snooze_notif_$currentNotifId"
        val prefs = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
        val savedSnooze = prefs.getInt(stateKey, 0)
        currentSnoozeCount = maxOf(intent?.getIntExtra("snooze_count", 0) ?: 0, savedSnooze)
        val intentRound = intent?.getIntExtra("alarm_round", 1) ?: 1
        currentAlarmRound = if (currentSnoozeCount >= 1) 2 else intentRound

        // Bật sáng màn hình ngay lập tức bằng WakeLock
        acquireWakeLock()

        // Tạo Notification Channels
        createNotificationChannels()

        // Intent mở Activity đè lên màn hình khóa
        val isFinal = currentSnoozeCount >= 1 || currentAlarmRound >= ALARM_ROUNDS
        val activityIntent = Intent(this, ReminderLockActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra("medicine_name", currentMedicineName)
            putExtra("dosage", currentDosage)
            putExtra("time", currentTime)
            putExtra("notification_id", currentNotifId)
            putExtra("snooze_count", currentSnoozeCount)
            putExtra("medication_log_id", currentMedicationLogId)
            putExtra("alarm_round", if (isFinal) 2 else currentAlarmRound)
        }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, currentNotifId, activityIntent, pendingFlags
        )

        // Tiêu đề & nội dung notification
        val isLastRound = currentSnoozeCount >= 1 || currentAlarmRound >= ALARM_ROUNDS
        val titleText = if (currentTime.isNotBlank()) "⏰ Đến giờ uống thuốc! ($currentTime)" else "⏰ Đến giờ uống thuốc!"
        val snoozeSuffix = if (isLastRound) " (Lần nhắc cuối cùng)" else ""
        val bodyText = "$currentMedicineName · $currentDosage$snoozeSuffix"

        // Notification dạng banner hiển thị trên lockscreen, nhấn vào để mở màn hình ReminderLockActivity
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
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

        val notification = notificationBuilder.build()

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

        // Mỗi đợt chuông kéo dài tối đa 10 phút.
        autoStopHandler.removeCallbacks(autoStopRunnable)
        autoStopHandler.postDelayed(autoStopRunnable, ALARM_WINDOW_MS)

        return START_NOT_STICKY
    }

    private fun executeSnooze(minutes: Int) {
        autoStopHandler.removeCallbacks(autoStopRunnable)
        stopAlarm()
        ReminderLockActivity.closeIfOpen()
        dismissNotification(currentNotifId)
        stopForeground(true)

        val nextCount = 1
        val triggerAtMillis = System.currentTimeMillis() + minutes * 60 * 1000L

            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val snoozeIntent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.medsreminder.ALARM_TRIGGER"
                putExtra("medicine_name", currentMedicineName)
                putExtra("dosage", currentDosage)
                putExtra("time", currentTime)
                putExtra("notification_id", currentNotifId)
                putExtra("snooze_count", nextCount)
                putExtra("medication_log_id", currentMedicationLogId)
                putExtra("alarm_round", 2)
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
                Log.d(TAG, "Snoozed alarm $currentNotifId for $minutes min (Final Round)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to schedule snooze alarm", e)
            }

        // Tạm ẩn thẻ thông báo hoãn chuông (mở lại nếu sau này cần dùng đến):
        // showSnoozedNotification(currentNotifId, currentMedicineName, minutes)

        stopSelf()
    }

    private fun handleNoResponse() {
        stopAlarm()
        ReminderLockActivity.closeIfOpen()
        dismissNotification(currentNotifId)
        stopForeground(true)
        val stateKey = if (currentMedicationLogId.isNotBlank()) "snooze_$currentMedicationLogId" else "snooze_notif_$currentNotifId"
        val isLastRound = currentSnoozeCount >= 1 || currentAlarmRound >= ALARM_ROUNDS
        if (!isLastRound) {
            getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
                .edit().putInt(stateKey, 1).apply()
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val nextIntent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.medsreminder.ALARM_TRIGGER"
                putExtra("medicine_name", currentMedicineName)
                putExtra("dosage", currentDosage)
                putExtra("time", currentTime)
                putExtra("notification_id", currentNotifId)
                putExtra("snooze_count", 1)
                putExtra("medication_log_id", currentMedicationLogId)
                putExtra("alarm_round", 2)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                currentNotifId,
                nextIntent,
                flags
            )
            val triggerAt = System.currentTimeMillis() + RETRY_INTERVAL_MS
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            } else {
                alarmManager?.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
            // Tạm ẩn thẻ thông báo hoãn chuông (mở lại nếu sau này cần dùng đến):
            // showSnoozedNotification(currentNotifId, currentMedicineName, (RETRY_INTERVAL_MS / 60000L).toInt())
        } else {
            val editor = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE).edit()
            if (currentMedicationLogId.isNotBlank()) {
                editor.remove("snooze_$currentMedicationLogId")
            }
            editor.remove("snooze_notif_$currentNotifId").apply()
            // Backend tự đánh dấu MISSED sau 11 phút và gửi FCM cho người chăm sóc.
            showMissedNotification(currentNotifId, currentMedicineName, currentTime)
        }
        stopSelf()
    }

    private fun notifyFlutterOfQueuedAction() {
        try {
            val appIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("dose_action_queued", true)
            }
            startActivity(appIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Could not notify Flutter about dose action", e)
        }
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

    private fun showSnoozedNotification(notifId: Int, medicineName: String, minutes: Int) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val notification = NotificationCompat.Builder(this, SNOOZE_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_popup_reminder)
                .setContentTitle("⏰ Đã hoãn: Nhắc lại sau $minutes phút")
                .setContentText("$medicineName · Chuông sẽ tự động reo lại")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
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
                .setContentText("Đã nhắc hai đợt, mỗi đợt 3 phút$timeText nhưng chưa có phản hồi.")
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
            wakeLock?.acquire(ALARM_WINDOW_MS)
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

    fun stopAlarm() {
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
        if (currentInstance == this) {
            currentInstance = null
        }
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

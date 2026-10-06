package com.medsreminder.meds_reminder

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
        const val NOTIF_ID = 9998
        const val ACTION_STOP_ALARM = "STOP_ALARM"
        private const val AUTO_STOP_DELAY_MS = 180_000L // 3 phút tự tắt nếu không ai tương tác
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var alarmPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val autoStopHandler = Handler(Looper.getMainLooper())

    private val autoStopRunnable = Runnable {
        Log.d(TAG, "Alarm auto-stopped after timeout")
        stopAlarm()
        stopForeground(true)
        stopSelf()
    }

    @Suppress("DEPRECATION")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "ReminderAlarmService onStartCommand: action=${intent?.action}")

        // 1. Xử lý nút "Tắt báo thức" từ notification hoặc từ ReminderLockActivity
        if (intent?.action == ACTION_STOP_ALARM) {
            Log.d(TAG, "STOP_ALARM received — stopping alarm sound and service")
            stopAlarm()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        val medicineName = intent?.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        val dosage = intent?.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        val time = intent?.getStringExtra("time") ?: ""
        val notifId = intent?.getIntExtra("notification_id", NOTIF_ID) ?: NOTIF_ID

        // 2. Bật sáng màn hình ngay lập tức bằng WakeLock
        acquireWakeLock()

        // 3. Tạo Notification Channel độ ưu tiên cao nhất
        createNotificationChannel()

        // 4. Intent mở Activity đè lên màn hình khóa
        val activityIntent = Intent(this, ReminderLockActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("time", time)
        }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, notifId, activityIntent, pendingFlags
        )

        // 5. Intent cho nút "Tắt báo thức" trên thanh Notification
        val stopIntent = Intent(this, ReminderAlarmService::class.java).apply {
            action = ACTION_STOP_ALARM
        }
        val stopPendingIntent = PendingIntent.getService(
            this, notifId + 1, stopIntent, pendingFlags
        )

        // 6. Xây dựng Foreground Notification (có nút Tắt báo thức)
        val titleText = if (time.isNotBlank()) "⏰ Đến giờ uống thuốc! ($time)" else "⏰ Đến giờ uống thuốc!"
        val bodyText = "$medicineName · $dosage"

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
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Tắt báo thức", stopPendingIntent)
            .build()

        startForeground(notifId, notification)

        // 7. Phát nhạc báo thức lặp liên tục
        startAlarmSound()

        // 8. Rung liên tục theo nhịp
        startVibration()

        // 9. Mở ReminderLockActivity
        try {
            startActivity(activityIntent)
            Log.d(TAG, "ReminderLockActivity started from Service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start ReminderLockActivity from service", e)
        }

        // 10. Đặt hẹn giờ tự tắt sau 3 phút nếu không có thao tác
        autoStopHandler.removeCallbacks(autoStopRunnable)
        autoStopHandler.postDelayed(autoStopRunnable, AUTO_STOP_DELAY_MS)

        return START_NOT_STICKY
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Nhắc uống thuốc (Báo thức)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo chuông báo thức nhắc uống thuốc"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                // Tắt tiếng của channel để MediaPlayer phát chuông lặp riêng
                setSound(null, null)
                enableVibration(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
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

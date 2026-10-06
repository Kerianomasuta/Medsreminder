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
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class ReminderAlarmService : Service() {

    companion object {
        private const val TAG = "ReminderAlarmService"
        const val CHANNEL_ID = "meds_alarm_wake_channel"
        const val NOTIF_ID = 9998
        const val ACTION_STOP_ALARM = "STOP_ALARM"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var alarmPlayer: MediaPlayer? = null

    @Suppress("DEPRECATION")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "ReminderAlarmService onStartCommand: action=${intent?.action}")

        // Xử lý nút "Tắt báo thức" từ notification hoặc từ Activity
        if (intent?.action == ACTION_STOP_ALARM) {
            Log.d(TAG, "STOP_ALARM received — stopping sound and service")
            stopAlarmSound()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        val medicineName = intent?.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        val dosage = intent?.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"

        // 1. Acquire WakeLock — bật sáng màn hình ngay lập tức
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "medsreminder:alarm_service_wake"
            )
            wakeLock?.acquire(120_000L)
            Log.d(TAG, "WakeLock acquired in ReminderAlarmService")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock", e)
        }

        // 2. Tạo notification channel (không có âm thanh — MediaPlayer xử lý thay)
        createNotificationChannel()

        // 3. Intent mở ReminderLockActivity (fullScreenIntent)
        val activityIntent = Intent(this, ReminderLockActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
        }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, NOTIF_ID, activityIntent, pendingFlags
        )

        // 4. Intent Tắt báo thức cho nút action trên notification
        val stopIntent = Intent(this, ReminderAlarmService::class.java).apply {
            action = ACTION_STOP_ALARM
        }
        val stopPendingIntent = PendingIntent.getService(
            this, NOTIF_ID + 1, stopIntent, pendingFlags
        )

        // 5. Build foreground notification với nút "Tắt báo thức"
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("⏰ Đến giờ uống thuốc!")
            .setContentText(medicineName)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setAutoCancel(false)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_delete, "Tắt báo thức", stopPendingIntent)
            .build()

        // 6. Start foreground
        startForeground(NOTIF_ID, notification)

        // 7. Phát nhạc báo thức lặp liên tục trong Service
        startAlarmSound()

        // 8. Mở ReminderLockActivity (nếu được phép)
        try {
            startActivity(activityIntent)
            Log.d(TAG, "ReminderLockActivity started from Service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start ReminderLockActivity from service", e)
        }

        return START_NOT_STICKY
    }

    private fun startAlarmSound() {
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Nhắc uống thuốc (Wake)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo bật màn hình nhắc uống thuốc"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                // Tắt âm thanh của notification channel — MediaPlayer xử lý thay
                setSound(null, null)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopAlarmSound()
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

package com.medsreminder.meds_reminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class ReminderAlarmService : Service() {

    companion object {
        private const val TAG = "ReminderAlarmService"
        const val CHANNEL_ID = "meds_alarm_wake_channel"
        const val NOTIF_ID = 9998
    }

    private var wakeLock: PowerManager.WakeLock? = null

    @Suppress("DEPRECATION")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "ReminderAlarmService onStartCommand")

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
            wakeLock?.acquire(60_000L)
            Log.d(TAG, "WakeLock acquired in ReminderAlarmService")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock", e)
        }

        // 2. Tạo notification channel
        createNotificationChannel()

        // 3. Intent để mở ReminderLockActivity
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

        // 4. Build foreground notification với fullScreenIntent
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
            .build()

        // 5. Start foreground (Service context được phép bật màn hình)
        startForeground(NOTIF_ID, notification)

        // 6. Mở ReminderLockActivity trực tiếp từ Service context
        try {
            startActivity(activityIntent)
            Log.d(TAG, "ReminderLockActivity started from Service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start ReminderLockActivity from service", e)
        }

        // 7. Tự stop service sau 5 giây (Activity đã hiện rồi)
        Handler(Looper.getMainLooper()).postDelayed({
            stopSelf()
        }, 5000)

        return START_NOT_STICKY
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
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
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

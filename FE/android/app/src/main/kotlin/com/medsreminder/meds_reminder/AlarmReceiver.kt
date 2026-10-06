package com.medsreminder.meds_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val medicineName = intent.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        val dosage = intent.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        val time = intent.getStringExtra("time") ?: ""
        val notifId = intent.getIntExtra("notification_id", 9998)
        val triggerAtMillis = intent.getLongExtra("trigger_at_millis", 0L)

        Log.d(TAG, "AlarmReceiver triggered for $medicineName at $time (id=$notifId)")

        // 1. Khởi động ReminderAlarmService để bật màn hình, phát nhạc lặp và hiện notification
        val serviceIntent = Intent(context, ReminderAlarmService::class.java).apply {
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("time", time)
            putExtra("notification_id", notifId)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting ReminderAlarmService from AlarmReceiver", e)
        }

        // 2. Tự động lên lịch lại cho 7 ngày sau (để duy trì lặp hàng tuần kể cả không mở app)
        if (triggerAtMillis > 0L) {
            val nextWeekMillis = triggerAtMillis + 7L * 24 * 60 * 60 * 1000L
            rescheduleNextWeek(context, intent, notifId, nextWeekMillis)
        }
    }

    private fun rescheduleNextWeek(
        context: Context,
        originalIntent: Intent,
        notifId: Int,
        nextTriggerMillis: Long
    ) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val repeatIntent = Intent(context, AlarmReceiver::class.java).apply {
                action = "com.medsreminder.ALARM_TRIGGER"
                putExtras(originalIntent)
                putExtra("trigger_at_millis", nextTriggerMillis)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(context, notifId, repeatIntent, flags)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    nextTriggerMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    nextTriggerMillis,
                    pendingIntent
                )
            }
            Log.d(TAG, "Rescheduled alarm $notifId for next week at $nextTriggerMillis")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reschedule alarm for next week", e)
        }
    }
}

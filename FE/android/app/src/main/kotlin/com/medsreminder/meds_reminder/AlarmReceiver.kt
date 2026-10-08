package com.medsreminder.meds_reminder

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
        val snoozeCount = intent.getIntExtra("snooze_count", 0)
        val medicationLogId = intent.getStringExtra("medication_log_id") ?: ""
        val alarmRound = intent.getIntExtra("alarm_round", 1)

        Log.d(TAG, "AlarmReceiver triggered for $medicineName at $time (id=$notifId, snoozeCount=$snoozeCount)")

        // 1. Khởi động ReminderAlarmService để bật màn hình, phát nhạc lặp và hiện notification
        val serviceIntent = Intent(context, ReminderAlarmService::class.java).apply {
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("time", time)
            putExtra("notification_id", notifId)
            putExtra("snooze_count", snoozeCount)
            putExtra("medication_log_id", medicationLogId)
            putExtra("alarm_round", alarmRound)
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

    }
}

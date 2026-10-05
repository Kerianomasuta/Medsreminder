package com.dexterous.flutterlocalnotifications

import android.app.Notification
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationManagerCompat
import com.dexterous.flutterlocalnotifications.models.NotificationDetails
import com.dexterous.flutterlocalnotifications.utils.StringUtils
import com.google.gson.reflect.TypeToken
import java.lang.reflect.Type

@Keep
class ScheduledNotificationReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ScheduledNotifReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive triggered")

        val notificationDetailsJson = intent.getStringExtra(FlutterLocalNotificationsPlugin.NOTIFICATION_DETAILS)
        var medicineName = "Đến giờ uống thuốc!"
        var dosage = "Hãy uống thuốc đúng cữ"

        if (StringUtils.isNullOrEmpty(notificationDetailsJson)) {
            // Legacy path: notification object in intent
            val notificationId = intent.getIntExtra("notification_id", 0)
            val notification: Notification? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra("notification", Notification::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra("notification")
            }

            if (notification == null) {
                FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, notificationId)
                Log.e(TAG, "Failed to parse notification from Intent. ID: $notificationId")
                return
            }

            notification.`when` = System.currentTimeMillis()
            val notificationManager = NotificationManagerCompat.from(context)
            notificationManager.notify(notificationId, notification)

            val repeat = intent.getBooleanExtra("repeat", false)
            if (!repeat) {
                FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, notificationId)
            }

            medicineName = notification.extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: medicineName
            dosage = notification.extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: dosage
        } else {
            val gson = FlutterLocalNotificationsPlugin.buildGson()
            val type: Type = object : TypeToken<NotificationDetails>() {}.type
            val notificationDetails: NotificationDetails = gson.fromJson(notificationDetailsJson, type)

            FlutterLocalNotificationsPlugin.showNotification(context, notificationDetails)
            FlutterLocalNotificationsPlugin.scheduleNextNotification(context, notificationDetails)

            medicineName = notificationDetails.title ?: medicineName
            dosage = notificationDetails.body ?: dosage
        }

        // Khởi động ReminderAlarmService (ForegroundService) để bật màn hình đáng tin cậy
        try {
            val serviceIntent = Intent(
                context,
                com.medsreminder.meds_reminder.ReminderAlarmService::class.java
            ).apply {
                putExtra("medicine_name", medicineName)
                putExtra("dosage", dosage)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "ReminderAlarmService started for: $medicineName")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting ReminderAlarmService", e)
        }
    }
}

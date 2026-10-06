package com.medsreminder.meds_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.medsreminder/wake_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "turnScreenOn" -> {
                    wakeUpScreen()
                    result.success(true)
                }
                "getTimeZoneName" -> {
                    val tzId = java.util.TimeZone.getDefault().id
                    result.success(tzId)
                }
                "showLockScreenReminder" -> {
                    val med = call.argument<String>("medicineName") ?: "Paracetamol 500mg"
                    val dose = call.argument<String>("dosage") ?: "1 viên · Sau khi ăn"
                    val time = call.argument<String>("time") ?: ""
                    val serviceIntent = Intent(this, ReminderAlarmService::class.java).apply {
                        putExtra("medicine_name", med)
                        putExtra("dosage", dose)
                        putExtra("time", time)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "scheduleExactAlarm" -> {
                    val id = call.argument<Int>("id") ?: 9998
                    val triggerAtMillis = call.argument<Number>("triggerAtMillis")?.toLong() ?: 0L
                    val med = call.argument<String>("medicineName") ?: "Paracetamol 500mg"
                    val dose = call.argument<String>("dosage") ?: "1 viên · Sau khi ăn"
                    val time = call.argument<String>("time") ?: ""
                    scheduleExactAlarm(id, triggerAtMillis, med, dose, time)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 9998
                    cancelAlarm(id)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    cancelAllAlarms()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scheduleExactAlarm(
        id: Int,
        triggerAtMillis: Long,
        medicineName: String,
        dosage: String,
        time: String
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.medsreminder.ALARM_TRIGGER"
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("time", time)
            putExtra("notification_id", id)
            putExtra("trigger_at_millis", triggerAtMillis)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(this, id, intent, flags)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
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
            saveAlarmId(id)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun cancelAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.medsreminder.ALARM_TRIGGER"
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_NO_CREATE
        }
        val pendingIntent = PendingIntent.getBroadcast(this, id, intent, flags)
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
        removeAlarmId(id)
    }

    private fun saveAlarmId(id: Int) {
        val prefs = getSharedPreferences("meds_alarms", Context.MODE_PRIVATE)
        val set = prefs.getStringSet("scheduled_ids", HashSet())?.toMutableSet() ?: mutableSetOf()
        set.add(id.toString())
        prefs.edit().putStringSet("scheduled_ids", set).apply()
    }

    private fun removeAlarmId(id: Int) {
        val prefs = getSharedPreferences("meds_alarms", Context.MODE_PRIVATE)
        val set = prefs.getStringSet("scheduled_ids", HashSet())?.toMutableSet() ?: mutableSetOf()
        set.remove(id.toString())
        prefs.edit().putStringSet("scheduled_ids", set).apply()
    }

    private fun cancelAllAlarms() {
        val prefs = getSharedPreferences("meds_alarms", Context.MODE_PRIVATE)
        val set = prefs.getStringSet("scheduled_ids", HashSet()) ?: emptySet()
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        for (idStr in set) {
            val id = idStr.toIntOrNull() ?: continue
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.medsreminder.ALARM_TRIGGER"
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_NO_CREATE
            }
            val pendingIntent = PendingIntent.getBroadcast(this, id, intent, flags)
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        }
        prefs.edit().remove("scheduled_ids").apply()
    }

    private fun wakeUpScreen() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
        @Suppress("DEPRECATION")
        val wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
            "medsreminder:wake_screen"
        )
        wakeLock.acquire(5000)
    }
}

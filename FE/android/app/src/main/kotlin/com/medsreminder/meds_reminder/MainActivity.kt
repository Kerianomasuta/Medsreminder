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
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.medsreminder/wake_lock"
    private val AUTH_CHANNEL = "com.medsreminder/auth_session"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
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
                    val medicationLogId = call.argument<String>("medicationLogId") ?: ""
                    val alarmRound = call.argument<Int>("alarmRound") ?: 1
                    scheduleExactAlarm(id, triggerAtMillis, med, dose, time, medicationLogId, alarmRound)
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
                "peekPendingDoseActions" -> {
                    result.success(DoseActionQueue.peek(this))
                }
                "ackPendingDoseAction" -> {
                    val actionId = call.argument<String>("actionId") ?: ""
                    DoseActionQueue.acknowledge(this, actionId)
                    result.success(true)
                }
                "clearPendingDoseActions" -> {
                    DoseActionQueue.clear(this)
                    result.success(true)
                }
                "consumePendingSkipRequest" -> {
                    result.success(consumePendingSkipRequest(intent))
                }
                "submitSkipReason" -> {
                    val medicationLogId = call.argument<String>("medicationLogId") ?: ""
                    val notificationId = call.argument<Int>("notificationId") ?: ReminderAlarmService.NOTIF_ID
                    val reason = call.argument<String>("reason")
                    val skipIntent = Intent(this, ReminderAlarmService::class.java).apply {
                        action = ReminderAlarmService.ACTION_SKIP
                        putExtra("notification_id", notificationId)
                        putExtra("medication_log_id", medicationLogId)
                        if (!reason.isNullOrBlank()) putExtra("skip_reason", reason.take(500))
                    }
                    startService(skipIntent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = encryptedAuthPreferences()
                when (call.method) {
                    "restoreTokens" -> result.success(
                        mapOf(
                            "accessToken" to prefs.getString("accessToken", null),
                            "refreshToken" to prefs.getString("refreshToken", null)
                        ).filterValues { it != null }
                    )
                    "saveTokens" -> {
                        prefs.edit().apply {
                            call.argument<String>("accessToken")?.let {
                                putString("accessToken", it)
                            }
                            call.argument<String>("refreshToken")?.let {
                                putString("refreshToken", it)
                            }
                        }.apply()
                        result.success(true)
                    }
                    "clearTokens" -> {
                        prefs.edit().clear().apply()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("dose_action_queued", false)) {
            methodChannel?.invokeMethod("doseActionQueued", null)
        }
        consumePendingSkipRequest(intent)?.let {
            methodChannel?.invokeMethod("openSkipReason", it)
        }
    }

    private fun consumePendingSkipRequest(source: Intent?): Map<String, Any>? {
        if (source?.getBooleanExtra("open_skip_reason", false) != true) return null
        val medicationLogId = source.getStringExtra("medication_log_id") ?: return null
        val notificationId = source.getIntExtra(
            "notification_id",
            ReminderAlarmService.NOTIF_ID
        )
        source.removeExtra("open_skip_reason")
        source.removeExtra("medication_log_id")
        source.removeExtra("notification_id")
        return mapOf(
            "medicationLogId" to medicationLogId,
            "notificationId" to notificationId
        )
    }

    private fun encryptedAuthPreferences() = EncryptedSharedPreferences.create(
        this,
        "meds_auth_session",
        MasterKey.Builder(this)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private fun scheduleExactAlarm(
        id: Int,
        triggerAtMillis: Long,
        medicineName: String,
        dosage: String,
        time: String,
        medicationLogId: String,
        alarmRound: Int
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.medsreminder.ALARM_TRIGGER"
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("time", time)
            putExtra("notification_id", id)
            putExtra("trigger_at_millis", triggerAtMillis)
            putExtra("medication_log_id", medicationLogId)
            putExtra("alarm_round", alarmRound)
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

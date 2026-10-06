package com.medsreminder.meds_reminder

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
                    // Khởi động ReminderAlarmService — service sẽ phát nhạc lặp
                    // và tự mở ReminderLockActivity bên trong
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
                else -> {
                    result.notImplemented()
                }
            }
        }
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

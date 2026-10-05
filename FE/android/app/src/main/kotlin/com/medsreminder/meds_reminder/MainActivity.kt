package com.medsreminder.meds_reminder

import android.content.Context
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
                    val intent = android.content.Intent(this, ReminderLockActivity::class.java).apply {
                        flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("medicine_name", med)
                        putExtra("dosage", dose)
                        putExtra("time", time)
                    }
                    startActivity(intent)
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

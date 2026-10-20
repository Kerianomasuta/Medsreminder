package com.medsreminder.meds_reminder

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ReminderLockActivity : Activity() {

    companion object {
        @Volatile
        var currentInstance: ReminderLockActivity? = null

        fun closeIfOpen() {
            try {
                currentInstance?.let { activity ->
                    if (!activity.isFinishing) {
                        activity.finish()
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private val autoCloseHandler = Handler(Looper.getMainLooper())
    private val autoCloseRunnable = Runnable {
        if (!isFinishing) {
            finish()
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    private var medicineName: String = "Đến giờ uống thuốc!"
    private var dosage: String = "Hãy uống thuốc đúng cữ"
    private var time: String = ""
    private var notifId: Int = ReminderAlarmService.NOTIF_ID
    private var snoozeCount: Int = 0
    private var medicationLogId: String = ""
    private var alarmRound: Int = 1

    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        currentInstance = this
        autoCloseHandler.removeCallbacks(autoCloseRunnable)
        autoCloseHandler.postDelayed(autoCloseRunnable, 3 * 60 * 1000L)

        // 1. Kích hoạt màn hình và hiển thị đè lên màn hình khóa (GIỮ NGUYÊN MÀN HÌNH KHÓA)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        // 2. WakeLock dự phòng để đảm bảo màn hình sáng trong suốt 3 phút của đợt reo
        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "medsreminder:reminder_activity_wake"
            )
            wakeLock?.acquire(3 * 60 * 1000L)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        setContentView(R.layout.activity_reminder_lock)

        // 3. Nhận dữ liệu cữ thuốc từ Intent
        displayReminder(intent)

        val btnTaken = findViewById<Button>(R.id.btnTaken)
        val btnSnooze = findViewById<Button>(R.id.btnSnooze)
        val btnDismiss = findViewById<TextView>(R.id.btnDismiss)

        // 4. Nút "✓ ĐÃ UỐNG" — Tắt hẳn chuông và dừng mọi nhắc lại
        btnTaken.setOnClickListener {
            ReminderAlarmService.currentInstance?.stopAlarm()
            val prefs = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            if (medicationLogId.isNotBlank()) {
                editor.remove("snooze_$medicationLogId")
            }
            editor.remove("snooze_notif_$notifId").apply()
            sendStopAction(ReminderAlarmService.ACTION_TAKEN)
            Toast.makeText(this, "✓ Đã ghi nhận cữ uống thuốc!", Toast.LENGTH_SHORT).show()
            finish()
        }

        // 5. Nút "⏰ Nhắc lại" — Tắt chuông hiện tại, hẹn 5 phút sau reo lại (tối đa 1 lần)
        btnSnooze.setOnClickListener {
            val stateKey = if (medicationLogId.isNotBlank()) "snooze_$medicationLogId" else "snooze_notif_$notifId"
            val prefs = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
            val savedSnooze = prefs.getInt(stateKey, 0)
            val effectiveSnoozeCount = maxOf(snoozeCount, savedSnooze)
            if (effectiveSnoozeCount >= 1 || alarmRound >= ReminderAlarmService.ALARM_ROUNDS) {
                btnSnooze.visibility = View.GONE
                Toast.makeText(this, "Đã hết số lần nhắc lại!", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            btnSnooze.isEnabled = false
            btnSnooze.visibility = View.GONE
            ReminderAlarmService.currentInstance?.stopAlarm()
            sendSnoozeService(5)
            Toast.makeText(this, "⏰ Sẽ nhắc lại sau 5 phút!", Toast.LENGTH_SHORT).show()
            finish()
        }

        // 6. Nút "Bỏ qua cữ này (Tắt hẳn)"
        btnDismiss.setOnClickListener {
            showSkipReasonDialog()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        displayReminder(intent)
    }

    private fun displayReminder(source: Intent) {
        medicineName = source.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        dosage = source.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        time = source.getStringExtra("time") ?: currentTime
        notifId = source.getIntExtra("notification_id", ReminderAlarmService.NOTIF_ID)
        snoozeCount = source.getIntExtra("snooze_count", 0)
        medicationLogId = source.getStringExtra("medication_log_id") ?: ""
        alarmRound = source.getIntExtra("alarm_round", 1)

        val stateKey = if (medicationLogId.isNotBlank()) "snooze_$medicationLogId" else "snooze_notif_$notifId"
        val prefs = getSharedPreferences("meds_alarm_state", Context.MODE_PRIVATE)
        val savedSnooze = prefs.getInt(stateKey, 0)
        val effectiveSnoozeCount = maxOf(snoozeCount, savedSnooze)

        findViewById<TextView>(R.id.tvReminderTime).text = time
        findViewById<TextView>(R.id.tvMedicineName).text = medicineName
        findViewById<TextView>(R.id.tvDosageInstructions).text = dosage

        val isLastRound = effectiveSnoozeCount >= 1 || alarmRound >= ReminderAlarmService.ALARM_ROUNDS
        findViewById<TextView>(R.id.tvSnoozeInfo).apply {
            if (isLastRound) {
                visibility = View.VISIBLE
                text = "⏰ Lần nhắc cuối cùng"
            } else {
                visibility = View.GONE
            }
        }

        findViewById<Button>(R.id.btnSnooze).apply {
            visibility = if (isLastRound) View.GONE else View.VISIBLE
            isEnabled = !isLastRound
        }
    }

    private fun sendSnoozeService(minutes: Int) {
        try {
            ReminderAlarmService.currentInstance?.stopAlarm()
            val snoozeIntent = Intent(this, ReminderAlarmService::class.java).apply {
                action = ReminderAlarmService.ACTION_SNOOZE
                putExtra("medicine_name", medicineName)
                putExtra("dosage", dosage)
                putExtra("time", time)
                putExtra("notification_id", notifId)
                putExtra("snooze_count", snoozeCount)
                putExtra("snooze_minutes", minutes)
                putExtra("medication_log_id", medicationLogId)
                putExtra("alarm_round", alarmRound)
            }
            startService(snoozeIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showSkipReasonDialog() {
        val input = EditText(this).apply {
            hint = "Ví dụ: Buồn nôn (không bắt buộc)"
            maxLines = 3
        }
        AlertDialog.Builder(this)
            .setTitle("Bỏ qua cữ thuốc")
            .setView(input)
            .setNegativeButton("Hủy", null)
            .setPositiveButton("Xác nhận") { _, _ ->
                sendStopAction(ReminderAlarmService.ACTION_SKIP, input.text.toString())
                Toast.makeText(this, "Đã bỏ qua cữ thuốc", Toast.LENGTH_SHORT).show()
                finish()
            }
            .show()
    }

    private fun sendStopAction(actionType: String, reason: String? = null) {
        try {
            ReminderAlarmService.currentInstance?.stopAlarm()
            val stopIntent = Intent(this, ReminderAlarmService::class.java).apply {
                action = actionType
                putExtra("notification_id", notifId)
                putExtra("medication_log_id", medicationLogId)
                if (!reason.isNullOrBlank()) putExtra("skip_reason", reason.take(500))
            }
            startService(stopIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        autoCloseHandler.removeCallbacks(autoCloseRunnable)
        if (currentInstance == this) {
            currentInstance = null
        }
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        super.onDestroy()
    }
}

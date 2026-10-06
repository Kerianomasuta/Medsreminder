package com.medsreminder.meds_reminder

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ReminderLockActivity : Activity() {

    private val autoDismissHandler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null

    private var medicineName: String = "Đến giờ uống thuốc!"
    private var dosage: String = "Hãy uống thuốc đúng cữ"
    private var time: String = ""
    private var notifId: Int = ReminderAlarmService.NOTIF_ID
    private var snoozeCount: Int = 0

    // Nếu người dùng không chạm vào màn hình trong 3 phút -> Tự động hoãn nhắc lại sau 5 phút
    private val autoDismissRunnable = Runnable {
        if (!isFinishing) {
            sendSnoozeService()
            finish()
        }
    }

    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

        // 2. WakeLock dự phòng để đảm bảo màn hình sáng
        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "medsreminder:reminder_activity_wake"
            )
            wakeLock?.acquire(180_000L)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        setContentView(R.layout.activity_reminder_lock)

        // 3. Nhận dữ liệu cữ thuốc từ Intent
        medicineName = intent.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        dosage = intent.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        time = intent.getStringExtra("time") ?: currentTime
        notifId = intent.getIntExtra("notification_id", ReminderAlarmService.NOTIF_ID)
        snoozeCount = intent.getIntExtra("snooze_count", 0)

        val tvReminderTime = findViewById<TextView>(R.id.tvReminderTime)
        val tvMedicineName = findViewById<TextView>(R.id.tvMedicineName)
        val tvDosageInstructions = findViewById<TextView>(R.id.tvDosageInstructions)
        val tvSnoozeInfo = findViewById<TextView>(R.id.tvSnoozeInfo)
        val btnTaken = findViewById<Button>(R.id.btnTaken)
        val btnSnooze = findViewById<Button>(R.id.btnSnooze)
        val btnDismiss = findViewById<TextView>(R.id.btnDismiss)

        tvReminderTime.text = time
        tvMedicineName.text = medicineName
        tvDosageInstructions.text = dosage

        if (snoozeCount > 0) {
            tvSnoozeInfo.visibility = View.VISIBLE
            tvSnoozeInfo.text = "⏰ Nhắc lại lần $snoozeCount/${ReminderAlarmService.MAX_SNOOZE_COUNT}"
        } else {
            tvSnoozeInfo.visibility = View.GONE
        }

        // 4. Nút "✓ ĐÃ UỐNG" — Tắt hẳn chuông và dừng mọi nhắc lại
        btnTaken.setOnClickListener {
            sendStopAction(ReminderAlarmService.ACTION_TAKEN)
            Toast.makeText(this, "✓ Đã ghi nhận cữ uống thuốc!", Toast.LENGTH_SHORT).show()
            finish()
        }

        // 5. Nút "⏰ Nhắc lại (5p)" — Tắt chuông hiện tại, hẹn 5 phút sau reo lại
        btnSnooze.setOnClickListener {
            sendSnoozeService()
            Toast.makeText(this, "⏰ Sẽ nhắc lại sau 5 phút!", Toast.LENGTH_SHORT).show()
            finish()
        }

        // 6. Nút "Bỏ qua cữ này (Tắt hẳn)"
        btnDismiss.setOnClickListener {
            sendStopAction(ReminderAlarmService.ACTION_STOP_ALARM)
            Toast.makeText(this, "Đã bỏ qua cữ thuốc", Toast.LENGTH_SHORT).show()
            finish()
        }

        // 7. Tự động chuyển sang Snooze sau 3 phút nếu không thao tác
        autoDismissHandler.postDelayed(autoDismissRunnable, 180_000L)
    }

    private fun sendSnoozeService() {
        try {
            val snoozeIntent = Intent(this, ReminderAlarmService::class.java).apply {
                action = ReminderAlarmService.ACTION_SNOOZE
                putExtra("medicine_name", medicineName)
                putExtra("dosage", dosage)
                putExtra("time", time)
                putExtra("notification_id", notifId)
                putExtra("snooze_count", snoozeCount)
            }
            startService(snoozeIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendStopAction(actionType: String) {
        try {
            val stopIntent = Intent(this, ReminderAlarmService::class.java).apply {
                action = actionType
                putExtra("notification_id", notifId)
            }
            startService(stopIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        autoDismissHandler.removeCallbacks(autoDismissRunnable)
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

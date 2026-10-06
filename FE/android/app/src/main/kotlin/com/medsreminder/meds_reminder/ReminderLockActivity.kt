package com.medsreminder.meds_reminder

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
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

    private val autoDismissRunnable = Runnable {
        if (!isFinishing) {
            finish()
        }
    }

    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Kích hoạt màn hình và hiển thị đè lên màn hình khóa
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // Thêm FLAG_KEEP_SCREEN_ON để màn hình không tắt
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        // 2. WakeLock dự phòng để đảm bảo màn hình sáng
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "medsreminder:reminder_activity_wake"
            )
            wakeLock?.acquire(60000L) // giữ sáng 60 giây
        } catch (e: Exception) {
            e.printStackTrace()
        }

        setContentView(R.layout.activity_reminder_lock)

        // 3. Nhận dữ liệu cữ thuốc từ Intent
        val medicineName = intent.getStringExtra("medicine_name") ?: "Đến giờ uống thuốc!"
        val dosage = intent.getStringExtra("dosage") ?: "Hãy uống thuốc đúng cữ"
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        val time = intent.getStringExtra("time") ?: currentTime

        val tvReminderTime = findViewById<TextView>(R.id.tvReminderTime)
        val tvMedicineName = findViewById<TextView>(R.id.tvMedicineName)
        val tvDosageInstructions = findViewById<TextView>(R.id.tvDosageInstructions)
        val btnTaken = findViewById<Button>(R.id.btnTaken)
        val btnDismiss = findViewById<Button>(R.id.btnDismiss)

        tvReminderTime.text = time
        tvMedicineName.text = medicineName
        tvDosageInstructions.text = dosage

        // 4. Xử lý nút bấm
        btnTaken.setOnClickListener {
            Toast.makeText(this, "✓ Đã ghi nhận cữ uống thuốc!", Toast.LENGTH_SHORT).show()
            finish()
        }

        btnDismiss.setOnClickListener {
            finish()
        }

        // 5. Tự động đóng sau 60 giây nếu người dùng không thao tác
        autoDismissHandler.postDelayed(autoDismissRunnable, 60000)
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

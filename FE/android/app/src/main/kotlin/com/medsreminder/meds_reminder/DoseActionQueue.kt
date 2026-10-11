package com.medsreminder.meds_reminder

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

object DoseActionQueue {
    private const val PREFS = "meds_dose_actions"
    private const val KEY = "pending_actions"

    @Synchronized
    fun enqueue(
        context: Context,
        logId: String,
        action: String,
        minutes: Int? = null,
        reason: String? = null
    ) {
        if (logId.isBlank()) return
        val items = read(context)
        items.put(JSONObject().apply {
            put("actionId", UUID.randomUUID().toString())
            put("logId", logId)
            put("action", action)
            put("createdAt", System.currentTimeMillis())
            if (minutes != null) put("minutes", minutes)
            if (!reason.isNullOrBlank()) put("reason", reason.trim())
        })
        write(context, items)
    }

    @Synchronized
    fun peek(context: Context): List<Map<String, Any?>> {
        val items = read(context)
        return (0 until items.length()).mapNotNull { index ->
            val item = items.optJSONObject(index) ?: return@mapNotNull null
            buildMap {
                put("actionId", item.optString("actionId"))
                put("logId", item.optString("logId"))
                put("action", item.optString("action"))
                put("createdAt", item.optLong("createdAt"))
                if (item.has("minutes")) put("minutes", item.optInt("minutes"))
                if (item.has("reason")) put("reason", item.optString("reason"))
            }
        }
    }

    @Synchronized
    fun acknowledge(context: Context, actionId: String) {
        val source = read(context)
        val kept = JSONArray()
        for (index in 0 until source.length()) {
            val item = source.optJSONObject(index) ?: continue
            if (item.optString("actionId") != actionId) kept.put(item)
        }
        write(context, kept)
    }

    @Synchronized
    fun clear(context: Context) {
        write(context, JSONArray())
    }

    private fun read(context: Context): JSONArray {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, "[]") ?: "[]"
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    private fun write(context: Context, value: JSONArray) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY, value.toString())
            .apply()
    }
}

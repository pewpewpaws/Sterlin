package com.example.planner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.SizeF
import android.appwidget.AppWidgetProvider
import android.widget.RemoteViews

class TimetableWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "HomeWidgetPreferences"
        const val ACTION_PREV_DAY = "com.example.planner.ACTION_PREV_DAY"
        const val ACTION_NEXT_DAY = "com.example.planner.ACTION_NEXT_DAY"

        private val DAY_NAMES = arrayOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

            fun updateAllWidgets(context: Context) {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(ComponentName(context, TimetableWidgetProvider::class.java))
                if (ids.isNotEmpty()) {
                    val provider = TimetableWidgetProvider()
                    provider.onUpdate(context, mgr, ids)
                    mgr.notifyAppWidgetViewDataChanged(ids, R.id.widget_flipper)
                }
            }

            fun setVectorIcon(context: Context, views: RemoteViews, viewId: Int, vectorResId: Int) {
                try {
                    val vectorDrawable = context.getDrawable(vectorResId)
                    if (vectorDrawable != null) {
                        val bitmap = android.graphics.Bitmap.createBitmap(
                            Math.max(1, vectorDrawable.intrinsicWidth),
                            Math.max(1, vectorDrawable.intrinsicHeight),
                            android.graphics.Bitmap.Config.ARGB_8888
                        )
                        val canvas = android.graphics.Canvas(bitmap)
                        vectorDrawable.setBounds(0, 0, canvas.width, canvas.height)
                        vectorDrawable.draw(canvas)
                        views.setImageViewBitmap(viewId, bitmap)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("TimetableWidget", "Error setting vector icon: $e")
                }
            }
        }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == ACTION_PREV_DAY || action == ACTION_NEXT_DAY) {
            val prefNames = listOf(PREFS_NAME, "FlutterSharedPreferences", "${context.packageName}_preferences")
            var currentDay = -1
            var maxDays = 5

            for (name in prefNames) {
                val p = context.getSharedPreferences(name, Context.MODE_PRIVATE)
                
                // Read maxDays from profile_json if available
                if (maxDays == 5) {
                    val profileJsonStr = p.getString("profile_json", null) ?: p.getString("flutter.profile_json", null)
                    if (!profileJsonStr.isNullOrEmpty()) {
                        try {
                            val profObj = org.json.JSONObject(profileJsonStr)
                            if (profObj.has("timetable")) {
                                val ttArray = profObj.getJSONArray("timetable")
                                maxDays = Math.max(5, Math.min(ttArray.length(), 7))
                            }
                        } catch (e: Exception) {}
                    }
                }

                if (p.contains("widget_selected_day") || p.contains("flutter.widget_selected_day")) {
                    currentDay = p.getInt("widget_selected_day", p.getInt("flutter.widget_selected_day", -1))
                }
            }

            if (currentDay == -1) {
                val nowWeekday = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_WEEK)
                currentDay = if (nowWeekday == java.util.Calendar.SATURDAY && maxDays < 6 || nowWeekday == java.util.Calendar.SUNDAY && maxDays < 7) 0 else (nowWeekday - 2 + 7) % 7
                if (currentDay >= maxDays) currentDay = 0
            }

            val newDay = if (action == ACTION_PREV_DAY) {
                (currentDay - 1 + maxDays) % maxDays
            } else {
                (currentDay + 1) % maxDays
            }

            for (name in prefNames) {
                val p = context.getSharedPreferences(name, Context.MODE_PRIVATE)
                p.edit().putInt("widget_selected_day", newDay).apply()
            }

            updateAllWidgets(context)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        buildViews(context, appWidgetManager, appWidgetId)
        // Force list items to re-bind with new widget height so card sizes update immediately
        if (newOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) >= 200) {
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_flipper)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { id -> buildViews(context, appWidgetManager, id) }
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        // Read selected day index
        val prefNames = listOf(PREFS_NAME, "FlutterSharedPreferences", "${context.packageName}_preferences")
        var selectedDay = -1
        var maxDays = 5

        for (name in prefNames) {
            val p = context.getSharedPreferences(name, Context.MODE_PRIVATE)
            if (maxDays == 5) {
                val profileJsonStr = p.getString("profile_json", null) ?: p.getString("flutter.profile_json", null)
                if (!profileJsonStr.isNullOrEmpty()) {
                    try {
                        val profObj = org.json.JSONObject(profileJsonStr)
                        if (profObj.has("timetable")) {
                            val ttArray = profObj.getJSONArray("timetable")
                            maxDays = Math.max(5, Math.min(ttArray.length(), 7))
                        }
                    } catch (e: Exception) {}
                }
            }
            if (p.contains("widget_selected_day") || p.contains("flutter.widget_selected_day")) {
                selectedDay = p.getInt("widget_selected_day", p.getInt("flutter.widget_selected_day", -1))
            }
        }
        if (selectedDay < 0 || selectedDay >= maxDays) {
            val nowWeekday = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_WEEK)
            selectedDay = if (nowWeekday == java.util.Calendar.SATURDAY && maxDays < 6 || nowWeekday == java.util.Calendar.SUNDAY && maxDays < 7) 0 else (nowWeekday - 2 + 7) % 7
            if (selectedDay >= maxDays) selectedDay = 0
        }

        // Build three variants: ultra-compact (2x2), medium (4x2), full (4x4)
        val tinyViews = buildTinyRemoteViews(context, widgetId)
        val mediumViews = buildRemoteViews(context, widgetId, R.layout.widget_layout_4x2, selectedDay)
        val fullViews = buildRemoteViews(context, widgetId, R.layout.widget_layout, selectedDay)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Responsive: pick variant by min cell footprint
            val viewMapping: Map<SizeF, RemoteViews> = mapOf(
                SizeF(110f, 110f) to tinyViews,
                SizeF(250f, 110f) to mediumViews,
                SizeF(250f, 250f) to fullViews
            )
            manager.updateAppWidget(widgetId, RemoteViews(viewMapping))
            // Tiny (2x2) has no list, so only notify the list when we use a list layout
            appWidgetManagerNotifyList(manager, widgetId)
        } else {
            // Android < 12 fallback: read min dims and pick a single layout
            val opts = manager.getAppWidgetOptions(widgetId)
            val minWidth = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 220)
            val minHeight = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140)
            val chosen = when {
                minWidth < 200 || minHeight < 200 -> tinyViews
                minHeight < 200 -> mediumViews
                else -> fullViews
            }
            manager.updateAppWidget(widgetId, chosen)
            if (chosen !== tinyViews) {
                appWidgetManagerNotifyList(manager, widgetId)
            }
        }
    }

    private fun appWidgetManagerNotifyList(manager: AppWidgetManager, widgetId: Int) {
        try {
            manager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_flipper)
        } catch (_: Exception) {}
    }

    private fun buildRemoteViews(
        context: Context,
        widgetId: Int,
        layoutId: Int,
        selectedDay: Int
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)

        views.setTextViewText(R.id.txt_day_name, DAY_NAMES[selectedDay])

        setVectorIcon(context, views, R.id.btn_prev_day, R.drawable.ic_chevron_left)
        setVectorIcon(context, views, R.id.btn_next_day, R.drawable.ic_chevron_right)

        // Prev Day Button PendingIntent
        val prevIntent = Intent(context, TimetableWidgetProvider::class.java).apply {
            action = ACTION_PREV_DAY
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            context, 101, prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_prev_day, prevPendingIntent)

        // Next Day Button PendingIntent
        val nextIntent = Intent(context, TimetableWidgetProvider::class.java).apply {
            action = ACTION_NEXT_DAY
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context, 102, nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_next_day, nextPendingIntent)

        // RemoteViewsAdapter intent pointing to TimetableWidgetService
        val serviceIntent = Intent(context, TimetableWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }

        views.setRemoteAdapter(R.id.widget_flipper, serviceIntent)
        views.setEmptyView(R.id.widget_flipper, R.id.widget_empty_view)

        // Open App PendingIntent for clicking cards or header title
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val clickPendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_flipper, clickPendingIntent)
        views.setOnClickPendingIntent(R.id.header_title_pill, clickPendingIntent)
        views.setOnClickPendingIntent(R.id.widget_empty_view, clickPendingIntent)

        return views
    }

    /**
     * Ultra-compact 2x2 layout: shows the next class + attendance %.
     * No day nav, no list — reads first item from timetable_json directly.
     * If user is not logged in (per the `etlab_is_logged_in` flag), shows
     * a sign-in prompt instead of stale/empty timetable data.
     */
    private fun buildTinyRemoteViews(
        context: Context,
        widgetId: Int
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_layout_2x2)

        // Read logged-in flag + first item from timetable_json
        val prefNames = listOf(PREFS_NAME, "FlutterSharedPreferences", "${context.packageName}_preferences")
        var timetableJsonStr: String? = null
        var isLoggedIn = false

        for (name in prefNames) {
            val p = context.getSharedPreferences(name, Context.MODE_PRIVATE)
            if (timetableJsonStr.isNullOrEmpty()) {
                timetableJsonStr = p.getString("timetable_json", null) ?: p.getString("flutter.timetable_json", null)
            }
            if (!isLoggedIn) {
                isLoggedIn = p.getBoolean("etlab_is_logged_in", false) ||
                              p.getBoolean("flutter.etlab_is_logged_in", false)
            }
        }

        var courseName = "Free day"
        var timeStr = ""
        var pct = -1

        try {
            if (!timetableJsonStr.isNullOrEmpty()) {
                val arr = org.json.JSONArray(timetableJsonStr)
                if (arr.length() > 0) {
                    val first = arr.getJSONObject(0)
                    courseName = first.optString("courseName", courseName)
                    timeStr = first.optString("timeStr", timeStr)
                    pct = first.optInt("attendancePct", -1)
                }
            }
        } catch (_: Exception) {}

        if (!isLoggedIn) {
            // Not signed in — prompt the user instead of showing stale/empty data.
            views.setTextViewText(R.id.item_course, "Sign in to Sterlin")
            views.setTextViewText(R.id.item_time_period, "Tap to open app")
            views.setViewVisibility(R.id.item_attendance_container, android.view.View.GONE)
            views.setTextViewText(R.id.header_title_pill, "Sterlin")
        } else if (timeStr.isEmpty()) {
            // Logged in but no class data (free day or first launch).
            views.setTextViewText(R.id.item_course, courseName)
            views.setTextViewText(R.id.item_time_period, "Open app to refresh")
            if (pct >= 0) {
                views.setProgressBar(R.id.item_attendance_progress, 100, pct, false)
                views.setTextViewText(R.id.item_attendance_pct, "$pct%")
                views.setViewVisibility(R.id.item_attendance_container, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.item_attendance_container, android.view.View.GONE)
            }
        } else {
            views.setTextViewText(R.id.item_course, courseName)
            views.setTextViewText(R.id.item_time_period, timeStr)
            if (pct >= 0) {
                views.setProgressBar(R.id.item_attendance_progress, 100, pct, false)
                views.setTextViewText(R.id.item_attendance_pct, "$pct%")
                views.setViewVisibility(R.id.item_attendance_container, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.item_attendance_container, android.view.View.GONE)
            }
        }

        // Open App PendingIntent
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val clickPendingIntent = PendingIntent.getActivity(
            context, widgetId, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(android.R.id.background, clickPendingIntent)
        views.setOnClickPendingIntent(R.id.item_course, clickPendingIntent)
        views.setOnClickPendingIntent(R.id.header_title_pill, clickPendingIntent)

        return views
    }
}

package com.example.planner.widgets

import com.example.planner.R
import com.example.planner.MainActivity

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
                
                if (maxDays == 5) {
                    val value = p.all["widget_max_days"] ?: p.all["flutter.widget_max_days"]
                    if (value is Number) {
                        maxDays = value.toInt()
                    }
                }

                if (p.contains("widget_selected_day") || p.contains("flutter.widget_selected_day")) {
                    val value = p.all["widget_selected_day"] ?: p.all["flutter.widget_selected_day"]
                    currentDay = (value as? Number)?.toInt() ?: -1
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
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_flipper)
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
                val value = p.all["widget_max_days"] ?: p.all["flutter.widget_max_days"]
                if (value is Number) {
                    maxDays = value.toInt()
                }
            }
            if (p.contains("widget_selected_day") || p.contains("flutter.widget_selected_day")) {
                val value = p.all["widget_selected_day"] ?: p.all["flutter.widget_selected_day"]
                selectedDay = (value as? Number)?.toInt() ?: -1
            }
        }
        if (selectedDay < 0 || selectedDay >= maxDays) {
            val nowWeekday = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_WEEK)
            selectedDay = if (nowWeekday == java.util.Calendar.SATURDAY && maxDays < 6 || nowWeekday == java.util.Calendar.SUNDAY && maxDays < 7) 0 else (nowWeekday - 2 + 7) % 7
            if (selectedDay >= maxDays) selectedDay = 0
        }

        // Build variants: medium (4x2), full (4x4)
        val mediumViews = buildRemoteViews(context, widgetId, R.layout.widget_layout_4x2, selectedDay)
        val fullViews = buildRemoteViews(context, widgetId, R.layout.widget_layout, selectedDay)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Responsive: pick variant by min cell footprint
            val viewMapping: Map<SizeF, RemoteViews> = mapOf(
                SizeF(250f, 110f) to mediumViews,
                SizeF(250f, 250f) to fullViews
            )
            manager.updateAppWidget(widgetId, RemoteViews(viewMapping))
            appWidgetManagerNotifyList(manager, widgetId)
        } else {
            // Android < 12 fallback: read min dims and pick a single layout
            val opts = manager.getAppWidgetOptions(widgetId)
            val minHeight = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140)
            val chosen = when {
                minHeight < 200 -> mediumViews
                else -> fullViews
            }
            manager.updateAppWidget(widgetId, chosen)
            appWidgetManagerNotifyList(manager, widgetId)
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

        val prefNames = listOf(PREFS_NAME, "FlutterSharedPreferences", "${context.packageName}_preferences")
        var isLoggedIn = false
        for (name in prefNames) {
            val p = context.getSharedPreferences(name, Context.MODE_PRIVATE)
            if (!isLoggedIn) {
                isLoggedIn = p.getBoolean("etlab_is_logged_in", false) || p.getBoolean("flutter.etlab_is_logged_in", false)
            }
        }

        if (!isLoggedIn) {
            views.setTextViewText(R.id.empty_message, "Sign in to Sterlin")
            views.setTextViewText(R.id.empty_sub, "Tap to open app")
        } else {
            views.setTextViewText(R.id.empty_message, "No classes scheduled")
            views.setTextViewText(R.id.empty_sub, "Free day! \uD83C\uDF89")
        }

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

        // Apply user-chosen accent color to header pills without losing corner radius
        val accentColor = readAccentColor(context)
        if (accentColor != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(
                    R.id.header_title_pill,
                    "setBackgroundTintList",
                    android.content.res.ColorStateList.valueOf(accentColor)
                )
                views.setColorStateList(
                    R.id.header_day_pill,
                    "setBackgroundTintList",
                    android.content.res.ColorStateList.valueOf(accentColor)
                )
            }
        }

        return views
    }

    /** Read the accent color stored by Flutter's ThemeService / HomeWidgetService.
     *  Flutter SharedPreferences stores ints as Long on Android — must NOT use getInt(). */
    private fun readAccentColor(context: Context): Int? {
        val prefNames = listOf(PREFS_NAME, "FlutterSharedPreferences", "${context.packageName}_preferences")
        for (name in prefNames) {
            val p = context.getSharedPreferences(name, Context.MODE_PRIVATE)
            for (key in listOf("app_theme_widget_accent", "flutter.app_theme_widget_accent")) {
                val raw = p.all[key] ?: continue
                val color = when (raw) {
                    is Int -> raw
                    is Long -> raw.toInt()
                    else -> continue
                }
                if (color != 0) return color
            }
        }
        return null
    }

}

package com.example.planner

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class TimetableWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val appWidgetId = intent.getIntExtra(
            android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID,
            android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID
        )
        return TimetableViewsFactory(this.applicationContext, appWidgetId)
    }
}

class TimetableViewsFactory(private val context: Context, private val appWidgetId: Int) : RemoteViewsService.RemoteViewsFactory {

    private var items = ArrayList<JSONObject>()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    private fun loadData() {
        items.clear()
        val prefNames = listOf(
            "HomeWidgetPreferences",
            "FlutterSharedPreferences",
            "${context.packageName}_preferences"
        )

        var profileJsonStr: String? = null
        var attendanceJsonStr: String? = null
        var teachersJsonStr: String? = null
        var timetableJsonStr: String? = null
        var selectedDayIndex = -1

        for (name in prefNames) {
            val prefs = context.getSharedPreferences(name, Context.MODE_PRIVATE)
            if (profileJsonStr.isNullOrEmpty()) {
                profileJsonStr = prefs.getString("profile_json", null) ?: prefs.getString("flutter.profile_json", null)
            }
            if (attendanceJsonStr.isNullOrEmpty()) {
                attendanceJsonStr = prefs.getString("attendance_json", null) ?: prefs.getString("flutter.attendance_json", null)
            }
            if (teachersJsonStr.isNullOrEmpty()) {
                teachersJsonStr = prefs.getString("teachers_json", null) ?: prefs.getString("flutter.teachers_json", null)
            }
            if (timetableJsonStr.isNullOrEmpty()) {
                timetableJsonStr = prefs.getString("timetable_json", null) ?: prefs.getString("flutter.timetable_json", null)
            }
            if (selectedDayIndex == -1) {
                selectedDayIndex = prefs.getInt("widget_selected_day", prefs.getInt("flutter.widget_selected_day", -1))
            }
        }

        if (selectedDayIndex < 0 || selectedDayIndex > 4) {
            val nowWeekday = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_WEEK)
            selectedDayIndex = (nowWeekday - 2 + 5) % 5
        }

        // Code to Subject Name mapping & PE subject lookup
        val codeToName = HashMap<String, String>()
        var peSubjectCode: String? = null

        try {
            if (!attendanceJsonStr.isNullOrEmpty()) {
                val attObj = JSONObject(attendanceJsonStr)
                if (attObj.has("subjects")) {
                    val subArray = attObj.getJSONArray("subjects")
                    for (i in 0 until subArray.length()) {
                        val sub = subArray.getJSONObject(i)
                        val code = sub.optString("code", "").trim()
                        val name = sub.optString("subject", code).trim()
                        if (code.isNotEmpty()) {
                            codeToName[code.uppercase()] = name
                            if (code.uppercase().startsWith("PE")) {
                                peSubjectCode = code
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("TimetableWidget", "Error parsing attendance JSON: $e")
        }

        // Code to Teacher mapping
        val subjectToTeacher = HashMap<String, String>()
        try {
            if (!teachersJsonStr.isNullOrEmpty()) {
                val teachObj = JSONObject(teachersJsonStr)
                if (teachObj.has("sub_teacher")) {
                    val teachArray = teachObj.getJSONArray("sub_teacher")
                    for (i in 0 until teachArray.length()) {
                        val t = teachArray.getJSONObject(i)
                        val rawSubj = t.optString("t_subject", "").trim()
                        val name = t.optString("t_name", "").trim()
                        if (rawSubj.isNotEmpty() && name.isNotEmpty()) {
                            val parts = rawSubj.split(" - ")
                            val codePart = parts[0].trim().uppercase()
                            subjectToTeacher[codePart] = name
                            if (parts.size > 1) {
                                val namePart = parts.subList(1, parts.size).joinToString(" - ").trim().uppercase()
                                subjectToTeacher[namePart] = name
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("TimetableWidget", "Error parsing teachers JSON: $e")
        }

        // Attendance stats mapping (courseId -> pct & ratio)
        val attendanceStats = HashMap<String, Pair<Int, String>>()
        try {
            if (!attendanceJsonStr.isNullOrEmpty()) {
                val attObj = JSONObject(attendanceJsonStr)
                if (attObj.has("subjects")) {
                    val subArray = attObj.getJSONArray("subjects")
                    for (i in 0 until subArray.length()) {
                        val sub = subArray.getJSONObject(i)
                        val code = sub.optString("code", "").uppercase().trim()
                        val attendedStr = sub.optString("class_attended", "0")
                        val totalStr = sub.optString("total_classes", "0")
                        val attended = attendedStr.toIntOrNull() ?: 0
                        val total = totalStr.toIntOrNull() ?: 0
                        val pct = if (total > 0) ((attended.toDouble() / total.toDouble()) * 100).toInt() else 100
                        attendanceStats[code] = Pair(pct, "$attended/$total")
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("TimetableWidget", "Error parsing attendance stats: $e")
        }

        // Parse profile_json for full timetable day
        try {
            if (!profileJsonStr.isNullOrEmpty()) {
                val profObj = JSONObject(profileJsonStr)
                if (profObj.has("timetable")) {
                    val ttArray = profObj.getJSONArray("timetable")
                    if (selectedDayIndex < ttArray.length()) {
                        val dayPeriods = ttArray.getJSONArray(selectedDayIndex)
                        for (i in 0 until dayPeriods.length()) {
                            val period = dayPeriods.getJSONObject(i)
                            var subjectCode = period.optString("subject", "").trim()
                            val typeRaw = period.optString("type", "TH").trim()
                            var timeStr = period.optString("timeperiod", "").trim()

                            if (subjectCode == "Free Period" || typeRaw == "FR" || timeStr.isEmpty()) {
                                continue
                            }
                            
                            // Friday 4th and 5th hour overrides
                            if (selectedDayIndex == 4) {
                                if (i == 3) {
                                    timeStr = "2:00 PM - 3:00 PM"
                                } else if (i == 4) {
                                    timeStr = "3:00 PM - 4:00 PM"
                                }
                            }

                            if (subjectCode.uppercase() == "BT404" && peSubjectCode != null) {
                                subjectCode = peSubjectCode
                            }

                            val courseNameOnly = codeToName[subjectCode.uppercase()] ?: subjectCode
                            val fullCourseTitle = if (subjectCode.isNotEmpty()) "$courseNameOnly ($subjectCode)" else courseNameOnly

                            var sessionType = "Lecture"
                            if (typeRaw == "PR") sessionType = "Lab"
                            if (typeRaw == "TU") sessionType = "Tutorial"

                            val isLab = sessionType == "Lab" || subjectCode.uppercase().contains("LAB") || courseNameOnly.uppercase().contains("LAB")

                            var teacherName = ""
                            if (!isLab) {
                                val rawTeacher = period.optString("teacher", "").trim()
                                val cleanTeacher = if (rawTeacher.uppercase() == "NA" || rawTeacher.uppercase() == "N/A") "" else rawTeacher
                                teacherName = subjectToTeacher[subjectCode.uppercase()]
                                    ?: subjectToTeacher[courseNameOnly.uppercase()]
                                    ?: cleanTeacher
                            }

                            val room = period.optString("room", "").trim()
                            val timeRoomStr = if (room.isNotEmpty()) "$timeStr | $room" else timeStr

                            val stats = attendanceStats[subjectCode.uppercase()]
                            val pct = stats?.first ?: -1
                            val ratio = stats?.second ?: ""

                            val item = JSONObject().apply {
                                put("courseName", fullCourseTitle)
                                put("timeStr", timeRoomStr)
                                put("sessionType", sessionType)
                                put("teacherName", teacherName)
                                put("attendancePct", pct)
                                put("attendanceRatio", ratio)
                            }
                            items.add(item)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("TimetableWidget", "Error parsing profile timetable: $e")
        }

        // Fallback to timetableJsonStr if items is empty
        if (items.isEmpty() && !timetableJsonStr.isNullOrEmpty()) {
            try {
                val array = JSONArray(timetableJsonStr)
                for (i in 0 until array.length()) {
                    items.add(array.getJSONObject(i))
                }
            } catch (e: Exception) {
                android.util.Log.e("TimetableWidget", "Error fallback timetable JSON: $e")
            }
        }
    }

    override fun onDestroy() {
        items.clear()
    }

    override fun getCount(): Int {
        return items.size
    }

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= items.size) return null

        val item = items[position]

        val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(context)
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)

        // Read orientation-safe widget height
        val isPortrait = context.resources.configuration.orientation != android.content.res.Configuration.ORIENTATION_LANDSCAPE
        val widgetH = if (isPortrait) {
            val h = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
            if (h > 0) h else options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 200)
        } else {
            val h = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            if (h > 0) h else options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 200)
        }

        // Header & container padding overhead is ~60dp
        val availableH = (widgetH - 60).coerceAtLeast(50)

        // 4 Progressive scaling tiers:
        // 1. Smallest: 1 small card
        // 2. A bit bigger: 1 big card
        // 3. A bit bigger: 2 small cards
        // 4. A bit more bigger: 2 big cards
        // 5. Larger: 3+ big cards
        val (targetCount, isCompact) = when {
            availableH < 85 -> Pair(1, true)    // Smallest -> 1 small card
            availableH < 135 -> Pair(1, false)  // A bit bigger -> 1 big card
            availableH < 195 -> Pair(2, true)   // A bit bigger -> 2 small cards
            availableH < 265 -> Pair(2, false)  // A bit more bigger -> 2 big cards
            availableH < 345 -> Pair(3, false)  // Large -> 3 big cards
            else -> Pair((availableH / 95).coerceAtLeast(3), false)
        }

        context.getSharedPreferences(TimetableWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean("widget_is_compact", isCompact).apply()

        val itemLayoutId = if (isCompact) R.layout.widget_item_compact else R.layout.widget_item
        val itemViews = RemoteViews(context.packageName, itemLayoutId)

        val dividerDp = if (isCompact) 6 else 12
        val totalDividers = (targetCount - 1) * dividerDp
        val itemHeightDp = ((availableH - totalDividers) / targetCount).coerceAtLeast(if (isCompact) 50 else 75)

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            itemViews.setViewLayoutHeight(
                R.id.widget_item_container,
                itemHeightDp.toFloat(),
                android.util.TypedValue.COMPLEX_UNIT_DIP
            )
        }

        val course = item.optString("courseName", "Free")
        val timeRoom = item.optString("timeStr", "--")
        val sessionType = item.optString("sessionType", "Lecture")
        val teacher = item.optString("teacherName", "")
        val pct = item.optInt("attendancePct", -1)
        val ratio = item.optString("attendanceRatio", "")

        itemViews.setTextViewText(R.id.item_session_type, sessionType)
        itemViews.setTextViewText(R.id.item_course, course)

        // Combine time + teacher on the same line so subject name (2 lines) doesn't push teacher off-screen.
        // The full item layout keeps R.id.item_teacher hidden and uses the combined string.
        val timeAndTeacher = if (teacher.isNotEmpty()) "$timeRoom · $teacher" else timeRoom
        itemViews.setTextViewText(R.id.item_time_period, timeAndTeacher)
        itemViews.setViewVisibility(R.id.item_teacher, android.view.View.GONE)

        if (sessionType == "INFO") {
            itemViews.setViewVisibility(R.id.item_session_type, android.view.View.GONE)
            itemViews.setViewVisibility(R.id.item_time_period, android.view.View.GONE)
            itemViews.setViewVisibility(R.id.item_teacher, android.view.View.GONE)
            itemViews.setViewVisibility(R.id.item_attendance_container, android.view.View.GONE)
        } else {
            itemViews.setViewVisibility(R.id.item_session_type, android.view.View.VISIBLE)
            itemViews.setViewVisibility(R.id.item_time_period, android.view.View.VISIBLE)

            if (ratio.isNotEmpty() && pct >= 0) {
                itemViews.setViewVisibility(R.id.item_attendance_container, android.view.View.VISIBLE)
                itemViews.setTextViewText(R.id.item_attendance_pct, "${pct}%")
                itemViews.setTextViewText(R.id.item_attendance_ratio, ratio)
            } else {
                itemViews.setViewVisibility(R.id.item_attendance_container, android.view.View.GONE)
            }
        }

        val fillInIntent = Intent()
        itemViews.setOnClickFillInIntent(R.id.widget_item_container, fillInIntent)

        return itemViews
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 2

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}

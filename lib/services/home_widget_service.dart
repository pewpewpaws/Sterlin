import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';

class HomeWidgetService {
  static const String _providerName = 'TimetableWidgetProvider';

  static Map<String, dynamic> _sessionToMap(
    ClassSession session,
    List<CourseAttendance> attendance,
  ) {
    final startStr =
        '${session.start.hour.toString().padLeft(2, '0')}:${session.start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${session.end.hour.toString().padLeft(2, '0')}:${session.end.minute.toString().padLeft(2, '0')}';

    final courseAtt = attendance.firstWhere(
      (a) => a.courseId == session.courseId,
      orElse: () => CourseAttendance(
        courseId: session.courseId,
        courseName: session.courseName,
        classesAttended: 0,
        classesOnDutyLeave: 0,
        classesAbsent: 0,
      ),
    );

    final pct = courseAtt.calculatePercentage(dutyLeaveCountsAsPresent: true);
    final total = courseAtt.classesAttended +
        courseAtt.classesOnDutyLeave +
        courseAtt.classesAbsent;
    final attended =
        courseAtt.classesAttended + courseAtt.classesOnDutyLeave;

    return {
      'courseName': '${session.courseName} (${session.courseId})',
      'courseTitle': session.courseName,
      'courseCode': session.courseId,
      'timeStr': session.room != null && session.room!.isNotEmpty
          ? '$startStr - $endStr | ${session.room}'
          : '$startStr - $endStr',
      'room': session.room ?? '',
      'sessionType':
          session.courseId.trim().toUpperCase() == 'FREE PERIOD'
              ? 'INFO'
              : session.sessionType,
      'teacherName': session.teacherName ?? '',
      'attendancePct': (pct * 100).round(),
      'attendanceRatio': '$attended / $total',
    };
  }

  static Future<void> updateHomeScreenWidget({
    required List<ClassSession> timetable,
    required List<CourseAttendance> attendance,
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? attendanceData,
    Map<String, dynamic>? teachersData,
  }) async {
    try {
      final List<Map<String, dynamic>> timetableList = timetable
          .map((session) => _sessionToMap(session, attendance))
          .toList();

      if (timetable.isEmpty) {
        timetableList.add({
          'courseName': 'No classes scheduled',
          'courseTitle': 'No classes scheduled',
          'courseCode': 'Free day! 🎉',
          'timeStr': 'Enjoy your day',
          'room': '',
          'sessionType': 'INFO',
          'teacherName': '',
          'attendancePct': -1,
          'attendanceRatio': '',
        });
      }

      // Pre-compute daily cards for all days of the week (0..6)
      final Map<String, List<Map<String, dynamic>>> daysMap = {};
      if (profileData != null) {
        for (int day = 0; day < 7; day++) {
          final daySessions = DashboardDataMapper.parseTimetableFromProfile(
            profileData,
            dayIndex: day,
            subjectsData: attendanceData,
            teachersData: teachersData,
          );
          daysMap[day.toString()] = daySessions
              .map((s) => _sessionToMap(s, attendance))
              .toList();
        }
      }

      final String timetableJson = jsonEncode(timetableList);
      final String daysJson = jsonEncode(daysMap);
      final String lastUpdated = DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('timetable_json', timetableJson);
      await prefs.setString('widget_timetable_days_json', daysJson);
      await prefs.setString('last_updated', lastUpdated);

      int maxDays = 5;
      if (profileData != null && profileData.containsKey('timetable')) {
        final tt = profileData['timetable'] as List<dynamic>;
        maxDays = tt.length.clamp(5, 7);
      }
      await prefs.setInt('widget_max_days', maxDays);

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          await HomeWidget.setAppGroupId('HomeWidgetPreferences');
          await HomeWidget.saveWidgetData<String>('timetable_json', timetableJson);
          await HomeWidget.saveWidgetData<String>('widget_timetable_days_json', daysJson);
          await HomeWidget.saveWidgetData<String>('last_updated', lastUpdated);
          await HomeWidget.saveWidgetData<int>('widget_max_days', maxDays);
          await HomeWidget.updateWidget(
            name: _providerName,
            androidName: _providerName,
            qualifiedAndroidName:
                'com.pewpewpaws.sterlin.widgets.TimetableWidgetProvider',
          );
          debugPrint('[WIDGET] Widget update successful: $_providerName');
        } catch (e) {
          debugPrint('[ERROR] updateHomeScreenWidget error: $e');
        }
      }
    } catch (e) {
      debugPrint('[ERROR] updateHomeScreenWidget fatal: $e');
    }
  }

  static Future<void> clearWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timetable_json');
      await prefs.remove('widget_timetable_days_json');
      await prefs.remove('current_index');
      await prefs.remove('last_updated');
      await prefs.remove('widget_max_days');

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await HomeWidget.setAppGroupId('HomeWidgetPreferences');
        await HomeWidget.saveWidgetData<String>('timetable_json', '[]');
        await HomeWidget.saveWidgetData<String>('widget_timetable_days_json', '{}');
        await HomeWidget.saveWidgetData<String>('last_updated', '');
        await HomeWidget.saveWidgetData<int>('widget_max_days', 5);
        await HomeWidget.updateWidget(
          name: _providerName,
          androidName: _providerName,
          qualifiedAndroidName:
              'com.pewpewpaws.sterlin.widgets.TimetableWidgetProvider',
        );
        debugPrint('[WIDGET] clearWidgetData() completed');
      }
    } catch (e) {
      debugPrint('[ERROR] clearWidgetData error: $e');
    }
  }

  static Future<bool?> registerWidgetCallback(Function(Uri?) callback) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return await HomeWidget.registerInteractivityCallback(callback);
    }
    return false;
  }
}

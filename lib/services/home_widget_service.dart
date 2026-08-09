import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';
import 'app_logger_service.dart';

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

      if (profileData != null) {
        await prefs.setString('profile_json', jsonEncode(profileData));
      }
      if (attendanceData != null) {
        await prefs.setString('attendance_json', jsonEncode(attendanceData));
      }
      if (teachersData != null) {
        await prefs.setString('teachers_json', jsonEncode(teachersData));
      }

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          await HomeWidget.setAppGroupId('HomeWidgetPreferences');
          await HomeWidget.saveWidgetData<String>('timetable_json', timetableJson);
          await HomeWidget.saveWidgetData<String>('widget_timetable_days_json', daysJson);
          await HomeWidget.saveWidgetData<String>('last_updated', lastUpdated);
          if (profileData != null) {
            await HomeWidget.saveWidgetData<String>('profile_json', jsonEncode(profileData));
          }
          if (attendanceData != null) {
            await HomeWidget.saveWidgetData<String>('attendance_json', jsonEncode(attendanceData));
          }
          if (teachersData != null) {
            await HomeWidget.saveWidgetData<String>('teachers_json', jsonEncode(teachersData));
          }
          await HomeWidget.updateWidget(
            name: _providerName,
            androidName: _providerName,
            qualifiedAndroidName:
                'com.example.planner.widgets.TimetableWidgetProvider',
          );
          AppLoggerService().log(
            'updateHomeScreenWidget(days: ${daysMap.length}, today: ${timetableList.length})',
            category: 'WIDGET',
          );
        } catch (e) {
          AppLoggerService().log('updateHomeScreenWidget error: $e', category: 'ERROR');
        }
      }
    } catch (e) {
      AppLoggerService().log('updateHomeScreenWidget fatal: $e', category: 'ERROR');
    }
  }

  static Future<void> clearWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timetable_json');
      await prefs.remove('widget_timetable_days_json');
      await prefs.remove('current_index');
      await prefs.remove('last_updated');
      await prefs.remove('profile_json');
      await prefs.remove('attendance_json');
      await prefs.remove('teachers_json');

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await HomeWidget.setAppGroupId('HomeWidgetPreferences');
        await HomeWidget.saveWidgetData<String>('timetable_json', '[]');
        await HomeWidget.saveWidgetData<String>('widget_timetable_days_json', '{}');
        await HomeWidget.saveWidgetData<String>('last_updated', '');
        await HomeWidget.saveWidgetData<String>('profile_json', '');
        await HomeWidget.saveWidgetData<String>('attendance_json', '');
        await HomeWidget.saveWidgetData<String>('teachers_json', '');
        await HomeWidget.updateWidget(
          name: _providerName,
          androidName: _providerName,
          qualifiedAndroidName:
              'com.example.planner.widgets.TimetableWidgetProvider',
        );
        AppLoggerService().log('clearWidgetData() completed', category: 'WIDGET');
      }
    } catch (e) {
      AppLoggerService().log('clearWidgetData error: $e', category: 'ERROR');
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

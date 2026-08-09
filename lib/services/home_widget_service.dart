import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';
import 'app_logger_service.dart';

class HomeWidgetService {
  static const String _providerName = 'TimetableWidgetProvider';

  static Future<void> updateHomeScreenWidget({
    required List<ClassSession> timetable,
    required List<CourseAttendance> attendance,
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? attendanceData,
    Map<String, dynamic>? teachersData,
  }) async {
    try {
      final List<Map<String, dynamic>> timetableList = timetable.map((session) {
        final startStr = '${session.start.hour.toString().padLeft(2, '0')}:${session.start.minute.toString().padLeft(2, '0')}';
        final endStr = '${session.end.hour.toString().padLeft(2, '0')}:${session.end.minute.toString().padLeft(2, '0')}';
        
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
        final total = courseAtt.classesAttended + courseAtt.classesOnDutyLeave + courseAtt.classesAbsent;
        final attended = courseAtt.classesAttended + courseAtt.classesOnDutyLeave;

        return {
          'courseName': '${session.courseName} (${session.courseId})',
          'timeStr': '$startStr - $endStr',
          'room': session.room ?? '',
          'sessionType': session.sessionType,
          'teacherName': session.teacherName ?? '',
          'attendancePct': (pct * 100).round(),
          'attendanceRatio': '$attended/$total',
        };
      }).toList();

      // ponytail: Simple linear scan auto-selects current/next session -> upgrade to real-time timer if needed
      final autoNextIdx = timetable.indexWhere((s) => s.isCurrent || !s.isPast);
      int currentIndex = autoNextIdx != -1 ? autoNextIdx : 0;

      if (timetable.isEmpty) {
        timetableList.add({
          'courseName': 'No classes scheduled',
          'timeStr': 'Free day',
          'room': '',
          'sessionType': 'INFO',
          'teacherName': '',
          'attendancePct': -1,
          'attendanceRatio': '',
        });
        currentIndex = 0;
      }

      final String timetableJson = jsonEncode(timetableList);
      // ponytail: ISO timestamp stash for widget offline indicator -> upgrade to persistent queue if needed
      final String lastUpdated = DateTime.now().toIso8601String();

      // Save directly to Flutter SharedPreferences to guarantee persistence across Isolate resets
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('timetable_json', timetableJson);
      await prefs.setInt('current_index', currentIndex);
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

      // Save to HomeWidget plugin on supported mobile platforms (Android/iOS)
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          await HomeWidget.setAppGroupId('HomeWidgetPreferences');
          await HomeWidget.saveWidgetData<String>('timetable_json', timetableJson);
          await HomeWidget.saveWidgetData<int>('current_index', currentIndex);
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
            qualifiedAndroidName: 'com.example.planner.TimetableWidgetProvider',
          );
          AppLoggerService().log('updateHomeScreenWidget(cards: ${timetableList.length})', category: 'WIDGET');
        } catch (e) {
          AppLoggerService().log('updateHomeScreenWidget(warning: $e)', category: 'WIDGET');
        }
      }
    } catch (e) {
      AppLoggerService().log('updateHomeScreenWidget(error: $e)', category: 'ERROR');
    }
  }

  static Future<void> clearWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timetable_json');
      await prefs.remove('current_index');
      await prefs.remove('last_updated');
      await prefs.remove('profile_json');
      await prefs.remove('attendance_json');
      await prefs.remove('teachers_json');

      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await HomeWidget.setAppGroupId('HomeWidgetPreferences');
        await HomeWidget.saveWidgetData<String>('timetable_json', '[]');
        await HomeWidget.saveWidgetData<int>('current_index', 0);
        await HomeWidget.saveWidgetData<String>('last_updated', '');
        await HomeWidget.saveWidgetData<String>('profile_json', '');
        await HomeWidget.saveWidgetData<String>('attendance_json', '');
        await HomeWidget.saveWidgetData<String>('teachers_json', '');
        await HomeWidget.updateWidget(
          name: _providerName,
          androidName: _providerName,
          qualifiedAndroidName: 'com.example.planner.TimetableWidgetProvider',
        );
        AppLoggerService().log('clearWidgetData() completed', category: 'WIDGET');
      }
    } catch (e) {
      AppLoggerService().log('clearWidgetData(error: $e)', category: 'ERROR');
    }
  }

  /// ponytail: Direct proxy for background home widget click callbacks -> upgrade to WorkManager if background sync required
  static Future<bool?> registerWidgetCallback(Function(Uri?) callback) async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return await HomeWidget.registerInteractivityCallback(callback);
    }
    return false;
  }
}

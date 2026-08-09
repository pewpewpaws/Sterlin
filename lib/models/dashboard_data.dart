import 'package:flutter/material.dart';
import '../services/etlab_api_service.dart';

enum AttendanceStatus { present, absent, dutyLeave, cancelled, holiday }

class ClassSession {
  final String courseId;
  final String courseName;
  final TimeOfDay start;
  final TimeOfDay end;
  final String? room;
  final String sessionType; // Lecture / Lab / Tutorial
  final String? teacherName;
  final bool isToday;
  final bool isPastDay;
  AttendanceStatus? status;

  ClassSession({
    required this.courseId,
    required this.courseName,
    required this.start,
    required this.end,
    this.room,
    required this.sessionType,
    this.teacherName,
    this.isToday = true,
    this.isPastDay = false,
    this.status,
  });

  bool get isPast {
    if (isPastDay) return true;
    if (!isToday) return false;
    final now = TimeOfDay.now();
    return end.hour < now.hour || (end.hour == now.hour && end.minute < now.minute);
  }

  bool get isCurrent {
    if (!isToday || isPastDay) return false;
    final now = TimeOfDay.now();
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }
}

class CourseAttendance {
  final String courseId;
  final String courseName;
  final double requiredPercentage;
  final int classesAttended;
  final int classesOnDutyLeave;
  final int classesAbsent;

  CourseAttendance({
    required this.courseId,
    required this.courseName,
    this.requiredPercentage = 0.75,
    required this.classesAttended,
    required this.classesOnDutyLeave,
    required this.classesAbsent,
  });

  double calculatePercentage({required bool dutyLeaveCountsAsPresent}) {
    final total = dutyLeaveCountsAsPresent
        ? classesAttended + classesOnDutyLeave + classesAbsent
        : classesAttended + classesAbsent;
    if (total == 0) return 1.0;
    
    final attended = dutyLeaveCountsAsPresent
        ? classesAttended + classesOnDutyLeave
        : classesAttended;
        
    return attended / total;
  }

  int get totalClassesTracked => classesAttended + classesOnDutyLeave + classesAbsent;

  String getBunkOrRecoverHint({required bool dutyLeaveCountsAsPresent}) {
    final pct = calculatePercentage(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);
    final total = totalClassesTracked;
    final attended = dutyLeaveCountsAsPresent ? classesAttended + classesOnDutyLeave : classesAttended;

    if (pct >= requiredPercentage) {
      int safeSkips = 0;
      int tempTotal = total;
      while ((attended / (tempTotal + 1)) >= requiredPercentage) {
        safeSkips++;
        tempTotal++;
      }
      return safeSkips > 0 ? "Can skip next $safeSkips classes" : "On boundary! Don't skip next class";
    } else {
      int needAttend = 0;
      int tempAttended = attended;
      int tempTotal = total;
      while ((tempAttended / tempTotal) < requiredPercentage) {
        needAttend++;
        tempAttended++;
        tempTotal++;
      }
      return "Attend next $needAttend to recover";
    }
  }
}

class TeacherInfo {
  final String name;
  final String roleOrSubject;
  final String email;
  final String? phone;
  final String? imageUrl;

  TeacherInfo({
    required this.name,
    required this.roleOrSubject,
    required this.email,
    this.phone,
    this.imageUrl,
  });
}

class DashboardDataMapper {
  static List<ClassSession> parseTimetableFromProfile(
    Map<String, dynamic>? profileData, {
    int? dayIndex,
    Map<String, dynamic>? subjectsData,
    Map<String, dynamic>? teachersData,
  }) {
    if (profileData == null || !profileData.containsKey('timetable')) {
      return [];
    }

    try {
      final Map<String, String> codeToName = {};
      String? peSubjectCode;

      if (subjectsData != null && subjectsData.containsKey('subjects')) {
        for (var s in (subjectsData['subjects'] as List<dynamic>)) {
          final item = s as Map<String, dynamic>;
          final code = item['code']?.toString() ?? '';
          final name = item['subject']?.toString() ?? code;
          if (code.isNotEmpty) {
            codeToName[code] = name;
            if (code.toUpperCase().startsWith('PE')) {
              peSubjectCode = code;
            }
          }
        }
      }

      final Map<String, String> subjectToTeacher = {};
      if (teachersData != null && teachersData['sub_teacher'] != null) {
        for (var t in (teachersData['sub_teacher'] as List<dynamic>)) {
          final item = t as Map<String, dynamic>;
          final rawSubj = item['t_subject']?.toString().trim() ?? '';
          final name = item['t_name']?.toString().trim() ?? '';
          if (rawSubj.isNotEmpty && name.isNotEmpty) {
            final parts = rawSubj.split(' - ');
            final codePart = parts[0].trim().toUpperCase();
            final namePart = parts.length > 1 ? parts.sublist(1).join(' - ').trim().toUpperCase() : rawSubj.toUpperCase();

            subjectToTeacher[codePart] = name;
            subjectToTeacher[namePart] = name;
            subjectToTeacher[rawSubj.toUpperCase()] = name;
          }
        }
      }

      final rawTimetable = profileData['timetable'] as List<dynamic>;
      final nowWeekday = DateTime.now().weekday;
      
      int maxDayIndex = (rawTimetable.length - 1).clamp(4, 6);
      final bool isWeekendToday = (nowWeekday == DateTime.saturday && maxDayIndex < 5) || 
                                  (nowWeekday == DateTime.sunday && maxDayIndex < 6);

      int currentDayIndex = nowWeekday - 1;
      int selectedDay = dayIndex ?? (isWeekendToday ? 0 : currentDayIndex);

      if (selectedDay < 0 || selectedDay > maxDayIndex) {
        selectedDay = 0;
      }
      
      bool isToday = !isWeekendToday && ((dayIndex == null && currentDayIndex <= maxDayIndex) || (selectedDay == currentDayIndex));
      bool isPastDay = false;
      if (!isWeekendToday && currentDayIndex <= maxDayIndex) {
        isPastDay = selectedDay < currentDayIndex;
      }

      if (selectedDay >= rawTimetable.length) return [];

      final dayPeriods = rawTimetable[selectedDay] as List<dynamic>;
      final List<ClassSession> result = [];

      for (int i = 0; i < dayPeriods.length; i++) {
        final period = dayPeriods[i] as Map<String, dynamic>;
        var subjectCode = (period['subject']?.toString() ?? '').trim().toUpperCase();
        final typeRaw = period['type'] ?? 'TH';
        final timeStr = period['timeperiod'] ?? '';

        if (subjectCode == 'FREE PERIOD' || typeRaw == 'FR' || timeStr.toString().isEmpty) {
          continue;
        }

        // Rule: If in timetable subject is BT404, substitute with PE subject code (e.g. PECMT535)
        if (subjectCode == 'BT404') {
          subjectCode = peSubjectCode ?? subjectCode;
        }

        final fullCourseName = codeToName[subjectCode] ?? subjectCode;
        final (start, end) = _parseTimePeriod(
          timeStr.toString(),
          isFriday: selectedDay == 4,
          periodIndex: i,
        );

        String sessionType = 'Lecture';
        if (typeRaw == 'PR') sessionType = 'Lab';
        if (typeRaw == 'TU') sessionType = 'Tutorial';

        final isLab = sessionType == 'Lab' ||
            subjectCode.contains('LAB') ||
            fullCourseName.toUpperCase().contains('LAB');

        String? teacherName;
        if (!isLab) {
          var rawTeacher = period['teacher']?.toString().trim() ?? '';
          if (rawTeacher.toUpperCase() == 'NA' || rawTeacher.toUpperCase() == 'N/A') {
            rawTeacher = '';
          }

          teacherName = subjectToTeacher[subjectCode] ??
              subjectToTeacher[fullCourseName.toUpperCase()] ??
              (rawTeacher.isNotEmpty ? rawTeacher : null);
        }

        result.add(
          ClassSession(
            courseId: subjectCode,
            courseName: fullCourseName,
            start: start,
            end: end,
            sessionType: sessionType,
            teacherName: teacherName,
            isToday: isToday,
            isPastDay: isPastDay,
          ),
        );
      }

      final List<ClassSession> groupedResult = [];
      for (var session in result) {
        if (groupedResult.isEmpty) {
          groupedResult.add(session);
        } else {
          final last = groupedResult.last;
          if (last.sessionType == 'Lab' &&
              session.sessionType == 'Lab' &&
              last.courseId == session.courseId) {
            groupedResult[groupedResult.length - 1] = ClassSession(
              courseId: last.courseId,
              courseName: last.courseName,
              start: last.start,
              end: session.end,
              room: last.room ?? session.room,
              sessionType: last.sessionType,
              teacherName: last.teacherName ?? session.teacherName,
              isToday: last.isToday,
              isPastDay: last.isPastDay,
              status: last.status,
            );
          } else {
            groupedResult.add(session);
          }
        }
      }
      return groupedResult;
    } catch (e) {
      return [];
    }
  }

  static (TimeOfDay, TimeOfDay) _parseTimePeriod(
    String timeperiod, {
    bool isFriday = false,
    int periodIndex = 0,
  }) {
    if (isFriday) {
      if (periodIndex == 3) {
        return (const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 15, minute: 0));
      } else if (periodIndex == 4) {
        return (const TimeOfDay(hour: 15, minute: 0), const TimeOfDay(hour: 16, minute: 0));
      }
    }
    final parts = timeperiod.split('-');
    TimeOfDay p(String s) {
      final v = s.trim().split('.');
      int h = int.tryParse(v[0]) ?? 9;
      if (h >= 1 && h <= 4) h += 12;
      return TimeOfDay(hour: h, minute: v.length > 1 ? (int.tryParse(v[1]) ?? 0) : 0);
    }
    return parts.length == 2
        ? (p(parts[0]), p(parts[1]))
        : (const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 10, minute: 0));
  }

  static List<CourseAttendance> parseAttendanceFromSubjects(
    Map<String, dynamic>? subjectsData, {
    double? targetPercentage,
  }) {
    if (subjectsData == null) return [];

    final reqPct = targetPercentage ?? EtlabApiService().targetAttendancePct;

    try {
      List<dynamic>? rawSubjects;
      if (subjectsData.containsKey('subjects') && subjectsData['subjects'] is List) {
        rawSubjects = subjectsData['subjects'] as List<dynamic>;
      } else if (subjectsData.containsKey('attends') && subjectsData['attends'] is List) {
        rawSubjects = subjectsData['attends'] as List<dynamic>;
      } else if (subjectsData.containsKey('data') && subjectsData['data'] is List) {
        rawSubjects = subjectsData['data'] as List<dynamic>;
      }

      if (rawSubjects == null) return [];

      final List<CourseAttendance> result = [];

      for (var s in rawSubjects) {
        if (s is! Map<String, dynamic>) continue;
        final item = s;
        final code = (item['code'] ?? item['subject_code'] ?? item['course_code'] ?? '').toString().trim().toUpperCase();
        final subjectName = (item['subject'] ?? item['subject_name'] ?? item['course_name'] ?? code).toString();
        final attended = int.tryParse((item['class_attended'] ?? item['attended'] ?? item['present'] ?? '0').toString()) ?? 0;
        final total = int.tryParse((item['total_classes'] ?? item['total'] ?? item['total_class'] ?? '0').toString()) ?? 0;
        final absent = (total - attended) > 0 ? (total - attended) : 0;

        if (subjectName.isNotEmpty || code.isNotEmpty) {
          result.add(
            CourseAttendance(
              courseId: code.isNotEmpty ? code : subjectName,
              courseName: subjectName.isNotEmpty ? subjectName : code,
              requiredPercentage: reqPct,
              classesAttended: attended,
              classesOnDutyLeave: 0,
              classesAbsent: absent,
            ),
          );
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  static List<TeacherInfo> parseTeachers(Map<String, dynamic>? teachersData) {
    if (teachersData == null) return [];

    final List<TeacherInfo> result = [];

    void addFromGroup(List<dynamic>? group, String defaultRole) {
      if (group == null) return;
      for (var item in group) {
        final t = item as Map<String, dynamic>;
        result.add(
          TeacherInfo(
            name: t['t_name']?.toString() ?? '',
            roleOrSubject: (t['t_subject'] == 'hod' || t['t_subject'] == 'staffadvisor')
                ? defaultRole
                : (t['t_subject']?.toString() ?? defaultRole),
            email: t['t_email']?.toString() ?? '',
            phone: t['t_phone']?.toString(),
            imageUrl: t['image_url']?.toString(),
          ),
        );
      }
    }

    addFromGroup(teachersData['hod'] as List<dynamic>?, 'Head of Department');
    addFromGroup(teachersData['staffadvisor'] as List<dynamic>?, 'Staff Advisor');
    addFromGroup(teachersData['sub_teacher'] as List<dynamic>?, 'Subject Teacher');

    return result;
  }
}

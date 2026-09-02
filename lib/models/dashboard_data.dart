import 'package:flutter/material.dart';
import 'etlab_models.dart';
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

  int calculateSafeSkips({required bool dutyLeaveCountsAsPresent}) {
    final total = dutyLeaveCountsAsPresent
        ? classesAttended + classesOnDutyLeave + classesAbsent
        : classesAttended + classesAbsent;
    if (total == 0) return 0;
    final attended = dutyLeaveCountsAsPresent ? classesAttended + classesOnDutyLeave : classesAttended;
    final skips = ((attended / requiredPercentage) - total).floor();
    return skips > 0 ? skips : 0;
  }

  bool isOnBoundary({required bool dutyLeaveCountsAsPresent}) {
    final pct = calculatePercentage(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);
    if (pct < requiredPercentage) return false;
    return calculateSafeSkips(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent) == 0;
  }

  String getBunkOrRecoverHint({required bool dutyLeaveCountsAsPresent}) {
    final pct = calculatePercentage(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);
    final total = dutyLeaveCountsAsPresent
        ? classesAttended + classesOnDutyLeave + classesAbsent
        : classesAttended + classesAbsent;
    final attended = dutyLeaveCountsAsPresent ? classesAttended + classesOnDutyLeave : classesAttended;

    if (pct >= requiredPercentage) {
      final safeSkips = calculateSafeSkips(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);
      return safeSkips > 0 ? "Can skip next $safeSkips classes" : "On boundary! Don't skip next class";
    } else {
      final needAttend = ((requiredPercentage * total - attended) / (1.0 - requiredPercentage)).ceil();
      return "Attend next ${needAttend > 0 ? needAttend : 1} to recover";
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
    if (profileData == null) return [];
    final profile = EtlabProfile.fromJson(profileData);
    if (profile.timetable == null || profile.timetable!.isEmpty) {
      return [];
    }

    try {
      final Map<String, String> codeToName = {};
      String? peSubjectCode;

      if (subjectsData != null && subjectsData.containsKey('subjects')) {
        for (var s in (subjectsData['subjects'] as List<dynamic>)) {
          if (s is Map) {
            final code = (s['code'] ?? s['subject_code'] ?? s['course_code'] ?? '').toString().trim();
            final name = (s['subject'] ?? s['subject_name'] ?? s['course_name'] ?? code).toString().trim();
            if (code.isNotEmpty) {
              codeToName[code] = name.isNotEmpty ? name : code;
              codeToName[code.toUpperCase()] = name.isNotEmpty ? name : code;
              if (code.toUpperCase().startsWith('PE')) {
                peSubjectCode = code;
              }
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

      final rawTimetable = profile.timetable!;
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

      final dayPeriods = rawTimetable[selectedDay];
      final List<ClassSession> result = [];

      for (int i = 0; i < dayPeriods.length; i++) {
        final period = dayPeriods[i];
        var subjectCode = (period.subject ?? '').trim().toUpperCase();
        final typeRaw = period.type ?? 'TH';
        final timeStr = period.timeperiod ?? '';

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
          var rawTeacher = period.teacher?.trim() ?? '';
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

  /// True when today's timetable has classes running now (with a short tail
  /// grace) or starting within the normal refresh horizon.
  static bool isClassActiveWindow(Map<String, dynamic>? profileData) {
    try {
      if (profileData == null) return false;
      final now = DateTime.now();
      if (now.weekday == DateTime.sunday) return false;

      final profile = EtlabProfile.fromJson(profileData);
      final raw = profile.timetable;
      if (raw == null || raw.isEmpty) return false;

      final maxDayIndex = (raw.length - 1).clamp(4, 6);
      if ((now.weekday - 1) > maxDayIndex) return false;

      final sessions = parseTimetableFromProfile(profileData);
      int? firstStart;
      int? lastEnd;
      for (final s in sessions) {
        final sm = s.start.hour * 60 + s.start.minute;
        final em = s.end.hour * 60 + s.end.minute;
        if (em <= sm) continue;
        if (firstStart == null || sm < firstStart) firstStart = sm;
        if (lastEnd == null || em > lastEnd) lastEnd = em;
      }
      if (firstStart == null || lastEnd == null) return false;

      const tailGraceMinutes = 30;
      const horizonMinutes = 5 * 60;
      final nowMinutes = now.hour * 60 + now.minute;

      final active =
          nowMinutes >= firstStart && nowMinutes <= lastEnd + tailGraceMinutes;
      final imminent =
          nowMinutes < firstStart && (firstStart - nowMinutes) <= horizonMinutes;
      return active || imminent;
    } catch (_) {
      return false;
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
      List<dynamic>? rawSubjects = subjectsData['subjects'] ?? subjectsData['attends'] ?? subjectsData['data'] ?? subjectsData['semesterlist'];
      if (rawSubjects == null) return [];

      return rawSubjects.map((s) {
        if (s is! Map<String, dynamic>) return null;
        final sa = EtlabSubjectAttendance.fromJson(s);
        if (sa.name.isEmpty && sa.code.isEmpty) return null;
        
        final absent = (sa.total - sa.attended) > 0 ? (sa.total - sa.attended) : 0;
        
        return CourseAttendance(
          courseId: sa.code.isNotEmpty ? sa.code : sa.name,
          courseName: sa.name.isNotEmpty ? sa.name : sa.code,
          requiredPercentage: reqPct,
          classesAttended: sa.attended,
          classesOnDutyLeave: 0,
          classesAbsent: absent,
        );
      }).whereType<CourseAttendance>().toList();
    } catch (_) {
      return [];
    }
  }

  static List<TeacherInfo> parseTeachers(Map<String, dynamic>? teachersData) {
    if (teachersData == null) return [];
    
    final tData = EtlabTeachersData.fromJson(teachersData);
    final List<TeacherInfo> result = [];

    void addFromGroup(List<EtlabTeacher>? group, String defaultRole) {
      if (group == null) return;
      for (var t in group) {
        result.add(
          TeacherInfo(
            name: t.name ?? '',
            roleOrSubject: (t.subject == 'hod' || t.subject == 'staffadvisor')
                ? defaultRole
                : (t.subject ?? defaultRole),
            email: t.email ?? '',
            phone: t.phone,
            imageUrl: t.imageUrl,
          ),
        );
      }
    }

    addFromGroup(tData.hod, 'Head of Department');
    addFromGroup(tData.staffadvisor, 'Staff Advisor');
    addFromGroup(tData.subTeacher, 'Subject Teacher');

    return result;
  }
}

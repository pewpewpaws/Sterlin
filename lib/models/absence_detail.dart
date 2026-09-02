import '../services/etlab_api_service.dart';

class AbsenceDetail {
  final String rawSubject;
  final String subjectCode;
  final String subjectName;
  final String? teacherName;
  final String date;
  final String formattedDate;
  final String dayName;
  final String hour;
  final String key;

  AbsenceDetail({
    required this.rawSubject,
    required this.subjectCode,
    required this.subjectName,
    this.teacherName,
    required this.date,
    required this.formattedDate,
    required this.dayName,
    required this.hour,
    required this.key,
  });

  static AbsenceDetail resolve(Map<String, dynamic> raw) {
    final rawSubj = (raw['subject'] ?? '').toString().trim();
    final dateStr = (raw['date'] ?? '').toString().trim();
    final hour = (raw['hour'] ?? '').toString().trim();
    final key = (raw['key'] ?? '${dateStr}_${hour}_$rawSubj').toString();

    // 1. Resolve day & date
    final dt = DateTime.tryParse(dateStr);
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dayName = dt != null ? weekdays[dt.weekday - 1] : '';
    final formattedDate = dt != null
        ? '${dt.day} ${months[dt.month - 1]} ${dt.year}'
        : dateStr;

    // 2. Resolve code, name, teacher
    final api = EtlabApiService();
    final subjectsData = api.attendanceData ?? api.profileData;
    final teachersData = api.teachersData ?? api.profileData;
    final profile = api.profileData;

    final Map<String, String> codeToName = {};
    final Map<String, String> nameToCode = {};

    if (subjectsData != null && subjectsData.containsKey('subjects')) {
      for (var s in (subjectsData['subjects'] as List<dynamic>)) {
        if (s is Map) {
          final c = (s['code'] ?? '').toString().trim().toUpperCase();
          final n = (s['subject'] ?? '').toString().trim();
          if (c.isNotEmpty) {
            codeToName[c] = n.isNotEmpty ? n : c;
            if (n.isNotEmpty) nameToCode[n.toUpperCase()] = c;
          }
        }
      }
    }

    final Map<String, String> subjectToTeacher = {};
    if (teachersData != null && teachersData['sub_teacher'] is List) {
      for (var t in (teachersData['sub_teacher'] as List<dynamic>)) {
        if (t is Map) {
          final tSubj = (t['t_subject'] ?? '').toString().trim();
          final tName = (t['t_name'] ?? '').toString().trim();
          if (tSubj.isNotEmpty && tName.isNotEmpty) {
            final parts = tSubj.split(' - ');
            final codePart = parts[0].trim().toUpperCase();
            final namePart = parts.length > 1
                ? parts.sublist(1).join(' - ').trim().toUpperCase()
                : tSubj.toUpperCase();

            subjectToTeacher[codePart] = tName;
            subjectToTeacher[namePart] = tName;
            subjectToTeacher[tSubj.toUpperCase()] = tName;
          }
        }
      }
    }

    String code = '';
    String name = rawSubj;

    if (rawSubj.contains(' - ')) {
      final parts = rawSubj.split(' - ');
      code = parts[0].trim();
      name = parts.sublist(1).join(' - ').trim();
    } else if (codeToName.containsKey(rawSubj.toUpperCase())) {
      code = rawSubj.toUpperCase();
      name = codeToName[rawSubj.toUpperCase()]!;
    } else if (nameToCode.containsKey(rawSubj.toUpperCase())) {
      code = nameToCode[rawSubj.toUpperCase()]!;
      name = rawSubj;
    } else {
      final isCodePattern = RegExp(
        r'^[A-Z]{2,4}\s?[0-9]{3}[A-Z]?$',
      ).hasMatch(rawSubj.toUpperCase());
      if (isCodePattern) {
        code = rawSubj.toUpperCase();
        name = codeToName[code] ?? rawSubj;
      } else {
        code = '';
        name = rawSubj;
      }
    }

    String? teacher = subjectToTeacher[code.toUpperCase()] ??
        subjectToTeacher[name.toUpperCase()] ??
        subjectToTeacher[rawSubj.toUpperCase()];

    if (teacher == null &&
        profile != null &&
        profile['timetable'] is List &&
        dt != null) {
      final dayIdx = dt.weekday - 1;
      final rawTt = profile['timetable'] as List<dynamic>;
      if (dayIdx >= 0 && dayIdx < rawTt.length && rawTt[dayIdx] is List) {
        final dayPeriods = rawTt[dayIdx] as List<dynamic>;
        for (var p in dayPeriods) {
          if (p is Map) {
            final pSubj = (p['subject'] ?? '').toString().trim().toUpperCase();
            final pTeacher = (p['teacher'] ?? '').toString().trim();
            if (pTeacher.isNotEmpty &&
                pTeacher.toUpperCase() != 'NA' &&
                pTeacher.toUpperCase() != 'N/A') {
              if (pSubj == code.toUpperCase() ||
                  pSubj == name.toUpperCase() ||
                  pSubj == rawSubj.toUpperCase()) {
                teacher = pTeacher;
                break;
              }
            }
          }
        }
      }
    }

    return AbsenceDetail(
      rawSubject: rawSubj,
      subjectCode: code,
      subjectName: name,
      teacherName: teacher,
      date: dateStr,
      formattedDate: formattedDate,
      dayName: dayName,
      hour: hour,
      key: key,
    );
  }
}

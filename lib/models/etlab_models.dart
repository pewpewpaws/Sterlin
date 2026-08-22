class EtlabSubjectAttendance {
  final String code;
  final String name;
  final int attended;
  final int total;

  EtlabSubjectAttendance({
    required this.code,
    required this.name,
    required this.attended,
    required this.total,
  });

  factory EtlabSubjectAttendance.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? json['subject_code'] ?? json['course_code'] ?? '').toString();
    final name = (json['subject'] ?? json['subject_name'] ?? json['course_name'] ?? code).toString();
    final attended = int.tryParse((json['class_attended'] ?? json['attended'] ?? json['present'] ?? '0').toString()) ?? 0;
    final total = int.tryParse((json['total_classes'] ?? json['total'] ?? json['total_class'] ?? '0').toString()) ?? 0;
    return EtlabSubjectAttendance(
      code: code,
      name: name,
      attended: attended,
      total: total,
    );
  }
}

class EtlabProfile {
  final List<List<EtlabTimetableItem>>? timetable;
  final dynamic semId;

  EtlabProfile(this.timetable, this.semId);

  factory EtlabProfile.fromJson(Map<String, dynamic> json) {
    List<List<EtlabTimetableItem>>? timetable;
    if (json['timetable'] is List) {
      timetable = (json['timetable'] as List).map((day) {
        if (day is List) {
          return day
              .whereType<Map<String, dynamic>>()
              .map((item) => EtlabTimetableItem.fromJson(item))
              .toList();
        }
        return <EtlabTimetableItem>[];
      }).toList();
    }
    return EtlabProfile(timetable, json['sem_id']);
  }
}

class EtlabTimetableItem {
  final String? subject;
  final String? type;
  final String? timeperiod;
  final String? teacher;

  EtlabTimetableItem(this.subject, this.type, this.timeperiod, this.teacher);

  factory EtlabTimetableItem.fromJson(Map<String, dynamic> json) {
    return EtlabTimetableItem(
      json['subject']?.toString(),
      json['type']?.toString(),
      json['timeperiod']?.toString(),
      json['teacher']?.toString(),
    );
  }
}

class EtlabTeachersData {
  final List<EtlabTeacher>? hod;
  final List<EtlabTeacher>? staffadvisor;
  final List<EtlabTeacher>? subTeacher;

  EtlabTeachersData(this.hod, this.staffadvisor, this.subTeacher);

  factory EtlabTeachersData.fromJson(Map<String, dynamic> json) {
    List<EtlabTeacher>? parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((t) => EtlabTeacher.fromJson(t))
            .toList();
      }
      return null;
    }

    return EtlabTeachersData(
      parseList(json['hod']),
      parseList(json['staffadvisor']),
      parseList(json['sub_teacher']),
    );
  }
}

class EtlabTeacher {
  final String? name;
  final String? subject;
  final String? email;
  final String? phone;
  final String? imageUrl;

  EtlabTeacher(this.name, this.subject, this.email, this.phone, this.imageUrl);

  factory EtlabTeacher.fromJson(Map<String, dynamic> json) {
    return EtlabTeacher(
      json['t_name']?.toString(),
      json['t_subject']?.toString(),
      json['t_email']?.toString(),
      json['t_phone']?.toString(),
      json['image_url']?.toString(),
    );
  }
}

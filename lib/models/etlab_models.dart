import 'package:json_annotation/json_annotation.dart';

part 'etlab_models.g.dart';

Object? _readSubjectCode(Map json, String key) => 
    json['code'] ?? json['subject_code'] ?? json['course_code'] ?? '';

Object? _readSubjectName(Map json, String key) => 
    json['subject'] ?? json['subject_name'] ?? json['course_name'] ?? _readSubjectCode(json, key);

Object? _readAttended(Map json, String key) => 
    json['class_attended'] ?? json['attended'] ?? json['present'] ?? '0';

Object? _readTotal(Map json, String key) => 
    json['total_classes'] ?? json['total'] ?? json['total_class'] ?? '0';

int _parseInt(dynamic value) => int.tryParse(value.toString()) ?? 0;

@JsonSerializable()
class EtlabSubjectAttendance {
  @JsonKey(readValue: _readSubjectCode)
  final String code;
  
  @JsonKey(readValue: _readSubjectName)
  final String name;
  
  @JsonKey(readValue: _readAttended, fromJson: _parseInt)
  final int attended;
  
  @JsonKey(readValue: _readTotal, fromJson: _parseInt)
  final int total;
  
  EtlabSubjectAttendance({
    required this.code, 
    required this.name, 
    required this.attended, 
    required this.total,
  });
  
  factory EtlabSubjectAttendance.fromJson(Map<String, dynamic> json) => _$EtlabSubjectAttendanceFromJson(json);
}

@JsonSerializable()
class EtlabProfile {
  final List<List<EtlabTimetableItem>>? timetable;
  final dynamic sem_id;
  
  EtlabProfile(this.timetable, this.sem_id);
  factory EtlabProfile.fromJson(Map<String, dynamic> json) => _$EtlabProfileFromJson(json);
}

@JsonSerializable()
class EtlabTimetableItem {
  final String? subject;
  final String? type;
  final String? timeperiod;
  final String? teacher;
  
  EtlabTimetableItem(this.subject, this.type, this.timeperiod, this.teacher);
  factory EtlabTimetableItem.fromJson(Map<String, dynamic> json) => _$EtlabTimetableItemFromJson(json);
}

@JsonSerializable()
class EtlabTeachersData {
  final List<EtlabTeacher>? hod;
  final List<EtlabTeacher>? staffadvisor;
  final List<EtlabTeacher>? sub_teacher;
  
  EtlabTeachersData(this.hod, this.staffadvisor, this.sub_teacher);
  factory EtlabTeachersData.fromJson(Map<String, dynamic> json) => _$EtlabTeachersDataFromJson(json);
}

@JsonSerializable()
class EtlabTeacher {
  final String? t_name;
  final String? t_subject;
  final String? t_email;
  final String? t_phone;
  final String? image_url;
  
  EtlabTeacher(this.t_name, this.t_subject, this.t_email, this.t_phone, this.image_url);
  factory EtlabTeacher.fromJson(Map<String, dynamic> json) => _$EtlabTeacherFromJson(json);
}

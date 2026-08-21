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

@JsonSerializable(createToJson: false)
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

@JsonSerializable(createToJson: false)
class EtlabProfile {
  final List<List<EtlabTimetableItem>>? timetable;
  
  @JsonKey(name: 'sem_id')
  final dynamic semId;
  
  EtlabProfile(this.timetable, this.semId);
  factory EtlabProfile.fromJson(Map<String, dynamic> json) => _$EtlabProfileFromJson(json);
}

@JsonSerializable(createToJson: false)
class EtlabTimetableItem {
  final String? subject;
  final String? type;
  final String? timeperiod;
  final String? teacher;
  
  EtlabTimetableItem(this.subject, this.type, this.timeperiod, this.teacher);
  factory EtlabTimetableItem.fromJson(Map<String, dynamic> json) => _$EtlabTimetableItemFromJson(json);
}

@JsonSerializable(createToJson: false)
class EtlabTeachersData {
  final List<EtlabTeacher>? hod;
  final List<EtlabTeacher>? staffadvisor;
  
  @JsonKey(name: 'sub_teacher')
  final List<EtlabTeacher>? subTeacher;
  
  EtlabTeachersData(this.hod, this.staffadvisor, this.subTeacher);
  factory EtlabTeachersData.fromJson(Map<String, dynamic> json) => _$EtlabTeachersDataFromJson(json);
}

@JsonSerializable(createToJson: false)
class EtlabTeacher {
  @JsonKey(name: 't_name')
  final String? name;
  
  @JsonKey(name: 't_subject')
  final String? subject;
  
  @JsonKey(name: 't_email')
  final String? email;
  
  @JsonKey(name: 't_phone')
  final String? phone;
  
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  
  EtlabTeacher(this.name, this.subject, this.email, this.phone, this.imageUrl);
  factory EtlabTeacher.fromJson(Map<String, dynamic> json) => _$EtlabTeacherFromJson(json);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etlab_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EtlabSubjectAttendance _$EtlabSubjectAttendanceFromJson(
  Map<String, dynamic> json,
) => EtlabSubjectAttendance(
  code: _readSubjectCode(json, 'code') as String,
  name: _readSubjectName(json, 'name') as String,
  attended: _parseInt(_readAttended(json, 'attended')),
  total: _parseInt(_readTotal(json, 'total')),
);

Map<String, dynamic> _$EtlabSubjectAttendanceToJson(
  EtlabSubjectAttendance instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'attended': instance.attended,
  'total': instance.total,
};

EtlabProfile _$EtlabProfileFromJson(Map<String, dynamic> json) => EtlabProfile(
  (json['timetable'] as List<dynamic>?)
      ?.map(
        (e) => (e as List<dynamic>)
            .map((e) => EtlabTimetableItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      .toList(),
  json['sem_id'],
);

Map<String, dynamic> _$EtlabProfileToJson(EtlabProfile instance) =>
    <String, dynamic>{
      'timetable': instance.timetable,
      'sem_id': instance.sem_id,
    };

EtlabTimetableItem _$EtlabTimetableItemFromJson(Map<String, dynamic> json) =>
    EtlabTimetableItem(
      json['subject'] as String?,
      json['type'] as String?,
      json['timeperiod'] as String?,
      json['teacher'] as String?,
    );

Map<String, dynamic> _$EtlabTimetableItemToJson(EtlabTimetableItem instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'type': instance.type,
      'timeperiod': instance.timeperiod,
      'teacher': instance.teacher,
    };

EtlabTeachersData _$EtlabTeachersDataFromJson(Map<String, dynamic> json) =>
    EtlabTeachersData(
      (json['hod'] as List<dynamic>?)
          ?.map((e) => EtlabTeacher.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['staffadvisor'] as List<dynamic>?)
          ?.map((e) => EtlabTeacher.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['sub_teacher'] as List<dynamic>?)
          ?.map((e) => EtlabTeacher.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EtlabTeachersDataToJson(EtlabTeachersData instance) =>
    <String, dynamic>{
      'hod': instance.hod,
      'staffadvisor': instance.staffadvisor,
      'sub_teacher': instance.sub_teacher,
    };

EtlabTeacher _$EtlabTeacherFromJson(Map<String, dynamic> json) => EtlabTeacher(
  json['t_name'] as String?,
  json['t_subject'] as String?,
  json['t_email'] as String?,
  json['t_phone'] as String?,
  json['image_url'] as String?,
);

Map<String, dynamic> _$EtlabTeacherToJson(EtlabTeacher instance) =>
    <String, dynamic>{
      't_name': instance.t_name,
      't_subject': instance.t_subject,
      't_email': instance.t_email,
      't_phone': instance.t_phone,
      'image_url': instance.image_url,
    };

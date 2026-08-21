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

EtlabTimetableItem _$EtlabTimetableItemFromJson(Map<String, dynamic> json) =>
    EtlabTimetableItem(
      json['subject'] as String?,
      json['type'] as String?,
      json['timeperiod'] as String?,
      json['teacher'] as String?,
    );

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

EtlabTeacher _$EtlabTeacherFromJson(Map<String, dynamic> json) => EtlabTeacher(
  json['t_name'] as String?,
  json['t_subject'] as String?,
  json['t_email'] as String?,
  json['t_phone'] as String?,
  json['image_url'] as String?,
);

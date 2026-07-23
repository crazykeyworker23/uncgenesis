// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cell_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CellGroupModelImpl _$$CellGroupModelImplFromJson(Map<String, dynamic> json) =>
    _$CellGroupModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      leader: json['leader'] == null
          ? null
          : UserModel.fromJson(json['leader'] as Map<String, dynamic>),
      meetingDay: json['meeting_day'] as String,
      meetingTime: json['meeting_time'] as String,
      address: json['address'] as String,
      latitude: _toDoubleNullable(json['latitude']),
      longitude: _toDoubleNullable(json['longitude']),
      description: json['description'] as String?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$$CellGroupModelImplToJson(
  _$CellGroupModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'leader': instance.leader,
  'meeting_day': instance.meetingDay,
  'meeting_time': instance.meetingTime,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'description': instance.description,
  'status': instance.status,
};

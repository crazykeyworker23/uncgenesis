// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventModelImpl _$$EventModelImplFromJson(Map<String, dynamic> json) =>
    _$EventModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      coverImage: json['cover_image'] as String?,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      location: json['location'] as String,
      capacity: (json['capacity'] as num?)?.toInt(),
      requiresRegistration: json['requires_registration'] as bool,
      status: json['status'] as String,
      registeredCount: (json['registered_count'] as num?)?.toInt(),
      isRegistered: json['is_registered'] as bool?,
    );

Map<String, dynamic> _$$EventModelImplToJson(_$EventModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'slug': instance.slug,
      'description': instance.description,
      'cover_image': instance.coverImage,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'location': instance.location,
      'capacity': instance.capacity,
      'requires_registration': instance.requiresRegistration,
      'status': instance.status,
      'registered_count': instance.registeredCount,
      'is_registered': instance.isRegistered,
    };

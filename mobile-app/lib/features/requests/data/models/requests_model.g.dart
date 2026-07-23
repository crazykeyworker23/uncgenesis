// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requests_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrayerRequestModelImpl _$$PrayerRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$PrayerRequestModelImpl(
  requesterName: json['requester_name'] as String,
  requesterEmail: json['requester_email'] as String?,
  requesterPhone: json['requester_phone'] as String?,
  subject: json['subject'] as String,
  description: json['description'] as String,
  isAnonymous: json['is_anonymous'] as bool,
);

Map<String, dynamic> _$$PrayerRequestModelImplToJson(
  _$PrayerRequestModelImpl instance,
) => <String, dynamic>{
  'requester_name': instance.requesterName,
  'requester_email': instance.requesterEmail,
  'requester_phone': instance.requesterPhone,
  'subject': instance.subject,
  'description': instance.description,
  'is_anonymous': instance.isAnonymous,
};

_$VisitorRequestModelImpl _$$VisitorRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$VisitorRequestModelImpl(
  fullName: json['full_name'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  ageRange: json['age_range'] as String,
  howDidYouFindUs: json['how_did_you_find_us'] as String,
  message: json['message'] as String,
  preferredContact: json['preferred_contact'] as String,
  cellGroupId: (json['cell_group_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$$VisitorRequestModelImplToJson(
  _$VisitorRequestModelImpl instance,
) => <String, dynamic>{
  'full_name': instance.fullName,
  'email': instance.email,
  'phone': instance.phone,
  'age_range': instance.ageRange,
  'how_did_you_find_us': instance.howDidYouFindUs,
  'message': instance.message,
  'preferred_contact': instance.preferredContact,
  'cell_group_id': instance.cellGroupId,
};

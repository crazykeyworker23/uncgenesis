// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsModelImpl _$$AppSettingsModelImplFromJson(
  Map<String, dynamic> json,
) => _$AppSettingsModelImpl(
  appName: json['app_name'] as String,
  appDescription: json['app_description'] as String,
  splashText: json['splash_text'] as String,
  logo: json['logo'] as String?,
  primaryColor: json['primary_color'] as String,
  secondaryColor: json['secondary_color'] as String,
  privacyPolicyUrl: json['privacy_policy_url'] as String,
  termsUrl: json['terms_url'] as String,
);

Map<String, dynamic> _$$AppSettingsModelImplToJson(
  _$AppSettingsModelImpl instance,
) => <String, dynamic>{
  'app_name': instance.appName,
  'app_description': instance.appDescription,
  'splash_text': instance.splashText,
  'logo': instance.logo,
  'primary_color': instance.primaryColor,
  'secondary_color': instance.secondaryColor,
  'privacy_policy_url': instance.privacyPolicyUrl,
  'terms_url': instance.termsUrl,
};

_$ChurchSettingsModelImpl _$$ChurchSettingsModelImplFromJson(
  Map<String, dynamic> json,
) => _$ChurchSettingsModelImpl(
  churchName: json['church_name'] as String,
  address: json['address'] as String,
  city: json['city'] as String,
  country: json['country'] as String,
  phone: json['phone'] as String,
  whatsapp: json['whatsapp'] as String,
  email: json['email'] as String,
  website: json['website'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$ChurchSettingsModelImplToJson(
  _$ChurchSettingsModelImpl instance,
) => <String, dynamic>{
  'church_name': instance.churchName,
  'address': instance.address,
  'city': instance.city,
  'country': instance.country,
  'phone': instance.phone,
  'whatsapp': instance.whatsapp,
  'email': instance.email,
  'website': instance.website,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};

_$ServiceScheduleModelImpl _$$ServiceScheduleModelImplFromJson(
  Map<String, dynamic> json,
) => _$ServiceScheduleModelImpl(
  id: (json['id'] as num).toInt(),
  dayOfWeek: json['day_of_week'] as String,
  dayOfWeekDisplay: json['day_of_week_display'] as String,
  startTime: json['start_time'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$$ServiceScheduleModelImplToJson(
  _$ServiceScheduleModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'day_of_week': instance.dayOfWeek,
  'day_of_week_display': instance.dayOfWeekDisplay,
  'start_time': instance.startTime,
  'title': instance.title,
  'description': instance.description,
};

_$SocialNetworkModelImpl _$$SocialNetworkModelImplFromJson(
  Map<String, dynamic> json,
) => _$SocialNetworkModelImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  url: json['url'] as String,
  iconName: json['icon_name'] as String,
);

Map<String, dynamic> _$$SocialNetworkModelImplToJson(
  _$SocialNetworkModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'url': instance.url,
  'icon_name': instance.iconName,
};

_$PublicSettingsModelImpl _$$PublicSettingsModelImplFromJson(
  Map<String, dynamic> json,
) => _$PublicSettingsModelImpl(
  app: AppSettingsModel.fromJson(json['app'] as Map<String, dynamic>),
  church: ChurchSettingsModel.fromJson(json['church'] as Map<String, dynamic>),
  schedules: (json['schedules'] as List<dynamic>)
      .map((e) => ServiceScheduleModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  socialNetworks: (json['social_networks'] as List<dynamic>)
      .map((e) => SocialNetworkModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$PublicSettingsModelImplToJson(
  _$PublicSettingsModelImpl instance,
) => <String, dynamic>{
  'app': instance.app,
  'church': instance.church,
  'schedules': instance.schedules,
  'social_networks': instance.socialNetworks,
};

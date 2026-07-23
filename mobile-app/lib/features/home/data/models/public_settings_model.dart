import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_settings_model.freezed.dart';
part 'public_settings_model.g.dart';

@freezed
class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    @JsonKey(name: 'app_name') required String appName,
    @JsonKey(name: 'app_description') required String appDescription,
    @JsonKey(name: 'splash_text') required String splashText,
    String? logo,
    @JsonKey(name: 'primary_color') required String primaryColor,
    @JsonKey(name: 'secondary_color') required String secondaryColor,
    @JsonKey(name: 'privacy_policy_url') required String privacyPolicyUrl,
    @JsonKey(name: 'terms_url') required String termsUrl,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => _$AppSettingsModelFromJson(json);
}

@freezed
class ChurchSettingsModel with _$ChurchSettingsModel {
  const factory ChurchSettingsModel({
    @JsonKey(name: 'church_name') required String churchName,
    required String address,
    required String city,
    required String country,
    required String phone,
    required String whatsapp,
    required String email,
    required String website,
    double? latitude,
    double? longitude,
  }) = _ChurchSettingsModel;

  factory ChurchSettingsModel.fromJson(Map<String, dynamic> json) => _$ChurchSettingsModelFromJson(json);
}

@freezed
class ServiceScheduleModel with _$ServiceScheduleModel {
  const factory ServiceScheduleModel({
    required int id,
    @JsonKey(name: 'day_of_week') required String dayOfWeek,
    @JsonKey(name: 'day_of_week_display') required String dayOfWeekDisplay,
    @JsonKey(name: 'start_time') required String startTime,
    required String title,
    required String description,
  }) = _ServiceScheduleModel;

  factory ServiceScheduleModel.fromJson(Map<String, dynamic> json) => _$ServiceScheduleModelFromJson(json);
}

@freezed
class SocialNetworkModel with _$SocialNetworkModel {
  const factory SocialNetworkModel({
    required int id,
    required String name,
    required String url,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _SocialNetworkModel;

  factory SocialNetworkModel.fromJson(Map<String, dynamic> json) => _$SocialNetworkModelFromJson(json);
}

@freezed
class PublicSettingsModel with _$PublicSettingsModel {
  const factory PublicSettingsModel({
    required AppSettingsModel app,
    required ChurchSettingsModel church,
    required List<ServiceScheduleModel> schedules,
    @JsonKey(name: 'social_networks') required List<SocialNetworkModel> socialNetworks,
  }) = _PublicSettingsModel;

  factory PublicSettingsModel.fromJson(Map<String, dynamic> json) => _$PublicSettingsModelFromJson(json);
}

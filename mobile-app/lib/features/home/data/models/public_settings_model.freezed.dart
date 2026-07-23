// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppSettingsModel _$AppSettingsModelFromJson(Map<String, dynamic> json) {
  return _AppSettingsModel.fromJson(json);
}

/// @nodoc
mixin _$AppSettingsModel {
  @JsonKey(name: 'app_name')
  String get appName => throw _privateConstructorUsedError;
  @JsonKey(name: 'app_description')
  String get appDescription => throw _privateConstructorUsedError;
  @JsonKey(name: 'splash_text')
  String get splashText => throw _privateConstructorUsedError;
  String? get logo => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_color')
  String get primaryColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'secondary_color')
  String get secondaryColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'privacy_policy_url')
  String get privacyPolicyUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'terms_url')
  String get termsUrl => throw _privateConstructorUsedError;

  /// Serializes this AppSettingsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSettingsModelCopyWith<AppSettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsModelCopyWith<$Res> {
  factory $AppSettingsModelCopyWith(
    AppSettingsModel value,
    $Res Function(AppSettingsModel) then,
  ) = _$AppSettingsModelCopyWithImpl<$Res, AppSettingsModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'app_name') String appName,
    @JsonKey(name: 'app_description') String appDescription,
    @JsonKey(name: 'splash_text') String splashText,
    String? logo,
    @JsonKey(name: 'primary_color') String primaryColor,
    @JsonKey(name: 'secondary_color') String secondaryColor,
    @JsonKey(name: 'privacy_policy_url') String privacyPolicyUrl,
    @JsonKey(name: 'terms_url') String termsUrl,
  });
}

/// @nodoc
class _$AppSettingsModelCopyWithImpl<$Res, $Val extends AppSettingsModel>
    implements $AppSettingsModelCopyWith<$Res> {
  _$AppSettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appName = null,
    Object? appDescription = null,
    Object? splashText = null,
    Object? logo = freezed,
    Object? primaryColor = null,
    Object? secondaryColor = null,
    Object? privacyPolicyUrl = null,
    Object? termsUrl = null,
  }) {
    return _then(
      _value.copyWith(
            appName: null == appName
                ? _value.appName
                : appName // ignore: cast_nullable_to_non_nullable
                      as String,
            appDescription: null == appDescription
                ? _value.appDescription
                : appDescription // ignore: cast_nullable_to_non_nullable
                      as String,
            splashText: null == splashText
                ? _value.splashText
                : splashText // ignore: cast_nullable_to_non_nullable
                      as String,
            logo: freezed == logo
                ? _value.logo
                : logo // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryColor: null == primaryColor
                ? _value.primaryColor
                : primaryColor // ignore: cast_nullable_to_non_nullable
                      as String,
            secondaryColor: null == secondaryColor
                ? _value.secondaryColor
                : secondaryColor // ignore: cast_nullable_to_non_nullable
                      as String,
            privacyPolicyUrl: null == privacyPolicyUrl
                ? _value.privacyPolicyUrl
                : privacyPolicyUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            termsUrl: null == termsUrl
                ? _value.termsUrl
                : termsUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppSettingsModelImplCopyWith<$Res>
    implements $AppSettingsModelCopyWith<$Res> {
  factory _$$AppSettingsModelImplCopyWith(
    _$AppSettingsModelImpl value,
    $Res Function(_$AppSettingsModelImpl) then,
  ) = __$$AppSettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'app_name') String appName,
    @JsonKey(name: 'app_description') String appDescription,
    @JsonKey(name: 'splash_text') String splashText,
    String? logo,
    @JsonKey(name: 'primary_color') String primaryColor,
    @JsonKey(name: 'secondary_color') String secondaryColor,
    @JsonKey(name: 'privacy_policy_url') String privacyPolicyUrl,
    @JsonKey(name: 'terms_url') String termsUrl,
  });
}

/// @nodoc
class __$$AppSettingsModelImplCopyWithImpl<$Res>
    extends _$AppSettingsModelCopyWithImpl<$Res, _$AppSettingsModelImpl>
    implements _$$AppSettingsModelImplCopyWith<$Res> {
  __$$AppSettingsModelImplCopyWithImpl(
    _$AppSettingsModelImpl _value,
    $Res Function(_$AppSettingsModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appName = null,
    Object? appDescription = null,
    Object? splashText = null,
    Object? logo = freezed,
    Object? primaryColor = null,
    Object? secondaryColor = null,
    Object? privacyPolicyUrl = null,
    Object? termsUrl = null,
  }) {
    return _then(
      _$AppSettingsModelImpl(
        appName: null == appName
            ? _value.appName
            : appName // ignore: cast_nullable_to_non_nullable
                  as String,
        appDescription: null == appDescription
            ? _value.appDescription
            : appDescription // ignore: cast_nullable_to_non_nullable
                  as String,
        splashText: null == splashText
            ? _value.splashText
            : splashText // ignore: cast_nullable_to_non_nullable
                  as String,
        logo: freezed == logo
            ? _value.logo
            : logo // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryColor: null == primaryColor
            ? _value.primaryColor
            : primaryColor // ignore: cast_nullable_to_non_nullable
                  as String,
        secondaryColor: null == secondaryColor
            ? _value.secondaryColor
            : secondaryColor // ignore: cast_nullable_to_non_nullable
                  as String,
        privacyPolicyUrl: null == privacyPolicyUrl
            ? _value.privacyPolicyUrl
            : privacyPolicyUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        termsUrl: null == termsUrl
            ? _value.termsUrl
            : termsUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsModelImpl implements _AppSettingsModel {
  const _$AppSettingsModelImpl({
    @JsonKey(name: 'app_name') required this.appName,
    @JsonKey(name: 'app_description') required this.appDescription,
    @JsonKey(name: 'splash_text') required this.splashText,
    this.logo,
    @JsonKey(name: 'primary_color') required this.primaryColor,
    @JsonKey(name: 'secondary_color') required this.secondaryColor,
    @JsonKey(name: 'privacy_policy_url') required this.privacyPolicyUrl,
    @JsonKey(name: 'terms_url') required this.termsUrl,
  });

  factory _$AppSettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsModelImplFromJson(json);

  @override
  @JsonKey(name: 'app_name')
  final String appName;
  @override
  @JsonKey(name: 'app_description')
  final String appDescription;
  @override
  @JsonKey(name: 'splash_text')
  final String splashText;
  @override
  final String? logo;
  @override
  @JsonKey(name: 'primary_color')
  final String primaryColor;
  @override
  @JsonKey(name: 'secondary_color')
  final String secondaryColor;
  @override
  @JsonKey(name: 'privacy_policy_url')
  final String privacyPolicyUrl;
  @override
  @JsonKey(name: 'terms_url')
  final String termsUrl;

  @override
  String toString() {
    return 'AppSettingsModel(appName: $appName, appDescription: $appDescription, splashText: $splashText, logo: $logo, primaryColor: $primaryColor, secondaryColor: $secondaryColor, privacyPolicyUrl: $privacyPolicyUrl, termsUrl: $termsUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsModelImpl &&
            (identical(other.appName, appName) || other.appName == appName) &&
            (identical(other.appDescription, appDescription) ||
                other.appDescription == appDescription) &&
            (identical(other.splashText, splashText) ||
                other.splashText == splashText) &&
            (identical(other.logo, logo) || other.logo == logo) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.secondaryColor, secondaryColor) ||
                other.secondaryColor == secondaryColor) &&
            (identical(other.privacyPolicyUrl, privacyPolicyUrl) ||
                other.privacyPolicyUrl == privacyPolicyUrl) &&
            (identical(other.termsUrl, termsUrl) ||
                other.termsUrl == termsUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    appName,
    appDescription,
    splashText,
    logo,
    primaryColor,
    secondaryColor,
    privacyPolicyUrl,
    termsUrl,
  );

  /// Create a copy of AppSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsModelImplCopyWith<_$AppSettingsModelImpl> get copyWith =>
      __$$AppSettingsModelImplCopyWithImpl<_$AppSettingsModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsModelImplToJson(this);
  }
}

abstract class _AppSettingsModel implements AppSettingsModel {
  const factory _AppSettingsModel({
    @JsonKey(name: 'app_name') required final String appName,
    @JsonKey(name: 'app_description') required final String appDescription,
    @JsonKey(name: 'splash_text') required final String splashText,
    final String? logo,
    @JsonKey(name: 'primary_color') required final String primaryColor,
    @JsonKey(name: 'secondary_color') required final String secondaryColor,
    @JsonKey(name: 'privacy_policy_url') required final String privacyPolicyUrl,
    @JsonKey(name: 'terms_url') required final String termsUrl,
  }) = _$AppSettingsModelImpl;

  factory _AppSettingsModel.fromJson(Map<String, dynamic> json) =
      _$AppSettingsModelImpl.fromJson;

  @override
  @JsonKey(name: 'app_name')
  String get appName;
  @override
  @JsonKey(name: 'app_description')
  String get appDescription;
  @override
  @JsonKey(name: 'splash_text')
  String get splashText;
  @override
  String? get logo;
  @override
  @JsonKey(name: 'primary_color')
  String get primaryColor;
  @override
  @JsonKey(name: 'secondary_color')
  String get secondaryColor;
  @override
  @JsonKey(name: 'privacy_policy_url')
  String get privacyPolicyUrl;
  @override
  @JsonKey(name: 'terms_url')
  String get termsUrl;

  /// Create a copy of AppSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSettingsModelImplCopyWith<_$AppSettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChurchSettingsModel _$ChurchSettingsModelFromJson(Map<String, dynamic> json) {
  return _ChurchSettingsModel.fromJson(json);
}

/// @nodoc
mixin _$ChurchSettingsModel {
  @JsonKey(name: 'church_name')
  String get churchName => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get whatsapp => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get website => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;

  /// Serializes this ChurchSettingsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChurchSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChurchSettingsModelCopyWith<ChurchSettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChurchSettingsModelCopyWith<$Res> {
  factory $ChurchSettingsModelCopyWith(
    ChurchSettingsModel value,
    $Res Function(ChurchSettingsModel) then,
  ) = _$ChurchSettingsModelCopyWithImpl<$Res, ChurchSettingsModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'church_name') String churchName,
    String address,
    String city,
    String country,
    String phone,
    String whatsapp,
    String email,
    String website,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class _$ChurchSettingsModelCopyWithImpl<$Res, $Val extends ChurchSettingsModel>
    implements $ChurchSettingsModelCopyWith<$Res> {
  _$ChurchSettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChurchSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? churchName = null,
    Object? address = null,
    Object? city = null,
    Object? country = null,
    Object? phone = null,
    Object? whatsapp = null,
    Object? email = null,
    Object? website = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _value.copyWith(
            churchName: null == churchName
                ? _value.churchName
                : churchName // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            whatsapp: null == whatsapp
                ? _value.whatsapp
                : whatsapp // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            website: null == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChurchSettingsModelImplCopyWith<$Res>
    implements $ChurchSettingsModelCopyWith<$Res> {
  factory _$$ChurchSettingsModelImplCopyWith(
    _$ChurchSettingsModelImpl value,
    $Res Function(_$ChurchSettingsModelImpl) then,
  ) = __$$ChurchSettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'church_name') String churchName,
    String address,
    String city,
    String country,
    String phone,
    String whatsapp,
    String email,
    String website,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class __$$ChurchSettingsModelImplCopyWithImpl<$Res>
    extends _$ChurchSettingsModelCopyWithImpl<$Res, _$ChurchSettingsModelImpl>
    implements _$$ChurchSettingsModelImplCopyWith<$Res> {
  __$$ChurchSettingsModelImplCopyWithImpl(
    _$ChurchSettingsModelImpl _value,
    $Res Function(_$ChurchSettingsModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChurchSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? churchName = null,
    Object? address = null,
    Object? city = null,
    Object? country = null,
    Object? phone = null,
    Object? whatsapp = null,
    Object? email = null,
    Object? website = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _$ChurchSettingsModelImpl(
        churchName: null == churchName
            ? _value.churchName
            : churchName // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        whatsapp: null == whatsapp
            ? _value.whatsapp
            : whatsapp // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        website: null == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChurchSettingsModelImpl implements _ChurchSettingsModel {
  const _$ChurchSettingsModelImpl({
    @JsonKey(name: 'church_name') required this.churchName,
    required this.address,
    required this.city,
    required this.country,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.website,
    this.latitude,
    this.longitude,
  });

  factory _$ChurchSettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChurchSettingsModelImplFromJson(json);

  @override
  @JsonKey(name: 'church_name')
  final String churchName;
  @override
  final String address;
  @override
  final String city;
  @override
  final String country;
  @override
  final String phone;
  @override
  final String whatsapp;
  @override
  final String email;
  @override
  final String website;
  @override
  final double? latitude;
  @override
  final double? longitude;

  @override
  String toString() {
    return 'ChurchSettingsModel(churchName: $churchName, address: $address, city: $city, country: $country, phone: $phone, whatsapp: $whatsapp, email: $email, website: $website, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChurchSettingsModelImpl &&
            (identical(other.churchName, churchName) ||
                other.churchName == churchName) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.whatsapp, whatsapp) ||
                other.whatsapp == whatsapp) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    churchName,
    address,
    city,
    country,
    phone,
    whatsapp,
    email,
    website,
    latitude,
    longitude,
  );

  /// Create a copy of ChurchSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChurchSettingsModelImplCopyWith<_$ChurchSettingsModelImpl> get copyWith =>
      __$$ChurchSettingsModelImplCopyWithImpl<_$ChurchSettingsModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChurchSettingsModelImplToJson(this);
  }
}

abstract class _ChurchSettingsModel implements ChurchSettingsModel {
  const factory _ChurchSettingsModel({
    @JsonKey(name: 'church_name') required final String churchName,
    required final String address,
    required final String city,
    required final String country,
    required final String phone,
    required final String whatsapp,
    required final String email,
    required final String website,
    final double? latitude,
    final double? longitude,
  }) = _$ChurchSettingsModelImpl;

  factory _ChurchSettingsModel.fromJson(Map<String, dynamic> json) =
      _$ChurchSettingsModelImpl.fromJson;

  @override
  @JsonKey(name: 'church_name')
  String get churchName;
  @override
  String get address;
  @override
  String get city;
  @override
  String get country;
  @override
  String get phone;
  @override
  String get whatsapp;
  @override
  String get email;
  @override
  String get website;
  @override
  double? get latitude;
  @override
  double? get longitude;

  /// Create a copy of ChurchSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChurchSettingsModelImplCopyWith<_$ChurchSettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ServiceScheduleModel _$ServiceScheduleModelFromJson(Map<String, dynamic> json) {
  return _ServiceScheduleModel.fromJson(json);
}

/// @nodoc
mixin _$ServiceScheduleModel {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'day_of_week')
  String get dayOfWeek => throw _privateConstructorUsedError;
  @JsonKey(name: 'day_of_week_display')
  String get dayOfWeekDisplay => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  String get startTime => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Serializes this ServiceScheduleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServiceScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceScheduleModelCopyWith<ServiceScheduleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceScheduleModelCopyWith<$Res> {
  factory $ServiceScheduleModelCopyWith(
    ServiceScheduleModel value,
    $Res Function(ServiceScheduleModel) then,
  ) = _$ServiceScheduleModelCopyWithImpl<$Res, ServiceScheduleModel>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'day_of_week') String dayOfWeek,
    @JsonKey(name: 'day_of_week_display') String dayOfWeekDisplay,
    @JsonKey(name: 'start_time') String startTime,
    String title,
    String description,
  });
}

/// @nodoc
class _$ServiceScheduleModelCopyWithImpl<
  $Res,
  $Val extends ServiceScheduleModel
>
    implements $ServiceScheduleModelCopyWith<$Res> {
  _$ServiceScheduleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayOfWeek = null,
    Object? dayOfWeekDisplay = null,
    Object? startTime = null,
    Object? title = null,
    Object? description = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            dayOfWeek: null == dayOfWeek
                ? _value.dayOfWeek
                : dayOfWeek // ignore: cast_nullable_to_non_nullable
                      as String,
            dayOfWeekDisplay: null == dayOfWeekDisplay
                ? _value.dayOfWeekDisplay
                : dayOfWeekDisplay // ignore: cast_nullable_to_non_nullable
                      as String,
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceScheduleModelImplCopyWith<$Res>
    implements $ServiceScheduleModelCopyWith<$Res> {
  factory _$$ServiceScheduleModelImplCopyWith(
    _$ServiceScheduleModelImpl value,
    $Res Function(_$ServiceScheduleModelImpl) then,
  ) = __$$ServiceScheduleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'day_of_week') String dayOfWeek,
    @JsonKey(name: 'day_of_week_display') String dayOfWeekDisplay,
    @JsonKey(name: 'start_time') String startTime,
    String title,
    String description,
  });
}

/// @nodoc
class __$$ServiceScheduleModelImplCopyWithImpl<$Res>
    extends _$ServiceScheduleModelCopyWithImpl<$Res, _$ServiceScheduleModelImpl>
    implements _$$ServiceScheduleModelImplCopyWith<$Res> {
  __$$ServiceScheduleModelImplCopyWithImpl(
    _$ServiceScheduleModelImpl _value,
    $Res Function(_$ServiceScheduleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayOfWeek = null,
    Object? dayOfWeekDisplay = null,
    Object? startTime = null,
    Object? title = null,
    Object? description = null,
  }) {
    return _then(
      _$ServiceScheduleModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        dayOfWeek: null == dayOfWeek
            ? _value.dayOfWeek
            : dayOfWeek // ignore: cast_nullable_to_non_nullable
                  as String,
        dayOfWeekDisplay: null == dayOfWeekDisplay
            ? _value.dayOfWeekDisplay
            : dayOfWeekDisplay // ignore: cast_nullable_to_non_nullable
                  as String,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceScheduleModelImpl implements _ServiceScheduleModel {
  const _$ServiceScheduleModelImpl({
    required this.id,
    @JsonKey(name: 'day_of_week') required this.dayOfWeek,
    @JsonKey(name: 'day_of_week_display') required this.dayOfWeekDisplay,
    @JsonKey(name: 'start_time') required this.startTime,
    required this.title,
    required this.description,
  });

  factory _$ServiceScheduleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceScheduleModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'day_of_week')
  final String dayOfWeek;
  @override
  @JsonKey(name: 'day_of_week_display')
  final String dayOfWeekDisplay;
  @override
  @JsonKey(name: 'start_time')
  final String startTime;
  @override
  final String title;
  @override
  final String description;

  @override
  String toString() {
    return 'ServiceScheduleModel(id: $id, dayOfWeek: $dayOfWeek, dayOfWeekDisplay: $dayOfWeekDisplay, startTime: $startTime, title: $title, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceScheduleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.dayOfWeekDisplay, dayOfWeekDisplay) ||
                other.dayOfWeekDisplay == dayOfWeekDisplay) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    dayOfWeek,
    dayOfWeekDisplay,
    startTime,
    title,
    description,
  );

  /// Create a copy of ServiceScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceScheduleModelImplCopyWith<_$ServiceScheduleModelImpl>
  get copyWith =>
      __$$ServiceScheduleModelImplCopyWithImpl<_$ServiceScheduleModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceScheduleModelImplToJson(this);
  }
}

abstract class _ServiceScheduleModel implements ServiceScheduleModel {
  const factory _ServiceScheduleModel({
    required final int id,
    @JsonKey(name: 'day_of_week') required final String dayOfWeek,
    @JsonKey(name: 'day_of_week_display')
    required final String dayOfWeekDisplay,
    @JsonKey(name: 'start_time') required final String startTime,
    required final String title,
    required final String description,
  }) = _$ServiceScheduleModelImpl;

  factory _ServiceScheduleModel.fromJson(Map<String, dynamic> json) =
      _$ServiceScheduleModelImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'day_of_week')
  String get dayOfWeek;
  @override
  @JsonKey(name: 'day_of_week_display')
  String get dayOfWeekDisplay;
  @override
  @JsonKey(name: 'start_time')
  String get startTime;
  @override
  String get title;
  @override
  String get description;

  /// Create a copy of ServiceScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceScheduleModelImplCopyWith<_$ServiceScheduleModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SocialNetworkModel _$SocialNetworkModelFromJson(Map<String, dynamic> json) {
  return _SocialNetworkModel.fromJson(json);
}

/// @nodoc
mixin _$SocialNetworkModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_name')
  String get iconName => throw _privateConstructorUsedError;

  /// Serializes this SocialNetworkModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SocialNetworkModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SocialNetworkModelCopyWith<SocialNetworkModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SocialNetworkModelCopyWith<$Res> {
  factory $SocialNetworkModelCopyWith(
    SocialNetworkModel value,
    $Res Function(SocialNetworkModel) then,
  ) = _$SocialNetworkModelCopyWithImpl<$Res, SocialNetworkModel>;
  @useResult
  $Res call({
    int id,
    String name,
    String url,
    @JsonKey(name: 'icon_name') String iconName,
  });
}

/// @nodoc
class _$SocialNetworkModelCopyWithImpl<$Res, $Val extends SocialNetworkModel>
    implements $SocialNetworkModelCopyWith<$Res> {
  _$SocialNetworkModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SocialNetworkModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? url = null,
    Object? iconName = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            iconName: null == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SocialNetworkModelImplCopyWith<$Res>
    implements $SocialNetworkModelCopyWith<$Res> {
  factory _$$SocialNetworkModelImplCopyWith(
    _$SocialNetworkModelImpl value,
    $Res Function(_$SocialNetworkModelImpl) then,
  ) = __$$SocialNetworkModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String url,
    @JsonKey(name: 'icon_name') String iconName,
  });
}

/// @nodoc
class __$$SocialNetworkModelImplCopyWithImpl<$Res>
    extends _$SocialNetworkModelCopyWithImpl<$Res, _$SocialNetworkModelImpl>
    implements _$$SocialNetworkModelImplCopyWith<$Res> {
  __$$SocialNetworkModelImplCopyWithImpl(
    _$SocialNetworkModelImpl _value,
    $Res Function(_$SocialNetworkModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SocialNetworkModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? url = null,
    Object? iconName = null,
  }) {
    return _then(
      _$SocialNetworkModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        iconName: null == iconName
            ? _value.iconName
            : iconName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SocialNetworkModelImpl implements _SocialNetworkModel {
  const _$SocialNetworkModelImpl({
    required this.id,
    required this.name,
    required this.url,
    @JsonKey(name: 'icon_name') required this.iconName,
  });

  factory _$SocialNetworkModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SocialNetworkModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String url;
  @override
  @JsonKey(name: 'icon_name')
  final String iconName;

  @override
  String toString() {
    return 'SocialNetworkModel(id: $id, name: $name, url: $url, iconName: $iconName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SocialNetworkModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, url, iconName);

  /// Create a copy of SocialNetworkModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SocialNetworkModelImplCopyWith<_$SocialNetworkModelImpl> get copyWith =>
      __$$SocialNetworkModelImplCopyWithImpl<_$SocialNetworkModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SocialNetworkModelImplToJson(this);
  }
}

abstract class _SocialNetworkModel implements SocialNetworkModel {
  const factory _SocialNetworkModel({
    required final int id,
    required final String name,
    required final String url,
    @JsonKey(name: 'icon_name') required final String iconName,
  }) = _$SocialNetworkModelImpl;

  factory _SocialNetworkModel.fromJson(Map<String, dynamic> json) =
      _$SocialNetworkModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get url;
  @override
  @JsonKey(name: 'icon_name')
  String get iconName;

  /// Create a copy of SocialNetworkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SocialNetworkModelImplCopyWith<_$SocialNetworkModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PublicSettingsModel _$PublicSettingsModelFromJson(Map<String, dynamic> json) {
  return _PublicSettingsModel.fromJson(json);
}

/// @nodoc
mixin _$PublicSettingsModel {
  AppSettingsModel get app => throw _privateConstructorUsedError;
  ChurchSettingsModel get church => throw _privateConstructorUsedError;
  List<ServiceScheduleModel> get schedules =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'social_networks')
  List<SocialNetworkModel> get socialNetworks =>
      throw _privateConstructorUsedError;

  /// Serializes this PublicSettingsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicSettingsModelCopyWith<PublicSettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicSettingsModelCopyWith<$Res> {
  factory $PublicSettingsModelCopyWith(
    PublicSettingsModel value,
    $Res Function(PublicSettingsModel) then,
  ) = _$PublicSettingsModelCopyWithImpl<$Res, PublicSettingsModel>;
  @useResult
  $Res call({
    AppSettingsModel app,
    ChurchSettingsModel church,
    List<ServiceScheduleModel> schedules,
    @JsonKey(name: 'social_networks') List<SocialNetworkModel> socialNetworks,
  });

  $AppSettingsModelCopyWith<$Res> get app;
  $ChurchSettingsModelCopyWith<$Res> get church;
}

/// @nodoc
class _$PublicSettingsModelCopyWithImpl<$Res, $Val extends PublicSettingsModel>
    implements $PublicSettingsModelCopyWith<$Res> {
  _$PublicSettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? app = null,
    Object? church = null,
    Object? schedules = null,
    Object? socialNetworks = null,
  }) {
    return _then(
      _value.copyWith(
            app: null == app
                ? _value.app
                : app // ignore: cast_nullable_to_non_nullable
                      as AppSettingsModel,
            church: null == church
                ? _value.church
                : church // ignore: cast_nullable_to_non_nullable
                      as ChurchSettingsModel,
            schedules: null == schedules
                ? _value.schedules
                : schedules // ignore: cast_nullable_to_non_nullable
                      as List<ServiceScheduleModel>,
            socialNetworks: null == socialNetworks
                ? _value.socialNetworks
                : socialNetworks // ignore: cast_nullable_to_non_nullable
                      as List<SocialNetworkModel>,
          )
          as $Val,
    );
  }

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppSettingsModelCopyWith<$Res> get app {
    return $AppSettingsModelCopyWith<$Res>(_value.app, (value) {
      return _then(_value.copyWith(app: value) as $Val);
    });
  }

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChurchSettingsModelCopyWith<$Res> get church {
    return $ChurchSettingsModelCopyWith<$Res>(_value.church, (value) {
      return _then(_value.copyWith(church: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PublicSettingsModelImplCopyWith<$Res>
    implements $PublicSettingsModelCopyWith<$Res> {
  factory _$$PublicSettingsModelImplCopyWith(
    _$PublicSettingsModelImpl value,
    $Res Function(_$PublicSettingsModelImpl) then,
  ) = __$$PublicSettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AppSettingsModel app,
    ChurchSettingsModel church,
    List<ServiceScheduleModel> schedules,
    @JsonKey(name: 'social_networks') List<SocialNetworkModel> socialNetworks,
  });

  @override
  $AppSettingsModelCopyWith<$Res> get app;
  @override
  $ChurchSettingsModelCopyWith<$Res> get church;
}

/// @nodoc
class __$$PublicSettingsModelImplCopyWithImpl<$Res>
    extends _$PublicSettingsModelCopyWithImpl<$Res, _$PublicSettingsModelImpl>
    implements _$$PublicSettingsModelImplCopyWith<$Res> {
  __$$PublicSettingsModelImplCopyWithImpl(
    _$PublicSettingsModelImpl _value,
    $Res Function(_$PublicSettingsModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? app = null,
    Object? church = null,
    Object? schedules = null,
    Object? socialNetworks = null,
  }) {
    return _then(
      _$PublicSettingsModelImpl(
        app: null == app
            ? _value.app
            : app // ignore: cast_nullable_to_non_nullable
                  as AppSettingsModel,
        church: null == church
            ? _value.church
            : church // ignore: cast_nullable_to_non_nullable
                  as ChurchSettingsModel,
        schedules: null == schedules
            ? _value._schedules
            : schedules // ignore: cast_nullable_to_non_nullable
                  as List<ServiceScheduleModel>,
        socialNetworks: null == socialNetworks
            ? _value._socialNetworks
            : socialNetworks // ignore: cast_nullable_to_non_nullable
                  as List<SocialNetworkModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicSettingsModelImpl implements _PublicSettingsModel {
  const _$PublicSettingsModelImpl({
    required this.app,
    required this.church,
    required final List<ServiceScheduleModel> schedules,
    @JsonKey(name: 'social_networks')
    required final List<SocialNetworkModel> socialNetworks,
  }) : _schedules = schedules,
       _socialNetworks = socialNetworks;

  factory _$PublicSettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicSettingsModelImplFromJson(json);

  @override
  final AppSettingsModel app;
  @override
  final ChurchSettingsModel church;
  final List<ServiceScheduleModel> _schedules;
  @override
  List<ServiceScheduleModel> get schedules {
    if (_schedules is EqualUnmodifiableListView) return _schedules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_schedules);
  }

  final List<SocialNetworkModel> _socialNetworks;
  @override
  @JsonKey(name: 'social_networks')
  List<SocialNetworkModel> get socialNetworks {
    if (_socialNetworks is EqualUnmodifiableListView) return _socialNetworks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_socialNetworks);
  }

  @override
  String toString() {
    return 'PublicSettingsModel(app: $app, church: $church, schedules: $schedules, socialNetworks: $socialNetworks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicSettingsModelImpl &&
            (identical(other.app, app) || other.app == app) &&
            (identical(other.church, church) || other.church == church) &&
            const DeepCollectionEquality().equals(
              other._schedules,
              _schedules,
            ) &&
            const DeepCollectionEquality().equals(
              other._socialNetworks,
              _socialNetworks,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    app,
    church,
    const DeepCollectionEquality().hash(_schedules),
    const DeepCollectionEquality().hash(_socialNetworks),
  );

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicSettingsModelImplCopyWith<_$PublicSettingsModelImpl> get copyWith =>
      __$$PublicSettingsModelImplCopyWithImpl<_$PublicSettingsModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicSettingsModelImplToJson(this);
  }
}

abstract class _PublicSettingsModel implements PublicSettingsModel {
  const factory _PublicSettingsModel({
    required final AppSettingsModel app,
    required final ChurchSettingsModel church,
    required final List<ServiceScheduleModel> schedules,
    @JsonKey(name: 'social_networks')
    required final List<SocialNetworkModel> socialNetworks,
  }) = _$PublicSettingsModelImpl;

  factory _PublicSettingsModel.fromJson(Map<String, dynamic> json) =
      _$PublicSettingsModelImpl.fromJson;

  @override
  AppSettingsModel get app;
  @override
  ChurchSettingsModel get church;
  @override
  List<ServiceScheduleModel> get schedules;
  @override
  @JsonKey(name: 'social_networks')
  List<SocialNetworkModel> get socialNetworks;

  /// Create a copy of PublicSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicSettingsModelImplCopyWith<_$PublicSettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

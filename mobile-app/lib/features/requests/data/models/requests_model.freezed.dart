// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'requests_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PrayerRequestModel _$PrayerRequestModelFromJson(Map<String, dynamic> json) {
  return _PrayerRequestModel.fromJson(json);
}

/// @nodoc
mixin _$PrayerRequestModel {
  @JsonKey(name: 'requester_name')
  String get requesterName => throw _privateConstructorUsedError;
  @JsonKey(name: 'requester_email')
  String? get requesterEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'requester_phone')
  String? get requesterPhone => throw _privateConstructorUsedError;
  String get subject => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_anonymous')
  bool get isAnonymous => throw _privateConstructorUsedError;

  /// Serializes this PrayerRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrayerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrayerRequestModelCopyWith<PrayerRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrayerRequestModelCopyWith<$Res> {
  factory $PrayerRequestModelCopyWith(
    PrayerRequestModel value,
    $Res Function(PrayerRequestModel) then,
  ) = _$PrayerRequestModelCopyWithImpl<$Res, PrayerRequestModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'requester_name') String requesterName,
    @JsonKey(name: 'requester_email') String? requesterEmail,
    @JsonKey(name: 'requester_phone') String? requesterPhone,
    String subject,
    String description,
    @JsonKey(name: 'is_anonymous') bool isAnonymous,
  });
}

/// @nodoc
class _$PrayerRequestModelCopyWithImpl<$Res, $Val extends PrayerRequestModel>
    implements $PrayerRequestModelCopyWith<$Res> {
  _$PrayerRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrayerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requesterName = null,
    Object? requesterEmail = freezed,
    Object? requesterPhone = freezed,
    Object? subject = null,
    Object? description = null,
    Object? isAnonymous = null,
  }) {
    return _then(
      _value.copyWith(
            requesterName: null == requesterName
                ? _value.requesterName
                : requesterName // ignore: cast_nullable_to_non_nullable
                      as String,
            requesterEmail: freezed == requesterEmail
                ? _value.requesterEmail
                : requesterEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            requesterPhone: freezed == requesterPhone
                ? _value.requesterPhone
                : requesterPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            isAnonymous: null == isAnonymous
                ? _value.isAnonymous
                : isAnonymous // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PrayerRequestModelImplCopyWith<$Res>
    implements $PrayerRequestModelCopyWith<$Res> {
  factory _$$PrayerRequestModelImplCopyWith(
    _$PrayerRequestModelImpl value,
    $Res Function(_$PrayerRequestModelImpl) then,
  ) = __$$PrayerRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'requester_name') String requesterName,
    @JsonKey(name: 'requester_email') String? requesterEmail,
    @JsonKey(name: 'requester_phone') String? requesterPhone,
    String subject,
    String description,
    @JsonKey(name: 'is_anonymous') bool isAnonymous,
  });
}

/// @nodoc
class __$$PrayerRequestModelImplCopyWithImpl<$Res>
    extends _$PrayerRequestModelCopyWithImpl<$Res, _$PrayerRequestModelImpl>
    implements _$$PrayerRequestModelImplCopyWith<$Res> {
  __$$PrayerRequestModelImplCopyWithImpl(
    _$PrayerRequestModelImpl _value,
    $Res Function(_$PrayerRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrayerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requesterName = null,
    Object? requesterEmail = freezed,
    Object? requesterPhone = freezed,
    Object? subject = null,
    Object? description = null,
    Object? isAnonymous = null,
  }) {
    return _then(
      _$PrayerRequestModelImpl(
        requesterName: null == requesterName
            ? _value.requesterName
            : requesterName // ignore: cast_nullable_to_non_nullable
                  as String,
        requesterEmail: freezed == requesterEmail
            ? _value.requesterEmail
            : requesterEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        requesterPhone: freezed == requesterPhone
            ? _value.requesterPhone
            : requesterPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        isAnonymous: null == isAnonymous
            ? _value.isAnonymous
            : isAnonymous // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrayerRequestModelImpl implements _PrayerRequestModel {
  const _$PrayerRequestModelImpl({
    @JsonKey(name: 'requester_name') required this.requesterName,
    @JsonKey(name: 'requester_email') this.requesterEmail,
    @JsonKey(name: 'requester_phone') this.requesterPhone,
    required this.subject,
    required this.description,
    @JsonKey(name: 'is_anonymous') required this.isAnonymous,
  });

  factory _$PrayerRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrayerRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'requester_name')
  final String requesterName;
  @override
  @JsonKey(name: 'requester_email')
  final String? requesterEmail;
  @override
  @JsonKey(name: 'requester_phone')
  final String? requesterPhone;
  @override
  final String subject;
  @override
  final String description;
  @override
  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;

  @override
  String toString() {
    return 'PrayerRequestModel(requesterName: $requesterName, requesterEmail: $requesterEmail, requesterPhone: $requesterPhone, subject: $subject, description: $description, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrayerRequestModelImpl &&
            (identical(other.requesterName, requesterName) ||
                other.requesterName == requesterName) &&
            (identical(other.requesterEmail, requesterEmail) ||
                other.requesterEmail == requesterEmail) &&
            (identical(other.requesterPhone, requesterPhone) ||
                other.requesterPhone == requesterPhone) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isAnonymous, isAnonymous) ||
                other.isAnonymous == isAnonymous));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    requesterName,
    requesterEmail,
    requesterPhone,
    subject,
    description,
    isAnonymous,
  );

  /// Create a copy of PrayerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrayerRequestModelImplCopyWith<_$PrayerRequestModelImpl> get copyWith =>
      __$$PrayerRequestModelImplCopyWithImpl<_$PrayerRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PrayerRequestModelImplToJson(this);
  }
}

abstract class _PrayerRequestModel implements PrayerRequestModel {
  const factory _PrayerRequestModel({
    @JsonKey(name: 'requester_name') required final String requesterName,
    @JsonKey(name: 'requester_email') final String? requesterEmail,
    @JsonKey(name: 'requester_phone') final String? requesterPhone,
    required final String subject,
    required final String description,
    @JsonKey(name: 'is_anonymous') required final bool isAnonymous,
  }) = _$PrayerRequestModelImpl;

  factory _PrayerRequestModel.fromJson(Map<String, dynamic> json) =
      _$PrayerRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'requester_name')
  String get requesterName;
  @override
  @JsonKey(name: 'requester_email')
  String? get requesterEmail;
  @override
  @JsonKey(name: 'requester_phone')
  String? get requesterPhone;
  @override
  String get subject;
  @override
  String get description;
  @override
  @JsonKey(name: 'is_anonymous')
  bool get isAnonymous;

  /// Create a copy of PrayerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrayerRequestModelImplCopyWith<_$PrayerRequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisitorRequestModel _$VisitorRequestModelFromJson(Map<String, dynamic> json) {
  return _VisitorRequestModel.fromJson(json);
}

/// @nodoc
mixin _$VisitorRequestModel {
  @JsonKey(name: 'full_name')
  String get fullName => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'age_range')
  String get ageRange => throw _privateConstructorUsedError;
  @JsonKey(name: 'how_did_you_find_us')
  String get howDidYouFindUs => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: 'preferred_contact')
  String get preferredContact => throw _privateConstructorUsedError;
  @JsonKey(name: 'cell_group_id')
  int? get cellGroupId => throw _privateConstructorUsedError;

  /// Serializes this VisitorRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisitorRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisitorRequestModelCopyWith<VisitorRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisitorRequestModelCopyWith<$Res> {
  factory $VisitorRequestModelCopyWith(
    VisitorRequestModel value,
    $Res Function(VisitorRequestModel) then,
  ) = _$VisitorRequestModelCopyWithImpl<$Res, VisitorRequestModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'full_name') String fullName,
    String? email,
    String? phone,
    @JsonKey(name: 'age_range') String ageRange,
    @JsonKey(name: 'how_did_you_find_us') String howDidYouFindUs,
    String message,
    @JsonKey(name: 'preferred_contact') String preferredContact,
    @JsonKey(name: 'cell_group_id') int? cellGroupId,
  });
}

/// @nodoc
class _$VisitorRequestModelCopyWithImpl<$Res, $Val extends VisitorRequestModel>
    implements $VisitorRequestModelCopyWith<$Res> {
  _$VisitorRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisitorRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? ageRange = null,
    Object? howDidYouFindUs = null,
    Object? message = null,
    Object? preferredContact = null,
    Object? cellGroupId = freezed,
  }) {
    return _then(
      _value.copyWith(
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            ageRange: null == ageRange
                ? _value.ageRange
                : ageRange // ignore: cast_nullable_to_non_nullable
                      as String,
            howDidYouFindUs: null == howDidYouFindUs
                ? _value.howDidYouFindUs
                : howDidYouFindUs // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            preferredContact: null == preferredContact
                ? _value.preferredContact
                : preferredContact // ignore: cast_nullable_to_non_nullable
                      as String,
            cellGroupId: freezed == cellGroupId
                ? _value.cellGroupId
                : cellGroupId // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VisitorRequestModelImplCopyWith<$Res>
    implements $VisitorRequestModelCopyWith<$Res> {
  factory _$$VisitorRequestModelImplCopyWith(
    _$VisitorRequestModelImpl value,
    $Res Function(_$VisitorRequestModelImpl) then,
  ) = __$$VisitorRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'full_name') String fullName,
    String? email,
    String? phone,
    @JsonKey(name: 'age_range') String ageRange,
    @JsonKey(name: 'how_did_you_find_us') String howDidYouFindUs,
    String message,
    @JsonKey(name: 'preferred_contact') String preferredContact,
    @JsonKey(name: 'cell_group_id') int? cellGroupId,
  });
}

/// @nodoc
class __$$VisitorRequestModelImplCopyWithImpl<$Res>
    extends _$VisitorRequestModelCopyWithImpl<$Res, _$VisitorRequestModelImpl>
    implements _$$VisitorRequestModelImplCopyWith<$Res> {
  __$$VisitorRequestModelImplCopyWithImpl(
    _$VisitorRequestModelImpl _value,
    $Res Function(_$VisitorRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VisitorRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? ageRange = null,
    Object? howDidYouFindUs = null,
    Object? message = null,
    Object? preferredContact = null,
    Object? cellGroupId = freezed,
  }) {
    return _then(
      _$VisitorRequestModelImpl(
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        ageRange: null == ageRange
            ? _value.ageRange
            : ageRange // ignore: cast_nullable_to_non_nullable
                  as String,
        howDidYouFindUs: null == howDidYouFindUs
            ? _value.howDidYouFindUs
            : howDidYouFindUs // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        preferredContact: null == preferredContact
            ? _value.preferredContact
            : preferredContact // ignore: cast_nullable_to_non_nullable
                  as String,
        cellGroupId: freezed == cellGroupId
            ? _value.cellGroupId
            : cellGroupId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VisitorRequestModelImpl implements _VisitorRequestModel {
  const _$VisitorRequestModelImpl({
    @JsonKey(name: 'full_name') required this.fullName,
    this.email,
    this.phone,
    @JsonKey(name: 'age_range') required this.ageRange,
    @JsonKey(name: 'how_did_you_find_us') required this.howDidYouFindUs,
    required this.message,
    @JsonKey(name: 'preferred_contact') required this.preferredContact,
    @JsonKey(name: 'cell_group_id') this.cellGroupId,
  });

  factory _$VisitorRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisitorRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'full_name')
  final String fullName;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'age_range')
  final String ageRange;
  @override
  @JsonKey(name: 'how_did_you_find_us')
  final String howDidYouFindUs;
  @override
  final String message;
  @override
  @JsonKey(name: 'preferred_contact')
  final String preferredContact;
  @override
  @JsonKey(name: 'cell_group_id')
  final int? cellGroupId;

  @override
  String toString() {
    return 'VisitorRequestModel(fullName: $fullName, email: $email, phone: $phone, ageRange: $ageRange, howDidYouFindUs: $howDidYouFindUs, message: $message, preferredContact: $preferredContact, cellGroupId: $cellGroupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisitorRequestModelImpl &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.ageRange, ageRange) ||
                other.ageRange == ageRange) &&
            (identical(other.howDidYouFindUs, howDidYouFindUs) ||
                other.howDidYouFindUs == howDidYouFindUs) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.preferredContact, preferredContact) ||
                other.preferredContact == preferredContact) &&
            (identical(other.cellGroupId, cellGroupId) ||
                other.cellGroupId == cellGroupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fullName,
    email,
    phone,
    ageRange,
    howDidYouFindUs,
    message,
    preferredContact,
    cellGroupId,
  );

  /// Create a copy of VisitorRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisitorRequestModelImplCopyWith<_$VisitorRequestModelImpl> get copyWith =>
      __$$VisitorRequestModelImplCopyWithImpl<_$VisitorRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VisitorRequestModelImplToJson(this);
  }
}

abstract class _VisitorRequestModel implements VisitorRequestModel {
  const factory _VisitorRequestModel({
    @JsonKey(name: 'full_name') required final String fullName,
    final String? email,
    final String? phone,
    @JsonKey(name: 'age_range') required final String ageRange,
    @JsonKey(name: 'how_did_you_find_us') required final String howDidYouFindUs,
    required final String message,
    @JsonKey(name: 'preferred_contact') required final String preferredContact,
    @JsonKey(name: 'cell_group_id') final int? cellGroupId,
  }) = _$VisitorRequestModelImpl;

  factory _VisitorRequestModel.fromJson(Map<String, dynamic> json) =
      _$VisitorRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'full_name')
  String get fullName;
  @override
  String? get email;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'age_range')
  String get ageRange;
  @override
  @JsonKey(name: 'how_did_you_find_us')
  String get howDidYouFindUs;
  @override
  String get message;
  @override
  @JsonKey(name: 'preferred_contact')
  String get preferredContact;
  @override
  @JsonKey(name: 'cell_group_id')
  int? get cellGroupId;

  /// Create a copy of VisitorRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisitorRequestModelImplCopyWith<_$VisitorRequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

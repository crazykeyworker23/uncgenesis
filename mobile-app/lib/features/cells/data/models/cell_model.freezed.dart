// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cell_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CellGroupModel _$CellGroupModelFromJson(Map<String, dynamic> json) {
  return _CellGroupModel.fromJson(json);
}

/// @nodoc
mixin _$CellGroupModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  UserModel? get leader => throw _privateConstructorUsedError;
  @JsonKey(name: 'meeting_day')
  String get meetingDay => throw _privateConstructorUsedError;
  @JsonKey(name: 'meeting_time')
  String get meetingTime => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDoubleNullable)
  double? get latitude => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDoubleNullable)
  double? get longitude => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this CellGroupModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CellGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CellGroupModelCopyWith<CellGroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CellGroupModelCopyWith<$Res> {
  factory $CellGroupModelCopyWith(
    CellGroupModel value,
    $Res Function(CellGroupModel) then,
  ) = _$CellGroupModelCopyWithImpl<$Res, CellGroupModel>;
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    UserModel? leader,
    @JsonKey(name: 'meeting_day') String meetingDay,
    @JsonKey(name: 'meeting_time') String meetingTime,
    String address,
    @JsonKey(fromJson: _toDoubleNullable) double? latitude,
    @JsonKey(fromJson: _toDoubleNullable) double? longitude,
    String? description,
    String status,
  });

  $UserModelCopyWith<$Res>? get leader;
}

/// @nodoc
class _$CellGroupModelCopyWithImpl<$Res, $Val extends CellGroupModel>
    implements $CellGroupModelCopyWith<$Res> {
  _$CellGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CellGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? leader = freezed,
    Object? meetingDay = null,
    Object? meetingTime = null,
    Object? address = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? description = freezed,
    Object? status = null,
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
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            leader: freezed == leader
                ? _value.leader
                : leader // ignore: cast_nullable_to_non_nullable
                      as UserModel?,
            meetingDay: null == meetingDay
                ? _value.meetingDay
                : meetingDay // ignore: cast_nullable_to_non_nullable
                      as String,
            meetingTime: null == meetingTime
                ? _value.meetingTime
                : meetingTime // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of CellGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserModelCopyWith<$Res>? get leader {
    if (_value.leader == null) {
      return null;
    }

    return $UserModelCopyWith<$Res>(_value.leader!, (value) {
      return _then(_value.copyWith(leader: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CellGroupModelImplCopyWith<$Res>
    implements $CellGroupModelCopyWith<$Res> {
  factory _$$CellGroupModelImplCopyWith(
    _$CellGroupModelImpl value,
    $Res Function(_$CellGroupModelImpl) then,
  ) = __$$CellGroupModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String slug,
    UserModel? leader,
    @JsonKey(name: 'meeting_day') String meetingDay,
    @JsonKey(name: 'meeting_time') String meetingTime,
    String address,
    @JsonKey(fromJson: _toDoubleNullable) double? latitude,
    @JsonKey(fromJson: _toDoubleNullable) double? longitude,
    String? description,
    String status,
  });

  @override
  $UserModelCopyWith<$Res>? get leader;
}

/// @nodoc
class __$$CellGroupModelImplCopyWithImpl<$Res>
    extends _$CellGroupModelCopyWithImpl<$Res, _$CellGroupModelImpl>
    implements _$$CellGroupModelImplCopyWith<$Res> {
  __$$CellGroupModelImplCopyWithImpl(
    _$CellGroupModelImpl _value,
    $Res Function(_$CellGroupModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CellGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? leader = freezed,
    Object? meetingDay = null,
    Object? meetingTime = null,
    Object? address = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? description = freezed,
    Object? status = null,
  }) {
    return _then(
      _$CellGroupModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        leader: freezed == leader
            ? _value.leader
            : leader // ignore: cast_nullable_to_non_nullable
                  as UserModel?,
        meetingDay: null == meetingDay
            ? _value.meetingDay
            : meetingDay // ignore: cast_nullable_to_non_nullable
                  as String,
        meetingTime: null == meetingTime
            ? _value.meetingTime
            : meetingTime // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CellGroupModelImpl implements _CellGroupModel {
  const _$CellGroupModelImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.leader,
    @JsonKey(name: 'meeting_day') required this.meetingDay,
    @JsonKey(name: 'meeting_time') required this.meetingTime,
    required this.address,
    @JsonKey(fromJson: _toDoubleNullable) this.latitude,
    @JsonKey(fromJson: _toDoubleNullable) this.longitude,
    this.description,
    required this.status,
  });

  factory _$CellGroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CellGroupModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final UserModel? leader;
  @override
  @JsonKey(name: 'meeting_day')
  final String meetingDay;
  @override
  @JsonKey(name: 'meeting_time')
  final String meetingTime;
  @override
  final String address;
  @override
  @JsonKey(fromJson: _toDoubleNullable)
  final double? latitude;
  @override
  @JsonKey(fromJson: _toDoubleNullable)
  final double? longitude;
  @override
  final String? description;
  @override
  final String status;

  @override
  String toString() {
    return 'CellGroupModel(id: $id, name: $name, slug: $slug, leader: $leader, meetingDay: $meetingDay, meetingTime: $meetingTime, address: $address, latitude: $latitude, longitude: $longitude, description: $description, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CellGroupModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.leader, leader) || other.leader == leader) &&
            (identical(other.meetingDay, meetingDay) ||
                other.meetingDay == meetingDay) &&
            (identical(other.meetingTime, meetingTime) ||
                other.meetingTime == meetingTime) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    leader,
    meetingDay,
    meetingTime,
    address,
    latitude,
    longitude,
    description,
    status,
  );

  /// Create a copy of CellGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CellGroupModelImplCopyWith<_$CellGroupModelImpl> get copyWith =>
      __$$CellGroupModelImplCopyWithImpl<_$CellGroupModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CellGroupModelImplToJson(this);
  }
}

abstract class _CellGroupModel implements CellGroupModel {
  const factory _CellGroupModel({
    required final int id,
    required final String name,
    required final String slug,
    final UserModel? leader,
    @JsonKey(name: 'meeting_day') required final String meetingDay,
    @JsonKey(name: 'meeting_time') required final String meetingTime,
    required final String address,
    @JsonKey(fromJson: _toDoubleNullable) final double? latitude,
    @JsonKey(fromJson: _toDoubleNullable) final double? longitude,
    final String? description,
    required final String status,
  }) = _$CellGroupModelImpl;

  factory _CellGroupModel.fromJson(Map<String, dynamic> json) =
      _$CellGroupModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  UserModel? get leader;
  @override
  @JsonKey(name: 'meeting_day')
  String get meetingDay;
  @override
  @JsonKey(name: 'meeting_time')
  String get meetingTime;
  @override
  String get address;
  @override
  @JsonKey(fromJson: _toDoubleNullable)
  double? get latitude;
  @override
  @JsonKey(fromJson: _toDoubleNullable)
  double? get longitude;
  @override
  String? get description;
  @override
  String get status;

  /// Create a copy of CellGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CellGroupModelImplCopyWith<_$CellGroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

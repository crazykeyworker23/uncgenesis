// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EventModel _$EventModelFromJson(Map<String, dynamic> json) {
  return _EventModel.fromJson(json);
}

/// @nodoc
mixin _$EventModel {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_image')
  String? get coverImage => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date')
  String get startDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_date')
  String get endDate => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  int? get capacity => throw _privateConstructorUsedError;
  @JsonKey(name: 'requires_registration')
  bool get requiresRegistration => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'registered_count')
  int? get registeredCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_registered')
  bool? get isRegistered => throw _privateConstructorUsedError;

  /// Serializes this EventModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventModelCopyWith<EventModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventModelCopyWith<$Res> {
  factory $EventModelCopyWith(
    EventModel value,
    $Res Function(EventModel) then,
  ) = _$EventModelCopyWithImpl<$Res, EventModel>;
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String description,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'start_date') String startDate,
    @JsonKey(name: 'end_date') String endDate,
    String location,
    int? capacity,
    @JsonKey(name: 'requires_registration') bool requiresRegistration,
    String status,
    @JsonKey(name: 'registered_count') int? registeredCount,
    @JsonKey(name: 'is_registered') bool? isRegistered,
  });
}

/// @nodoc
class _$EventModelCopyWithImpl<$Res, $Val extends EventModel>
    implements $EventModelCopyWith<$Res> {
  _$EventModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? description = null,
    Object? coverImage = freezed,
    Object? startDate = null,
    Object? endDate = null,
    Object? location = null,
    Object? capacity = freezed,
    Object? requiresRegistration = null,
    Object? status = null,
    Object? registeredCount = freezed,
    Object? isRegistered = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            capacity: freezed == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as int?,
            requiresRegistration: null == requiresRegistration
                ? _value.requiresRegistration
                : requiresRegistration // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            registeredCount: freezed == registeredCount
                ? _value.registeredCount
                : registeredCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            isRegistered: freezed == isRegistered
                ? _value.isRegistered
                : isRegistered // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EventModelImplCopyWith<$Res>
    implements $EventModelCopyWith<$Res> {
  factory _$$EventModelImplCopyWith(
    _$EventModelImpl value,
    $Res Function(_$EventModelImpl) then,
  ) = __$$EventModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String description,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'start_date') String startDate,
    @JsonKey(name: 'end_date') String endDate,
    String location,
    int? capacity,
    @JsonKey(name: 'requires_registration') bool requiresRegistration,
    String status,
    @JsonKey(name: 'registered_count') int? registeredCount,
    @JsonKey(name: 'is_registered') bool? isRegistered,
  });
}

/// @nodoc
class __$$EventModelImplCopyWithImpl<$Res>
    extends _$EventModelCopyWithImpl<$Res, _$EventModelImpl>
    implements _$$EventModelImplCopyWith<$Res> {
  __$$EventModelImplCopyWithImpl(
    _$EventModelImpl _value,
    $Res Function(_$EventModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? description = null,
    Object? coverImage = freezed,
    Object? startDate = null,
    Object? endDate = null,
    Object? location = null,
    Object? capacity = freezed,
    Object? requiresRegistration = null,
    Object? status = null,
    Object? registeredCount = freezed,
    Object? isRegistered = freezed,
  }) {
    return _then(
      _$EventModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        capacity: freezed == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as int?,
        requiresRegistration: null == requiresRegistration
            ? _value.requiresRegistration
            : requiresRegistration // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        registeredCount: freezed == registeredCount
            ? _value.registeredCount
            : registeredCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        isRegistered: freezed == isRegistered
            ? _value.isRegistered
            : isRegistered // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EventModelImpl implements _EventModel {
  const _$EventModelImpl({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    @JsonKey(name: 'cover_image') this.coverImage,
    @JsonKey(name: 'start_date') required this.startDate,
    @JsonKey(name: 'end_date') required this.endDate,
    required this.location,
    this.capacity,
    @JsonKey(name: 'requires_registration') required this.requiresRegistration,
    required this.status,
    @JsonKey(name: 'registered_count') this.registeredCount,
    @JsonKey(name: 'is_registered') this.isRegistered,
  });

  factory _$EventModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String description;
  @override
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  @override
  @JsonKey(name: 'start_date')
  final String startDate;
  @override
  @JsonKey(name: 'end_date')
  final String endDate;
  @override
  final String location;
  @override
  final int? capacity;
  @override
  @JsonKey(name: 'requires_registration')
  final bool requiresRegistration;
  @override
  final String status;
  @override
  @JsonKey(name: 'registered_count')
  final int? registeredCount;
  @override
  @JsonKey(name: 'is_registered')
  final bool? isRegistered;

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, slug: $slug, description: $description, coverImage: $coverImage, startDate: $startDate, endDate: $endDate, location: $location, capacity: $capacity, requiresRegistration: $requiresRegistration, status: $status, registeredCount: $registeredCount, isRegistered: $isRegistered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.requiresRegistration, requiresRegistration) ||
                other.requiresRegistration == requiresRegistration) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.registeredCount, registeredCount) ||
                other.registeredCount == registeredCount) &&
            (identical(other.isRegistered, isRegistered) ||
                other.isRegistered == isRegistered));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    slug,
    description,
    coverImage,
    startDate,
    endDate,
    location,
    capacity,
    requiresRegistration,
    status,
    registeredCount,
    isRegistered,
  );

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventModelImplCopyWith<_$EventModelImpl> get copyWith =>
      __$$EventModelImplCopyWithImpl<_$EventModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventModelImplToJson(this);
  }
}

abstract class _EventModel implements EventModel {
  const factory _EventModel({
    required final int id,
    required final String title,
    required final String slug,
    required final String description,
    @JsonKey(name: 'cover_image') final String? coverImage,
    @JsonKey(name: 'start_date') required final String startDate,
    @JsonKey(name: 'end_date') required final String endDate,
    required final String location,
    final int? capacity,
    @JsonKey(name: 'requires_registration')
    required final bool requiresRegistration,
    required final String status,
    @JsonKey(name: 'registered_count') final int? registeredCount,
    @JsonKey(name: 'is_registered') final bool? isRegistered,
  }) = _$EventModelImpl;

  factory _EventModel.fromJson(Map<String, dynamic> json) =
      _$EventModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String get description;
  @override
  @JsonKey(name: 'cover_image')
  String? get coverImage;
  @override
  @JsonKey(name: 'start_date')
  String get startDate;
  @override
  @JsonKey(name: 'end_date')
  String get endDate;
  @override
  String get location;
  @override
  int? get capacity;
  @override
  @JsonKey(name: 'requires_registration')
  bool get requiresRegistration;
  @override
  String get status;
  @override
  @JsonKey(name: 'registered_count')
  int? get registeredCount;
  @override
  @JsonKey(name: 'is_registered')
  bool? get isRegistered;

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventModelImplCopyWith<_$EventModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'devotional_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DevotionalModel _$DevotionalModelFromJson(Map<String, dynamic> json) {
  return _DevotionalModel.fromJson(json);
}

/// @nodoc
mixin _$DevotionalModel {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'bible_passage')
  String get biblePassage => throw _privateConstructorUsedError;
  @JsonKey(name: 'bible_text')
  String get bibleText => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_url')
  String? get audioUrl => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'views_count')
  int get viewsCount => throw _privateConstructorUsedError;

  /// Serializes this DevotionalModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DevotionalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DevotionalModelCopyWith<DevotionalModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevotionalModelCopyWith<$Res> {
  factory $DevotionalModelCopyWith(
    DevotionalModel value,
    $Res Function(DevotionalModel) then,
  ) = _$DevotionalModelCopyWithImpl<$Res, DevotionalModel>;
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String date,
    @JsonKey(name: 'bible_passage') String biblePassage,
    @JsonKey(name: 'bible_text') String bibleText,
    String content,
    @JsonKey(name: 'audio_url') String? audioUrl,
    String status,
    @JsonKey(name: 'views_count') int viewsCount,
  });
}

/// @nodoc
class _$DevotionalModelCopyWithImpl<$Res, $Val extends DevotionalModel>
    implements $DevotionalModelCopyWith<$Res> {
  _$DevotionalModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DevotionalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? date = null,
    Object? biblePassage = null,
    Object? bibleText = null,
    Object? content = null,
    Object? audioUrl = freezed,
    Object? status = null,
    Object? viewsCount = null,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            biblePassage: null == biblePassage
                ? _value.biblePassage
                : biblePassage // ignore: cast_nullable_to_non_nullable
                      as String,
            bibleText: null == bibleText
                ? _value.bibleText
                : bibleText // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            audioUrl: freezed == audioUrl
                ? _value.audioUrl
                : audioUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            viewsCount: null == viewsCount
                ? _value.viewsCount
                : viewsCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DevotionalModelImplCopyWith<$Res>
    implements $DevotionalModelCopyWith<$Res> {
  factory _$$DevotionalModelImplCopyWith(
    _$DevotionalModelImpl value,
    $Res Function(_$DevotionalModelImpl) then,
  ) = __$$DevotionalModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String date,
    @JsonKey(name: 'bible_passage') String biblePassage,
    @JsonKey(name: 'bible_text') String bibleText,
    String content,
    @JsonKey(name: 'audio_url') String? audioUrl,
    String status,
    @JsonKey(name: 'views_count') int viewsCount,
  });
}

/// @nodoc
class __$$DevotionalModelImplCopyWithImpl<$Res>
    extends _$DevotionalModelCopyWithImpl<$Res, _$DevotionalModelImpl>
    implements _$$DevotionalModelImplCopyWith<$Res> {
  __$$DevotionalModelImplCopyWithImpl(
    _$DevotionalModelImpl _value,
    $Res Function(_$DevotionalModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DevotionalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? date = null,
    Object? biblePassage = null,
    Object? bibleText = null,
    Object? content = null,
    Object? audioUrl = freezed,
    Object? status = null,
    Object? viewsCount = null,
  }) {
    return _then(
      _$DevotionalModelImpl(
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
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        biblePassage: null == biblePassage
            ? _value.biblePassage
            : biblePassage // ignore: cast_nullable_to_non_nullable
                  as String,
        bibleText: null == bibleText
            ? _value.bibleText
            : bibleText // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        audioUrl: freezed == audioUrl
            ? _value.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        viewsCount: null == viewsCount
            ? _value.viewsCount
            : viewsCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DevotionalModelImpl implements _DevotionalModel {
  const _$DevotionalModelImpl({
    required this.id,
    required this.title,
    required this.slug,
    required this.date,
    @JsonKey(name: 'bible_passage') required this.biblePassage,
    @JsonKey(name: 'bible_text') required this.bibleText,
    required this.content,
    @JsonKey(name: 'audio_url') this.audioUrl,
    required this.status,
    @JsonKey(name: 'views_count') required this.viewsCount,
  });

  factory _$DevotionalModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DevotionalModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String date;
  @override
  @JsonKey(name: 'bible_passage')
  final String biblePassage;
  @override
  @JsonKey(name: 'bible_text')
  final String bibleText;
  @override
  final String content;
  @override
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @override
  final String status;
  @override
  @JsonKey(name: 'views_count')
  final int viewsCount;

  @override
  String toString() {
    return 'DevotionalModel(id: $id, title: $title, slug: $slug, date: $date, biblePassage: $biblePassage, bibleText: $bibleText, content: $content, audioUrl: $audioUrl, status: $status, viewsCount: $viewsCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DevotionalModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.biblePassage, biblePassage) ||
                other.biblePassage == biblePassage) &&
            (identical(other.bibleText, bibleText) ||
                other.bibleText == bibleText) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    slug,
    date,
    biblePassage,
    bibleText,
    content,
    audioUrl,
    status,
    viewsCount,
  );

  /// Create a copy of DevotionalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DevotionalModelImplCopyWith<_$DevotionalModelImpl> get copyWith =>
      __$$DevotionalModelImplCopyWithImpl<_$DevotionalModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DevotionalModelImplToJson(this);
  }
}

abstract class _DevotionalModel implements DevotionalModel {
  const factory _DevotionalModel({
    required final int id,
    required final String title,
    required final String slug,
    required final String date,
    @JsonKey(name: 'bible_passage') required final String biblePassage,
    @JsonKey(name: 'bible_text') required final String bibleText,
    required final String content,
    @JsonKey(name: 'audio_url') final String? audioUrl,
    required final String status,
    @JsonKey(name: 'views_count') required final int viewsCount,
  }) = _$DevotionalModelImpl;

  factory _DevotionalModel.fromJson(Map<String, dynamic> json) =
      _$DevotionalModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String get date;
  @override
  @JsonKey(name: 'bible_passage')
  String get biblePassage;
  @override
  @JsonKey(name: 'bible_text')
  String get bibleText;
  @override
  String get content;
  @override
  @JsonKey(name: 'audio_url')
  String? get audioUrl;
  @override
  String get status;
  @override
  @JsonKey(name: 'views_count')
  int get viewsCount;

  /// Create a copy of DevotionalModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DevotionalModelImplCopyWith<_$DevotionalModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

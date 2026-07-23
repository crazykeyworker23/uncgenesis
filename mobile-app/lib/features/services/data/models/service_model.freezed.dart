// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ServiceVerseModel _$ServiceVerseModelFromJson(Map<String, dynamic> json) {
  return _ServiceVerseModel.fromJson(json);
}

/// @nodoc
mixin _$ServiceVerseModel {
  int get id => throw _privateConstructorUsedError;
  String get book => throw _privateConstructorUsedError;
  int get chapter => throw _privateConstructorUsedError;
  String get verses => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;

  /// Serializes this ServiceVerseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServiceVerseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceVerseModelCopyWith<ServiceVerseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceVerseModelCopyWith<$Res> {
  factory $ServiceVerseModelCopyWith(
    ServiceVerseModel value,
    $Res Function(ServiceVerseModel) then,
  ) = _$ServiceVerseModelCopyWithImpl<$Res, ServiceVerseModel>;
  @useResult
  $Res call({int id, String book, int chapter, String verses, String text});
}

/// @nodoc
class _$ServiceVerseModelCopyWithImpl<$Res, $Val extends ServiceVerseModel>
    implements $ServiceVerseModelCopyWith<$Res> {
  _$ServiceVerseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceVerseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? book = null,
    Object? chapter = null,
    Object? verses = null,
    Object? text = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            book: null == book
                ? _value.book
                : book // ignore: cast_nullable_to_non_nullable
                      as String,
            chapter: null == chapter
                ? _value.chapter
                : chapter // ignore: cast_nullable_to_non_nullable
                      as int,
            verses: null == verses
                ? _value.verses
                : verses // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceVerseModelImplCopyWith<$Res>
    implements $ServiceVerseModelCopyWith<$Res> {
  factory _$$ServiceVerseModelImplCopyWith(
    _$ServiceVerseModelImpl value,
    $Res Function(_$ServiceVerseModelImpl) then,
  ) = __$$ServiceVerseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String book, int chapter, String verses, String text});
}

/// @nodoc
class __$$ServiceVerseModelImplCopyWithImpl<$Res>
    extends _$ServiceVerseModelCopyWithImpl<$Res, _$ServiceVerseModelImpl>
    implements _$$ServiceVerseModelImplCopyWith<$Res> {
  __$$ServiceVerseModelImplCopyWithImpl(
    _$ServiceVerseModelImpl _value,
    $Res Function(_$ServiceVerseModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceVerseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? book = null,
    Object? chapter = null,
    Object? verses = null,
    Object? text = null,
  }) {
    return _then(
      _$ServiceVerseModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        book: null == book
            ? _value.book
            : book // ignore: cast_nullable_to_non_nullable
                  as String,
        chapter: null == chapter
            ? _value.chapter
            : chapter // ignore: cast_nullable_to_non_nullable
                  as int,
        verses: null == verses
            ? _value.verses
            : verses // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceVerseModelImpl implements _ServiceVerseModel {
  const _$ServiceVerseModelImpl({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.text,
  });

  factory _$ServiceVerseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceVerseModelImplFromJson(json);

  @override
  final int id;
  @override
  final String book;
  @override
  final int chapter;
  @override
  final String verses;
  @override
  final String text;

  @override
  String toString() {
    return 'ServiceVerseModel(id: $id, book: $book, chapter: $chapter, verses: $verses, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceVerseModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.chapter, chapter) || other.chapter == chapter) &&
            (identical(other.verses, verses) || other.verses == verses) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, book, chapter, verses, text);

  /// Create a copy of ServiceVerseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceVerseModelImplCopyWith<_$ServiceVerseModelImpl> get copyWith =>
      __$$ServiceVerseModelImplCopyWithImpl<_$ServiceVerseModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceVerseModelImplToJson(this);
  }
}

abstract class _ServiceVerseModel implements ServiceVerseModel {
  const factory _ServiceVerseModel({
    required final int id,
    required final String book,
    required final int chapter,
    required final String verses,
    required final String text,
  }) = _$ServiceVerseModelImpl;

  factory _ServiceVerseModel.fromJson(Map<String, dynamic> json) =
      _$ServiceVerseModelImpl.fromJson;

  @override
  int get id;
  @override
  String get book;
  @override
  int get chapter;
  @override
  String get verses;
  @override
  String get text;

  /// Create a copy of ServiceVerseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceVerseModelImplCopyWith<_$ServiceVerseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChurchServiceModel _$ChurchServiceModelFromJson(Map<String, dynamic> json) {
  return _ChurchServiceModel.fromJson(json);
}

/// @nodoc
mixin _$ChurchServiceModel {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'video_url')
  String? get videoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_url')
  String? get audioUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'sermon_notes')
  String? get sermonNotes => throw _privateConstructorUsedError;
  @JsonKey(name: 'views_count')
  int get viewsCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_live')
  bool get isLive => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<ServiceVerseModel> get verses => throw _privateConstructorUsedError;

  /// Serializes this ChurchServiceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChurchServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChurchServiceModelCopyWith<ChurchServiceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChurchServiceModelCopyWith<$Res> {
  factory $ChurchServiceModelCopyWith(
    ChurchServiceModel value,
    $Res Function(ChurchServiceModel) then,
  ) = _$ChurchServiceModelCopyWithImpl<$Res, ChurchServiceModel>;
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String date,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'sermon_notes') String? sermonNotes,
    @JsonKey(name: 'views_count') int viewsCount,
    @JsonKey(name: 'is_live') bool isLive,
    String status,
    List<ServiceVerseModel> verses,
  });
}

/// @nodoc
class _$ChurchServiceModelCopyWithImpl<$Res, $Val extends ChurchServiceModel>
    implements $ChurchServiceModelCopyWith<$Res> {
  _$ChurchServiceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChurchServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? date = null,
    Object? videoUrl = freezed,
    Object? audioUrl = freezed,
    Object? sermonNotes = freezed,
    Object? viewsCount = null,
    Object? isLive = null,
    Object? status = null,
    Object? verses = null,
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
            videoUrl: freezed == videoUrl
                ? _value.videoUrl
                : videoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            audioUrl: freezed == audioUrl
                ? _value.audioUrl
                : audioUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            sermonNotes: freezed == sermonNotes
                ? _value.sermonNotes
                : sermonNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            viewsCount: null == viewsCount
                ? _value.viewsCount
                : viewsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isLive: null == isLive
                ? _value.isLive
                : isLive // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            verses: null == verses
                ? _value.verses
                : verses // ignore: cast_nullable_to_non_nullable
                      as List<ServiceVerseModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChurchServiceModelImplCopyWith<$Res>
    implements $ChurchServiceModelCopyWith<$Res> {
  factory _$$ChurchServiceModelImplCopyWith(
    _$ChurchServiceModelImpl value,
    $Res Function(_$ChurchServiceModelImpl) then,
  ) = __$$ChurchServiceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String date,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'sermon_notes') String? sermonNotes,
    @JsonKey(name: 'views_count') int viewsCount,
    @JsonKey(name: 'is_live') bool isLive,
    String status,
    List<ServiceVerseModel> verses,
  });
}

/// @nodoc
class __$$ChurchServiceModelImplCopyWithImpl<$Res>
    extends _$ChurchServiceModelCopyWithImpl<$Res, _$ChurchServiceModelImpl>
    implements _$$ChurchServiceModelImplCopyWith<$Res> {
  __$$ChurchServiceModelImplCopyWithImpl(
    _$ChurchServiceModelImpl _value,
    $Res Function(_$ChurchServiceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChurchServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? date = null,
    Object? videoUrl = freezed,
    Object? audioUrl = freezed,
    Object? sermonNotes = freezed,
    Object? viewsCount = null,
    Object? isLive = null,
    Object? status = null,
    Object? verses = null,
  }) {
    return _then(
      _$ChurchServiceModelImpl(
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
        videoUrl: freezed == videoUrl
            ? _value.videoUrl
            : videoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioUrl: freezed == audioUrl
            ? _value.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        sermonNotes: freezed == sermonNotes
            ? _value.sermonNotes
            : sermonNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        viewsCount: null == viewsCount
            ? _value.viewsCount
            : viewsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isLive: null == isLive
            ? _value.isLive
            : isLive // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        verses: null == verses
            ? _value._verses
            : verses // ignore: cast_nullable_to_non_nullable
                  as List<ServiceVerseModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChurchServiceModelImpl implements _ChurchServiceModel {
  const _$ChurchServiceModelImpl({
    required this.id,
    required this.title,
    required this.slug,
    required this.date,
    @JsonKey(name: 'video_url') this.videoUrl,
    @JsonKey(name: 'audio_url') this.audioUrl,
    @JsonKey(name: 'sermon_notes') this.sermonNotes,
    @JsonKey(name: 'views_count') required this.viewsCount,
    @JsonKey(name: 'is_live') required this.isLive,
    required this.status,
    final List<ServiceVerseModel> verses = const [],
  }) : _verses = verses;

  factory _$ChurchServiceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChurchServiceModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String date;
  @override
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @override
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @override
  @JsonKey(name: 'sermon_notes')
  final String? sermonNotes;
  @override
  @JsonKey(name: 'views_count')
  final int viewsCount;
  @override
  @JsonKey(name: 'is_live')
  final bool isLive;
  @override
  final String status;
  final List<ServiceVerseModel> _verses;
  @override
  @JsonKey()
  List<ServiceVerseModel> get verses {
    if (_verses is EqualUnmodifiableListView) return _verses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_verses);
  }

  @override
  String toString() {
    return 'ChurchServiceModel(id: $id, title: $title, slug: $slug, date: $date, videoUrl: $videoUrl, audioUrl: $audioUrl, sermonNotes: $sermonNotes, viewsCount: $viewsCount, isLive: $isLive, status: $status, verses: $verses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChurchServiceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.sermonNotes, sermonNotes) ||
                other.sermonNotes == sermonNotes) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount) &&
            (identical(other.isLive, isLive) || other.isLive == isLive) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._verses, _verses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    slug,
    date,
    videoUrl,
    audioUrl,
    sermonNotes,
    viewsCount,
    isLive,
    status,
    const DeepCollectionEquality().hash(_verses),
  );

  /// Create a copy of ChurchServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChurchServiceModelImplCopyWith<_$ChurchServiceModelImpl> get copyWith =>
      __$$ChurchServiceModelImplCopyWithImpl<_$ChurchServiceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChurchServiceModelImplToJson(this);
  }
}

abstract class _ChurchServiceModel implements ChurchServiceModel {
  const factory _ChurchServiceModel({
    required final int id,
    required final String title,
    required final String slug,
    required final String date,
    @JsonKey(name: 'video_url') final String? videoUrl,
    @JsonKey(name: 'audio_url') final String? audioUrl,
    @JsonKey(name: 'sermon_notes') final String? sermonNotes,
    @JsonKey(name: 'views_count') required final int viewsCount,
    @JsonKey(name: 'is_live') required final bool isLive,
    required final String status,
    final List<ServiceVerseModel> verses,
  }) = _$ChurchServiceModelImpl;

  factory _ChurchServiceModel.fromJson(Map<String, dynamic> json) =
      _$ChurchServiceModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String get date;
  @override
  @JsonKey(name: 'video_url')
  String? get videoUrl;
  @override
  @JsonKey(name: 'audio_url')
  String? get audioUrl;
  @override
  @JsonKey(name: 'sermon_notes')
  String? get sermonNotes;
  @override
  @JsonKey(name: 'views_count')
  int get viewsCount;
  @override
  @JsonKey(name: 'is_live')
  bool get isLive;
  @override
  String get status;
  @override
  List<ServiceVerseModel> get verses;

  /// Create a copy of ChurchServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChurchServiceModelImplCopyWith<_$ChurchServiceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

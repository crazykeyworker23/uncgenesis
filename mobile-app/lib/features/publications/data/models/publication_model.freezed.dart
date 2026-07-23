// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'publication_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PublicationCategoryModel _$PublicationCategoryModelFromJson(
  Map<String, dynamic> json,
) {
  return _PublicationCategoryModel.fromJson(json);
}

/// @nodoc
mixin _$PublicationCategoryModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this PublicationCategoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicationCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicationCategoryModelCopyWith<PublicationCategoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicationCategoryModelCopyWith<$Res> {
  factory $PublicationCategoryModelCopyWith(
    PublicationCategoryModel value,
    $Res Function(PublicationCategoryModel) then,
  ) = _$PublicationCategoryModelCopyWithImpl<$Res, PublicationCategoryModel>;
  @useResult
  $Res call({int id, String name, String slug, String? description});
}

/// @nodoc
class _$PublicationCategoryModelCopyWithImpl<
  $Res,
  $Val extends PublicationCategoryModel
>
    implements $PublicationCategoryModelCopyWith<$Res> {
  _$PublicationCategoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicationCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
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
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PublicationCategoryModelImplCopyWith<$Res>
    implements $PublicationCategoryModelCopyWith<$Res> {
  factory _$$PublicationCategoryModelImplCopyWith(
    _$PublicationCategoryModelImpl value,
    $Res Function(_$PublicationCategoryModelImpl) then,
  ) = __$$PublicationCategoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String slug, String? description});
}

/// @nodoc
class __$$PublicationCategoryModelImplCopyWithImpl<$Res>
    extends
        _$PublicationCategoryModelCopyWithImpl<
          $Res,
          _$PublicationCategoryModelImpl
        >
    implements _$$PublicationCategoryModelImplCopyWith<$Res> {
  __$$PublicationCategoryModelImplCopyWithImpl(
    _$PublicationCategoryModelImpl _value,
    $Res Function(_$PublicationCategoryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PublicationCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
  }) {
    return _then(
      _$PublicationCategoryModelImpl(
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
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicationCategoryModelImpl implements _PublicationCategoryModel {
  const _$PublicationCategoryModelImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory _$PublicationCategoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicationCategoryModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;

  @override
  String toString() {
    return 'PublicationCategoryModel(id: $id, name: $name, slug: $slug, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicationCategoryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, slug, description);

  /// Create a copy of PublicationCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicationCategoryModelImplCopyWith<_$PublicationCategoryModelImpl>
  get copyWith =>
      __$$PublicationCategoryModelImplCopyWithImpl<
        _$PublicationCategoryModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicationCategoryModelImplToJson(this);
  }
}

abstract class _PublicationCategoryModel implements PublicationCategoryModel {
  const factory _PublicationCategoryModel({
    required final int id,
    required final String name,
    required final String slug,
    final String? description,
  }) = _$PublicationCategoryModelImpl;

  factory _PublicationCategoryModel.fromJson(Map<String, dynamic> json) =
      _$PublicationCategoryModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String? get description;

  /// Create a copy of PublicationCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicationCategoryModelImplCopyWith<_$PublicationCategoryModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PublicationTagModel _$PublicationTagModelFromJson(Map<String, dynamic> json) {
  return _PublicationTagModel.fromJson(json);
}

/// @nodoc
mixin _$PublicationTagModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;

  /// Serializes this PublicationTagModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicationTagModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicationTagModelCopyWith<PublicationTagModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicationTagModelCopyWith<$Res> {
  factory $PublicationTagModelCopyWith(
    PublicationTagModel value,
    $Res Function(PublicationTagModel) then,
  ) = _$PublicationTagModelCopyWithImpl<$Res, PublicationTagModel>;
  @useResult
  $Res call({int id, String name, String slug});
}

/// @nodoc
class _$PublicationTagModelCopyWithImpl<$Res, $Val extends PublicationTagModel>
    implements $PublicationTagModelCopyWith<$Res> {
  _$PublicationTagModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicationTagModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? slug = null}) {
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PublicationTagModelImplCopyWith<$Res>
    implements $PublicationTagModelCopyWith<$Res> {
  factory _$$PublicationTagModelImplCopyWith(
    _$PublicationTagModelImpl value,
    $Res Function(_$PublicationTagModelImpl) then,
  ) = __$$PublicationTagModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String slug});
}

/// @nodoc
class __$$PublicationTagModelImplCopyWithImpl<$Res>
    extends _$PublicationTagModelCopyWithImpl<$Res, _$PublicationTagModelImpl>
    implements _$$PublicationTagModelImplCopyWith<$Res> {
  __$$PublicationTagModelImplCopyWithImpl(
    _$PublicationTagModelImpl _value,
    $Res Function(_$PublicationTagModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PublicationTagModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? slug = null}) {
    return _then(
      _$PublicationTagModelImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicationTagModelImpl implements _PublicationTagModel {
  const _$PublicationTagModelImpl({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory _$PublicationTagModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicationTagModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;

  @override
  String toString() {
    return 'PublicationTagModel(id: $id, name: $name, slug: $slug)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicationTagModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, slug);

  /// Create a copy of PublicationTagModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicationTagModelImplCopyWith<_$PublicationTagModelImpl> get copyWith =>
      __$$PublicationTagModelImplCopyWithImpl<_$PublicationTagModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicationTagModelImplToJson(this);
  }
}

abstract class _PublicationTagModel implements PublicationTagModel {
  const factory _PublicationTagModel({
    required final int id,
    required final String name,
    required final String slug,
  }) = _$PublicationTagModelImpl;

  factory _PublicationTagModel.fromJson(Map<String, dynamic> json) =
      _$PublicationTagModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get slug;

  /// Create a copy of PublicationTagModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicationTagModelImplCopyWith<_$PublicationTagModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PublicationGalleryModel _$PublicationGalleryModelFromJson(
  Map<String, dynamic> json,
) {
  return _PublicationGalleryModel.fromJson(json);
}

/// @nodoc
mixin _$PublicationGalleryModel {
  int get id => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;

  /// Serializes this PublicationGalleryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicationGalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicationGalleryModelCopyWith<PublicationGalleryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicationGalleryModelCopyWith<$Res> {
  factory $PublicationGalleryModelCopyWith(
    PublicationGalleryModel value,
    $Res Function(PublicationGalleryModel) then,
  ) = _$PublicationGalleryModelCopyWithImpl<$Res, PublicationGalleryModel>;
  @useResult
  $Res call({int id, String image, int order, String? caption});
}

/// @nodoc
class _$PublicationGalleryModelCopyWithImpl<
  $Res,
  $Val extends PublicationGalleryModel
>
    implements $PublicationGalleryModelCopyWith<$Res> {
  _$PublicationGalleryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicationGalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? image = null,
    Object? order = null,
    Object? caption = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            image: null == image
                ? _value.image
                : image // ignore: cast_nullable_to_non_nullable
                      as String,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            caption: freezed == caption
                ? _value.caption
                : caption // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PublicationGalleryModelImplCopyWith<$Res>
    implements $PublicationGalleryModelCopyWith<$Res> {
  factory _$$PublicationGalleryModelImplCopyWith(
    _$PublicationGalleryModelImpl value,
    $Res Function(_$PublicationGalleryModelImpl) then,
  ) = __$$PublicationGalleryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String image, int order, String? caption});
}

/// @nodoc
class __$$PublicationGalleryModelImplCopyWithImpl<$Res>
    extends
        _$PublicationGalleryModelCopyWithImpl<
          $Res,
          _$PublicationGalleryModelImpl
        >
    implements _$$PublicationGalleryModelImplCopyWith<$Res> {
  __$$PublicationGalleryModelImplCopyWithImpl(
    _$PublicationGalleryModelImpl _value,
    $Res Function(_$PublicationGalleryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PublicationGalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? image = null,
    Object? order = null,
    Object? caption = freezed,
  }) {
    return _then(
      _$PublicationGalleryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        image: null == image
            ? _value.image
            : image // ignore: cast_nullable_to_non_nullable
                  as String,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        caption: freezed == caption
            ? _value.caption
            : caption // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicationGalleryModelImpl implements _PublicationGalleryModel {
  const _$PublicationGalleryModelImpl({
    required this.id,
    required this.image,
    required this.order,
    this.caption,
  });

  factory _$PublicationGalleryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicationGalleryModelImplFromJson(json);

  @override
  final int id;
  @override
  final String image;
  @override
  final int order;
  @override
  final String? caption;

  @override
  String toString() {
    return 'PublicationGalleryModel(id: $id, image: $image, order: $order, caption: $caption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicationGalleryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.caption, caption) || other.caption == caption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, image, order, caption);

  /// Create a copy of PublicationGalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicationGalleryModelImplCopyWith<_$PublicationGalleryModelImpl>
  get copyWith =>
      __$$PublicationGalleryModelImplCopyWithImpl<
        _$PublicationGalleryModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicationGalleryModelImplToJson(this);
  }
}

abstract class _PublicationGalleryModel implements PublicationGalleryModel {
  const factory _PublicationGalleryModel({
    required final int id,
    required final String image,
    required final int order,
    final String? caption,
  }) = _$PublicationGalleryModelImpl;

  factory _PublicationGalleryModel.fromJson(Map<String, dynamic> json) =
      _$PublicationGalleryModelImpl.fromJson;

  @override
  int get id;
  @override
  String get image;
  @override
  int get order;
  @override
  String? get caption;

  /// Create a copy of PublicationGalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicationGalleryModelImplCopyWith<_$PublicationGalleryModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PublicationModel _$PublicationModelFromJson(Map<String, dynamic> json) {
  return _PublicationModel.fromJson(json);
}

/// @nodoc
mixin _$PublicationModel {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_image')
  String? get coverImage => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_type')
  String get contentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'published_at')
  String? get publishedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_featured')
  bool get isFeatured => throw _privateConstructorUsedError;
  @JsonKey(name: 'views_count')
  int get viewsCount => throw _privateConstructorUsedError; // Nested properties for detail view
  PublicationCategoryModel? get category => throw _privateConstructorUsedError;
  List<PublicationTagModel>? get tags => throw _privateConstructorUsedError;
  UserModel? get author => throw _privateConstructorUsedError;
  @JsonKey(name: 'gallery_images')
  List<PublicationGalleryModel>? get galleryImages =>
      throw _privateConstructorUsedError;

  /// Serializes this PublicationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicationModelCopyWith<PublicationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicationModelCopyWith<$Res> {
  factory $PublicationModelCopyWith(
    PublicationModel value,
    $Res Function(PublicationModel) then,
  ) = _$PublicationModelCopyWithImpl<$Res, PublicationModel>;
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String summary,
    String content,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'content_type') String contentType,
    @JsonKey(name: 'published_at') String? publishedAt,
    @JsonKey(name: 'is_featured') bool isFeatured,
    @JsonKey(name: 'views_count') int viewsCount,
    PublicationCategoryModel? category,
    List<PublicationTagModel>? tags,
    UserModel? author,
    @JsonKey(name: 'gallery_images')
    List<PublicationGalleryModel>? galleryImages,
  });

  $PublicationCategoryModelCopyWith<$Res>? get category;
  $UserModelCopyWith<$Res>? get author;
}

/// @nodoc
class _$PublicationModelCopyWithImpl<$Res, $Val extends PublicationModel>
    implements $PublicationModelCopyWith<$Res> {
  _$PublicationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? summary = null,
    Object? content = null,
    Object? coverImage = freezed,
    Object? contentType = null,
    Object? publishedAt = freezed,
    Object? isFeatured = null,
    Object? viewsCount = null,
    Object? category = freezed,
    Object? tags = freezed,
    Object? author = freezed,
    Object? galleryImages = freezed,
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
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            contentType: null == contentType
                ? _value.contentType
                : contentType // ignore: cast_nullable_to_non_nullable
                      as String,
            publishedAt: freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            isFeatured: null == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool,
            viewsCount: null == viewsCount
                ? _value.viewsCount
                : viewsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as PublicationCategoryModel?,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<PublicationTagModel>?,
            author: freezed == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as UserModel?,
            galleryImages: freezed == galleryImages
                ? _value.galleryImages
                : galleryImages // ignore: cast_nullable_to_non_nullable
                      as List<PublicationGalleryModel>?,
          )
          as $Val,
    );
  }

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PublicationCategoryModelCopyWith<$Res>? get category {
    if (_value.category == null) {
      return null;
    }

    return $PublicationCategoryModelCopyWith<$Res>(_value.category!, (value) {
      return _then(_value.copyWith(category: value) as $Val);
    });
  }

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserModelCopyWith<$Res>? get author {
    if (_value.author == null) {
      return null;
    }

    return $UserModelCopyWith<$Res>(_value.author!, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PublicationModelImplCopyWith<$Res>
    implements $PublicationModelCopyWith<$Res> {
  factory _$$PublicationModelImplCopyWith(
    _$PublicationModelImpl value,
    $Res Function(_$PublicationModelImpl) then,
  ) = __$$PublicationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String slug,
    String summary,
    String content,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'content_type') String contentType,
    @JsonKey(name: 'published_at') String? publishedAt,
    @JsonKey(name: 'is_featured') bool isFeatured,
    @JsonKey(name: 'views_count') int viewsCount,
    PublicationCategoryModel? category,
    List<PublicationTagModel>? tags,
    UserModel? author,
    @JsonKey(name: 'gallery_images')
    List<PublicationGalleryModel>? galleryImages,
  });

  @override
  $PublicationCategoryModelCopyWith<$Res>? get category;
  @override
  $UserModelCopyWith<$Res>? get author;
}

/// @nodoc
class __$$PublicationModelImplCopyWithImpl<$Res>
    extends _$PublicationModelCopyWithImpl<$Res, _$PublicationModelImpl>
    implements _$$PublicationModelImplCopyWith<$Res> {
  __$$PublicationModelImplCopyWithImpl(
    _$PublicationModelImpl _value,
    $Res Function(_$PublicationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? summary = null,
    Object? content = null,
    Object? coverImage = freezed,
    Object? contentType = null,
    Object? publishedAt = freezed,
    Object? isFeatured = null,
    Object? viewsCount = null,
    Object? category = freezed,
    Object? tags = freezed,
    Object? author = freezed,
    Object? galleryImages = freezed,
  }) {
    return _then(
      _$PublicationModelImpl(
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
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        contentType: null == contentType
            ? _value.contentType
            : contentType // ignore: cast_nullable_to_non_nullable
                  as String,
        publishedAt: freezed == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        isFeatured: null == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool,
        viewsCount: null == viewsCount
            ? _value.viewsCount
            : viewsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as PublicationCategoryModel?,
        tags: freezed == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<PublicationTagModel>?,
        author: freezed == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as UserModel?,
        galleryImages: freezed == galleryImages
            ? _value._galleryImages
            : galleryImages // ignore: cast_nullable_to_non_nullable
                  as List<PublicationGalleryModel>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicationModelImpl implements _PublicationModel {
  const _$PublicationModelImpl({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.content,
    @JsonKey(name: 'cover_image') this.coverImage,
    @JsonKey(name: 'content_type') required this.contentType,
    @JsonKey(name: 'published_at') this.publishedAt,
    @JsonKey(name: 'is_featured') required this.isFeatured,
    @JsonKey(name: 'views_count') required this.viewsCount,
    this.category,
    final List<PublicationTagModel>? tags,
    this.author,
    @JsonKey(name: 'gallery_images')
    final List<PublicationGalleryModel>? galleryImages,
  }) : _tags = tags,
       _galleryImages = galleryImages;

  factory _$PublicationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicationModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String summary;
  @override
  final String content;
  @override
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  @override
  @JsonKey(name: 'content_type')
  final String contentType;
  @override
  @JsonKey(name: 'published_at')
  final String? publishedAt;
  @override
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @override
  @JsonKey(name: 'views_count')
  final int viewsCount;
  // Nested properties for detail view
  @override
  final PublicationCategoryModel? category;
  final List<PublicationTagModel>? _tags;
  @override
  List<PublicationTagModel>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final UserModel? author;
  final List<PublicationGalleryModel>? _galleryImages;
  @override
  @JsonKey(name: 'gallery_images')
  List<PublicationGalleryModel>? get galleryImages {
    final value = _galleryImages;
    if (value == null) return null;
    if (_galleryImages is EqualUnmodifiableListView) return _galleryImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'PublicationModel(id: $id, title: $title, slug: $slug, summary: $summary, content: $content, coverImage: $coverImage, contentType: $contentType, publishedAt: $publishedAt, isFeatured: $isFeatured, viewsCount: $viewsCount, category: $category, tags: $tags, author: $author, galleryImages: $galleryImages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality().equals(
              other._galleryImages,
              _galleryImages,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    slug,
    summary,
    content,
    coverImage,
    contentType,
    publishedAt,
    isFeatured,
    viewsCount,
    category,
    const DeepCollectionEquality().hash(_tags),
    author,
    const DeepCollectionEquality().hash(_galleryImages),
  );

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicationModelImplCopyWith<_$PublicationModelImpl> get copyWith =>
      __$$PublicationModelImplCopyWithImpl<_$PublicationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicationModelImplToJson(this);
  }
}

abstract class _PublicationModel implements PublicationModel {
  const factory _PublicationModel({
    required final int id,
    required final String title,
    required final String slug,
    required final String summary,
    required final String content,
    @JsonKey(name: 'cover_image') final String? coverImage,
    @JsonKey(name: 'content_type') required final String contentType,
    @JsonKey(name: 'published_at') final String? publishedAt,
    @JsonKey(name: 'is_featured') required final bool isFeatured,
    @JsonKey(name: 'views_count') required final int viewsCount,
    final PublicationCategoryModel? category,
    final List<PublicationTagModel>? tags,
    final UserModel? author,
    @JsonKey(name: 'gallery_images')
    final List<PublicationGalleryModel>? galleryImages,
  }) = _$PublicationModelImpl;

  factory _PublicationModel.fromJson(Map<String, dynamic> json) =
      _$PublicationModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String get summary;
  @override
  String get content;
  @override
  @JsonKey(name: 'cover_image')
  String? get coverImage;
  @override
  @JsonKey(name: 'content_type')
  String get contentType;
  @override
  @JsonKey(name: 'published_at')
  String? get publishedAt;
  @override
  @JsonKey(name: 'is_featured')
  bool get isFeatured;
  @override
  @JsonKey(name: 'views_count')
  int get viewsCount; // Nested properties for detail view
  @override
  PublicationCategoryModel? get category;
  @override
  List<PublicationTagModel>? get tags;
  @override
  UserModel? get author;
  @override
  @JsonKey(name: 'gallery_images')
  List<PublicationGalleryModel>? get galleryImages;

  /// Create a copy of PublicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicationModelImplCopyWith<_$PublicationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

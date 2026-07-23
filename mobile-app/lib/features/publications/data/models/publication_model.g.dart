// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PublicationCategoryModelImpl _$$PublicationCategoryModelImplFromJson(
  Map<String, dynamic> json,
) => _$PublicationCategoryModelImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$$PublicationCategoryModelImplToJson(
  _$PublicationCategoryModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'description': instance.description,
};

_$PublicationTagModelImpl _$$PublicationTagModelImplFromJson(
  Map<String, dynamic> json,
) => _$PublicationTagModelImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$$PublicationTagModelImplToJson(
  _$PublicationTagModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
};

_$PublicationGalleryModelImpl _$$PublicationGalleryModelImplFromJson(
  Map<String, dynamic> json,
) => _$PublicationGalleryModelImpl(
  id: (json['id'] as num).toInt(),
  image: json['image'] as String,
  order: (json['order'] as num).toInt(),
  caption: json['caption'] as String?,
);

Map<String, dynamic> _$$PublicationGalleryModelImplToJson(
  _$PublicationGalleryModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'image': instance.image,
  'order': instance.order,
  'caption': instance.caption,
};

_$PublicationModelImpl _$$PublicationModelImplFromJson(
  Map<String, dynamic> json,
) => _$PublicationModelImpl(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  slug: json['slug'] as String,
  summary: json['summary'] as String,
  content: json['content'] as String,
  coverImage: json['cover_image'] as String?,
  contentType: json['content_type'] as String,
  publishedAt: json['published_at'] as String?,
  isFeatured: json['is_featured'] as bool,
  viewsCount: (json['views_count'] as num).toInt(),
  category: json['category'] == null
      ? null
      : PublicationCategoryModel.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => PublicationTagModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  author: json['author'] == null
      ? null
      : UserModel.fromJson(json['author'] as Map<String, dynamic>),
  galleryImages: (json['gallery_images'] as List<dynamic>?)
      ?.map((e) => PublicationGalleryModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$PublicationModelImplToJson(
  _$PublicationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'summary': instance.summary,
  'content': instance.content,
  'cover_image': instance.coverImage,
  'content_type': instance.contentType,
  'published_at': instance.publishedAt,
  'is_featured': instance.isFeatured,
  'views_count': instance.viewsCount,
  'category': instance.category,
  'tags': instance.tags,
  'author': instance.author,
  'gallery_images': instance.galleryImages,
};

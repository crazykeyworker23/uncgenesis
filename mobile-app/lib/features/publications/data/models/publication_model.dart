import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../auth/data/models/user_model.dart';

part 'publication_model.freezed.dart';
part 'publication_model.g.dart';

@freezed
class PublicationCategoryModel with _$PublicationCategoryModel {
  const factory PublicationCategoryModel({
    required int id,
    required String name,
    required String slug,
    String? description,
  }) = _PublicationCategoryModel;

  factory PublicationCategoryModel.fromJson(Map<String, dynamic> json) => _$PublicationCategoryModelFromJson(json);
}

@freezed
class PublicationTagModel with _$PublicationTagModel {
  const factory PublicationTagModel({
    required int id,
    required String name,
    required String slug,
  }) = _PublicationTagModel;

  factory PublicationTagModel.fromJson(Map<String, dynamic> json) => _$PublicationTagModelFromJson(json);
}

@freezed
class PublicationGalleryModel with _$PublicationGalleryModel {
  const factory PublicationGalleryModel({
    required int id,
    required String image,
    required int order,
    String? caption,
  }) = _PublicationGalleryModel;

  factory PublicationGalleryModel.fromJson(Map<String, dynamic> json) => _$PublicationGalleryModelFromJson(json);
}

@freezed
class PublicationModel with _$PublicationModel {
  const factory PublicationModel({
    required int id,
    required String title,
    required String slug,
    required String summary,
    required String content,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'content_type') required String contentType,
    @JsonKey(name: 'published_at') String? publishedAt,
    @JsonKey(name: 'is_featured') required bool isFeatured,
    @JsonKey(name: 'views_count') required int viewsCount,
    
    // Nested properties for detail view
    PublicationCategoryModel? category,
    List<PublicationTagModel>? tags,
    UserModel? author,
    @JsonKey(name: 'gallery_images') List<PublicationGalleryModel>? galleryImages,
  }) = _PublicationModel;

  factory PublicationModel.fromJson(Map<String, dynamic> json) => _$PublicationModelFromJson(json);
}

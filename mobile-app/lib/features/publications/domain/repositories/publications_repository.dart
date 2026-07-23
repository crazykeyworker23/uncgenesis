import '../../data/models/publication_model.dart';

abstract class PublicationsRepository {
  Future<List<PublicationModel>> getPublications({
    required int page,
    String? categorySlug,
    String? contentType,
    String? searchQuery,
  });
  Future<PublicationModel> getPublicationDetail(String slug);
  Future<List<PublicationCategoryModel>> getCategories();
}

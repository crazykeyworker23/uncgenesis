import 'package:dio/dio.dart';
import '../../domain/repositories/publications_repository.dart';
import '../models/publication_model.dart';

class PublicationsRepositoryImpl implements PublicationsRepository {
  final Dio _dio;

  PublicationsRepositoryImpl({required Dio dio}) : _dio = dio;

  List<dynamic> _parseListResponse(dynamic data) {
    if (data is List) {
      return data;
    } else if (data is Map<String, dynamic>) {
      if (data['results'] is List) {
        return data['results'] as List<dynamic>;
      } else if (data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
    }
    return [];
  }

  @override
  Future<List<PublicationModel>> getPublications({
    required int page,
    String? categorySlug,
    String? contentType,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'status': 'PUBLISHED',
      'show_in_app': true,
      'ordering': '-published_at',
    };

    if (categorySlug != null && categorySlug.isNotEmpty) {
      queryParams['category__slug'] = categorySlug;
    }
    if (contentType != null && contentType.isNotEmpty && contentType != 'ALL') {
      queryParams['content_type'] = contentType;
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['search'] = searchQuery.trim();
    }

    final response = await _dio.get('/publications/', queryParameters: queryParams);
    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => PublicationModel.fromJson(json)).toList();
  }

  @override
  Future<PublicationModel> getPublicationDetail(String slug) async {
    final response = await _dio.get('/publications/$slug/');
    return PublicationModel.fromJson(response.data);
  }

  @override
  Future<List<PublicationCategoryModel>> getCategories() async {
    final response = await _dio.get('/categories/');
    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => PublicationCategoryModel.fromJson(json)).toList();
  }
}

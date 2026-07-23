import 'package:dio/dio.dart';
import '../../domain/repositories/devotionals_repository.dart';
import '../models/devotional_model.dart';

class DevotionalsRepositoryImpl implements DevotionalsRepository {
  final Dio _dio;

  DevotionalsRepositoryImpl({required Dio dio}) : _dio = dio;

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
  Future<List<DevotionalModel>> getDevotionals({
    required int page,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'status': 'PUBLISHED',
      'ordering': '-date',
    };

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['search'] = searchQuery.trim();
    }

    final response = await _dio.get('/devotionals/', queryParameters: queryParams);
    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => DevotionalModel.fromJson(json)).toList();
  }

  @override
  Future<DevotionalModel> getDevotionalDetail(String slug) async {
    final response = await _dio.get('/devotionals/$slug/');
    return DevotionalModel.fromJson(response.data);
  }
}

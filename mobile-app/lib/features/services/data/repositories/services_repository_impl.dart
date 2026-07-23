import 'package:dio/dio.dart';
import '../../domain/repositories/services_repository.dart';
import '../models/service_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final Dio _dio;

  ServicesRepositoryImpl({required Dio dio}) : _dio = dio;

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
  Future<List<ChurchServiceModel>> getServices({required int page}) async {
    final response = await _dio.get('/services/', queryParameters: {
      'page': page,
      'status': 'PUBLISHED',
    });

    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => ChurchServiceModel.fromJson(json)).toList();
  }

  @override
  Future<ChurchServiceModel> getServiceDetail(String slug) async {
    final response = await _dio.get('/services/$slug/');
    return ChurchServiceModel.fromJson(response.data);
  }
}

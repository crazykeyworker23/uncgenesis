import 'package:dio/dio.dart';
import '../../domain/repositories/cells_repository.dart';
import '../models/cell_model.dart';

class CellsRepositoryImpl implements CellsRepository {
  final Dio _dio;

  CellsRepositoryImpl({required Dio dio}) : _dio = dio;

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
  Future<List<CellGroupModel>> getCells({
    required int page,
    String? searchQuery,
    String? meetingDay,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'status': 'ACTIVE',
    };

    if (meetingDay != null && meetingDay != 'ALL') {
      queryParams['meeting_day'] = meetingDay;
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['search'] = searchQuery.trim();
    }

    final response = await _dio.get('/cells/', queryParameters: queryParams);
    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => CellGroupModel.fromJson(json)).toList();
  }

  @override
  Future<CellGroupModel> getCellDetail(String slug) async {
    final response = await _dio.get('/cells/$slug/');
    return CellGroupModel.fromJson(response.data);
  }
}

import 'package:dio/dio.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/public_settings_model.dart';
import '../../../publications/data/models/publication_model.dart';
import '../../../devotionals/data/models/devotional_model.dart';
import '../../../events/data/models/event_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;

  HomeRepositoryImpl({required Dio dio}) : _dio = dio;

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
  Future<PublicSettingsModel> getPublicSettings() async {
    final response = await _dio.get('/settings/public/');
    return PublicSettingsModel.fromJson(response.data);
  }

  @override
  Future<List<PublicationModel>> getRecentPublications() async {
    final response = await _dio.get('/publications/', queryParameters: {
      'status': 'PUBLISHED',
      'show_in_app': true,
      'ordering': '-published_at',
    });
    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => PublicationModel.fromJson(json)).toList();
  }

  @override
  Future<DevotionalModel?> getTodayDevotional() async {
    try {
      final response = await _dio.get('/devotionals/today/');
      return DevotionalModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EventModel>> getUpcomingEvents() async {
    final response = await _dio.get('/events/', queryParameters: {
      'status': 'PUBLISHED',
      'ordering': 'start_date',
    });
    final List<dynamic> results = _parseListResponse(response.data);
    return results.map((json) => EventModel.fromJson(json)).toList();
  }
}

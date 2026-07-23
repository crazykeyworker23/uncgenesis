import 'package:dio/dio.dart';
import '../../domain/repositories/events_repository.dart';
import '../models/event_model.dart';

class EventsRepositoryImpl implements EventsRepository {
  final Dio _dio;

  EventsRepositoryImpl({required Dio dio}) : _dio = dio;

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
  Future<List<EventModel>> getEvents({
    required int page,
    String? filterType,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'status': 'PUBLISHED',
      'ordering': 'start_date',
    };

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['search'] = searchQuery.trim();
    }

    final response = await _dio.get('/events/', queryParameters: queryParams);
    final List<dynamic> results = _parseListResponse(response.data);
    final allEvents = results.map((json) => EventModel.fromJson(json)).toList();

    if (filterType == 'UPCOMING') {
      final now = DateTime.now();
      return allEvents.where((e) {
        final startDate = DateTime.tryParse(e.startDate);
        return startDate != null && startDate.isAfter(now);
      }).toList();
    } else if (filterType == 'PAST') {
      final now = DateTime.now();
      return allEvents.where((e) {
        final startDate = DateTime.tryParse(e.startDate);
        return startDate != null && startDate.isBefore(now);
      }).toList();
    }

    return allEvents;
  }

  @override
  Future<EventModel> getEventDetail(String slug) async {
    final response = await _dio.get('/events/$slug/');
    return EventModel.fromJson(response.data);
  }

  @override
  Future<void> registerToEvent(int eventId) async {
    await _dio.post('/events/$eventId/register/');
  }
}

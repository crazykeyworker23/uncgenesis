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
    // El filtro por fecha se aplica en el notifier: si se recortara aquí, el
    // cálculo de "quedan más páginas" usaría el listado ya filtrado y la
    // paginación se detendría antes de tiempo.
    return results.map((json) => EventModel.fromJson(json)).toList();
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

  @override
  Future<List<EventModel>> getMyRegisteredEvents() async {
    // El backend no expone un endpoint "mis inscripciones", así que se recorre
    // la lista publicada y se filtra por `is_registered`, que el serializador
    // calcula para el usuario autenticado.
    const maxPages = 20;
    final registered = <EventModel>[];

    for (var page = 1; page <= maxPages; page++) {
      final response = await _dio.get('/events/', queryParameters: {
        'page': page,
        'status': 'PUBLISHED',
        'ordering': 'start_date',
      });

      final results = _parseListResponse(response.data);
      if (results.isEmpty) break;

      registered.addAll(
        results.map((json) => EventModel.fromJson(json)).where((e) => e.isRegistered == true),
      );

      final hasNext = response.data is Map && response.data['next'] != null;
      if (!hasNext) break;
    }

    return registered;
  }
}

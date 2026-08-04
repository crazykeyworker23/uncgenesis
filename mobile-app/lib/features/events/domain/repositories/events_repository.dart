import '../../data/models/event_model.dart';

abstract class EventsRepository {
  Future<List<EventModel>> getEvents({
    required int page,
    String? filterType, // 'ALL', 'UPCOMING', 'PAST'
    String? searchQuery,
  });
  Future<EventModel> getEventDetail(String slug);
  Future<void> registerToEvent(int eventId);

  /// Eventos publicados en los que el usuario autenticado está inscrito.
  Future<List<EventModel>> getMyRegisteredEvents();
}

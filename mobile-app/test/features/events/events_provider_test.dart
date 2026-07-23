import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/features/events/domain/repositories/events_repository.dart';
import 'package:genesis_app/features/events/data/models/event_model.dart';
import 'package:genesis_app/features/events/presentation/providers/events_provider.dart';

class FakeEventsRepository implements EventsRepository {
  bool registerCalled = false;

  @override
  Future<List<EventModel>> getEvents({
    required int page,
    String? filterType,
    String? searchQuery,
  }) async {
    return [
      const EventModel(
        id: 1,
        title: 'Evento Test 1',
        slug: 'evento-test-1',
        description: 'Desc',
        startDate: '2026-07-10T19:00:00Z',
        endDate: '2026-07-10T21:00:00Z',
        location: 'Templo',
        requiresRegistration: true,
        status: 'PUBLISHED',
      )
    ];
  }

  @override
  Future<EventModel> getEventDetail(String slug) async {
    return const EventModel(
      id: 1,
      title: 'Evento Test Detail',
      slug: 'evento-test-1',
      description: 'Desc Detail',
      startDate: '2026-07-10T19:00:00Z',
      endDate: '2026-07-10T21:00:00Z',
      location: 'Templo',
      requiresRegistration: true,
      status: 'PUBLISHED',
      isRegistered: true,
    );
  }

  @override
  Future<void> registerToEvent(int eventId) async {
    registerCalled = true;
  }
}

void main() {
  group('Events Providers Tests', () {
    late ProviderContainer container;
    late FakeEventsRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeEventsRepository();
      container = ProviderContainer(
        overrides: [
          eventsRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('eventsProvider loadNextPage appends events and increments page', () async {
      final notifier = container.read(eventsProvider.notifier);
      await notifier.loadNextPage();
      
      final state = container.read(eventsProvider);
      expect(state.events.length, 1);
      expect(state.events.first.title, 'Evento Test 1');
      expect(state.page, 2);
    });

    test('eventDetailProvider loads successfully with isRegistered true', () async {
      final detail = await container.read(eventDetailProvider('evento-test-1').future);
      expect(detail.title, 'Evento Test Detail');
      expect(detail.isRegistered, isTrue);
    });

    test('registerToEvent calls repository register', () async {
      final repo = container.read(eventsRepositoryProvider);
      await repo.registerToEvent(1);
      expect(fakeRepository.registerCalled, isTrue);
    });
  });
}

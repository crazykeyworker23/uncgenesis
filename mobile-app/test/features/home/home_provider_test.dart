import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/features/home/domain/repositories/home_repository.dart';
import 'package:genesis_app/features/home/data/models/public_settings_model.dart';
import 'package:genesis_app/features/publications/data/models/publication_model.dart';
import 'package:genesis_app/features/devotionals/data/models/devotional_model.dart';
import 'package:genesis_app/features/events/data/models/event_model.dart';
import 'package:genesis_app/features/home/presentation/providers/home_provider.dart';

class FakeHomeRepository implements HomeRepository {
  @override
  Future<PublicSettingsModel> getPublicSettings() async {
    return const PublicSettingsModel(
      app: AppSettingsModel(
        appName: 'Genesis',
        appDescription: 'Desc',
        splashText: 'Text',
        primaryColor: '#000000',
        secondaryColor: '#FFFFFF',
        privacyPolicyUrl: 'http://privacy.com',
        termsUrl: 'http://terms.com',
      ),
      church: ChurchSettingsModel(
        churchName: 'Iglesia Genesis',
        address: 'Calle 123',
        city: 'Iquitos',
        country: 'Peru',
        phone: '123456',
        whatsapp: '931405531',
        email: 'g@g.com',
        website: 'g.org',
      ),
      schedules: [],
      socialNetworks: [],
    );
  }

  @override
  Future<List<PublicationModel>> getRecentPublications() async {
    return [
      const PublicationModel(
        id: 1,
        title: 'Noticia 1',
        slug: 'noticia-1',
        summary: 'Resumen',
        content: 'Contenido',
        contentType: 'GENERAL',
        isFeatured: false,
        viewsCount: 10,
      )
    ];
  }

  @override
  Future<DevotionalModel?> getTodayDevotional() async {
    return const DevotionalModel(
      id: 1,
      title: 'Devocional de Hoy',
      slug: 'dev-1',
      date: '2026-07-10',
      biblePassage: 'Juan 3:16',
      bibleText: 'Texto biblia',
      content: 'Contenido devocional',
      status: 'PUBLISHED',
      viewsCount: 5,
    );
  }

  @override
  Future<List<EventModel>> getUpcomingEvents() async {
    return [
      const EventModel(
        id: 1,
        title: 'Evento 1',
        slug: 'evento-1',
        description: 'Desc event',
        startDate: '2026-07-10T19:00:00Z',
        endDate: '2026-07-10T21:00:00Z',
        location: 'Templo',
        requiresRegistration: true,
        status: 'PUBLISHED',
      )
    ];
  }
}

void main() {
  group('Home Providers Tests', () {
    late ProviderContainer container;
    late FakeHomeRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeHomeRepository();
      container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('publicSettingsProvider loads successfully', () async {
      final settings = await container.read(publicSettingsProvider.future);
      expect(settings.church.churchName, 'Iglesia Genesis');
      expect(settings.church.whatsapp, '931405531');
    });

    test('recentPublicationsProvider loads successfully', () async {
      final publications = await container.read(recentPublicationsProvider.future);
      expect(publications.length, 1);
      expect(publications.first.title, 'Noticia 1');
    });

    test('todayDevotionalProvider loads successfully', () async {
      final devotional = await container.read(todayDevotionalProvider.future);
      expect(devotional, isNotNull);
      expect(devotional!.title, 'Devocional de Hoy');
    });

    test('upcomingEventsProvider loads successfully', () async {
      final events = await container.read(upcomingEventsProvider.future);
      expect(events.length, 1);
      expect(events.first.title, 'Evento 1');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genesis_app/features/devotionals/domain/repositories/devotionals_repository.dart';
import 'package:genesis_app/features/devotionals/data/models/devotional_model.dart';
import 'package:genesis_app/features/devotionals/presentation/providers/devotionals_provider.dart';

class FakeDevotionalsRepository implements DevotionalsRepository {
  @override
  Future<List<DevotionalModel>> getDevotionals({
    required int page,
    String? searchQuery,
  }) async {
    return [
      const DevotionalModel(
        id: 1,
        title: 'Devocional Test 1',
        slug: 'devocional-test-1',
        date: '2026-07-10',
        biblePassage: 'Génesis 1:1',
        bibleText: 'En el principio...',
        content: 'Contenido devocional',
        status: 'PUBLISHED',
        viewsCount: 10,
      )
    ];
  }

  @override
  Future<DevotionalModel> getDevotionalDetail(String slug) async {
    return const DevotionalModel(
      id: 1,
      title: 'Devocional Test Detail',
      slug: 'devocional-test-1',
      date: '2026-07-10',
      biblePassage: 'Génesis 1:1',
      bibleText: 'En el principio...',
      content: 'Contenido devocional completo',
      status: 'PUBLISHED',
      viewsCount: 11,
      audioUrl: 'https://example.com/audio.mp3',
    );
  }
}

void main() {
  group('Devotionals Providers Tests', () {
    late ProviderContainer container;
    late FakeDevotionalsRepository fakeRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRepository = FakeDevotionalsRepository();
      container = ProviderContainer(
        overrides: [
          devotionalsRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('devotionalsProvider loadNextPage appends devotionals and increments page', () async {
      final notifier = container.read(devotionalsProvider.notifier);
      await notifier.loadNextPage();
      
      final state = container.read(devotionalsProvider);
      expect(state.devotionals.length, 1);
      expect(state.devotionals.first.title, 'Devocional Test 1');
      expect(state.page, 2);
    });

    test('devotionalDetailProvider loads successfully with audioUrl', () async {
      final detail = await container.read(devotionalDetailProvider('devocional-test-1').future);
      expect(detail.title, 'Devocional Test Detail');
      expect(detail.audioUrl, 'https://example.com/audio.mp3');
    });

    test('savedDevotionalsProvider toggles favorites correctly', () async {
      final savedNotifier = container.read(savedDevotionalsProvider.notifier);
      
      expect(container.read(savedDevotionalsProvider), isEmpty);
      
      await savedNotifier.toggleFavorite('devocional-test-1');
      expect(container.read(savedDevotionalsProvider), contains('devocional-test-1'));
      
      await savedNotifier.toggleFavorite('devocional-test-1');
      expect(container.read(savedDevotionalsProvider), isEmpty);
    });
  });
}

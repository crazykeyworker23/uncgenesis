import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/features/publications/domain/repositories/publications_repository.dart';
import 'package:genesis_app/features/publications/data/models/publication_model.dart';
import 'package:genesis_app/features/publications/presentation/providers/publications_provider.dart';

class FakePublicationsRepository implements PublicationsRepository {
  bool shouldFail = false;

  @override
  Future<List<PublicationModel>> getPublications({
    required int page,
    String? categorySlug,
    String? contentType,
    String? searchQuery,
  }) async {
    if (shouldFail) throw Exception('Failed to load publications');
    return [
      const PublicationModel(
        id: 1,
        title: 'Pub 1',
        slug: 'pub-1',
        summary: 'Summary 1',
        content: 'Content 1',
        contentType: 'NEWS',
        isFeatured: false,
        viewsCount: 15,
      )
    ];
  }

  @override
  Future<PublicationModel> getPublicationDetail(String slug) async {
    return const PublicationModel(
      id: 1,
      title: 'Pub 1 Detail',
      slug: 'pub-1',
      summary: 'Summary 1',
      content: 'Content 1 Detail',
      contentType: 'NEWS',
      isFeatured: false,
      viewsCount: 16,
    );
  }

  @override
  Future<List<PublicationCategoryModel>> getCategories() async {
    return [
      const PublicationCategoryModel(
        id: 1,
        name: 'Categoria 1',
        slug: 'cat-1',
      )
    ];
  }
}

void main() {
  group('Publications Providers Tests', () {
    late ProviderContainer container;
    late FakePublicationsRepository fakeRepository;

    setUp(() {
      fakeRepository = FakePublicationsRepository();
      container = ProviderContainer(
        overrides: [
          publicationsRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('categoriesProvider loads successfully', () async {
      final categories = await container.read(categoriesProvider.future);
      expect(categories.length, 1);
      expect(categories.first.name, 'Categoria 1');
    });

    test('publicationsProvider loadNextPage appends publications and increments page', () async {
      final notifier = container.read(publicationsProvider.notifier);
      await notifier.loadNextPage();
      
      final state = container.read(publicationsProvider);
      expect(state.publications.length, 1);
      expect(state.publications.first.title, 'Pub 1');
      expect(state.page, 2);
    });

    test('publicationDetailProvider loads successfully', () async {
      final detail = await container.read(publicationDetailProvider('pub-1').future);
      expect(detail.title, 'Pub 1 Detail');
      expect(detail.content, 'Content 1 Detail');
    });
  });
}

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/publications_repository_impl.dart';
import '../../domain/repositories/publications_repository.dart';
import '../../data/models/publication_model.dart';

class PublicationsState {
  final List<PublicationModel> publications;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String selectedContentType;
  final String? selectedCategorySlug;
  final String searchQuery;

  PublicationsState({
    this.publications = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.selectedContentType = 'ALL',
    this.selectedCategorySlug,
    this.searchQuery = '',
  });

  PublicationsState copyWith({
    List<PublicationModel>? publications,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? selectedContentType,
    String? selectedCategorySlug,
    String? searchQuery,
  }) {
    return PublicationsState(
      publications: publications ?? this.publications,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      selectedContentType: selectedContentType ?? this.selectedContentType,
      selectedCategorySlug: selectedCategorySlug ?? this.selectedCategorySlug,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final publicationsRepositoryProvider = Provider<PublicationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PublicationsRepositoryImpl(dio: apiClient.dio);
});

final categoriesProvider = FutureProvider<List<PublicationCategoryModel>>((ref) async {
  final repository = ref.watch(publicationsRepositoryProvider);
  return repository.getCategories();
});

class PublicationsNotifier extends StateNotifier<PublicationsState> {
  final PublicationsRepository _repository;
  int _currentRequestToken = 0;

  PublicationsNotifier({required PublicationsRepository repository})
      : _repository = repository,
        super(PublicationsState()) {
    Future.microtask(() => loadNextPage());
  }

  Future<void> loadNextPage({bool force = false}) async {
    if (!force && (state.isLoading || !state.hasMore)) return;

    final requestToken = ++_currentRequestToken;
    state = state.copyWith(isLoading: true);

    try {
      final newPublications = await _repository.getPublications(
        page: state.page,
        categorySlug: state.selectedCategorySlug,
        contentType: state.selectedContentType,
        searchQuery: state.searchQuery,
      );

      if (requestToken != _currentRequestToken) return;

      state = state.copyWith(
        publications: [...state.publications, ...newPublications],
        page: state.page + 1,
        hasMore: newPublications.length >= 10,
        isLoading: false,
      );
    } catch (e) {
      if (requestToken == _currentRequestToken) {
        debugPrint('Error loading publications: $e');
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    }
  }

  Future<void> setContentType(String type) async {
    if (state.selectedContentType == type) return;
    _currentRequestToken++;
    state = state.copyWith(
      selectedContentType: type,
      page: 1,
      hasMore: true,
      publications: [],
      isLoading: false,
    );
    await loadNextPage(force: true);
  }

  Future<void> setCategorySlug(String? slug) async {
    if (state.selectedCategorySlug == slug) return;
    _currentRequestToken++;
    state = state.copyWith(
      selectedCategorySlug: slug,
      page: 1,
      hasMore: true,
      publications: [],
      isLoading: false,
    );
    await loadNextPage(force: true);
  }

  Future<void> setSearchQuery(String query) async {
    _currentRequestToken++;
    state = state.copyWith(
      searchQuery: query,
      page: 1,
      hasMore: true,
      publications: [],
      isLoading: false,
    );
    await loadNextPage(force: true);
  }
}

final publicationsProvider = StateNotifierProvider<PublicationsNotifier, PublicationsState>((ref) {
  final repository = ref.watch(publicationsRepositoryProvider);
  return PublicationsNotifier(repository: repository);
});

final publicationDetailProvider = FutureProvider.family<PublicationModel, String>((ref, slug) async {
  final repository = ref.watch(publicationsRepositoryProvider);
  return repository.getPublicationDetail(slug);
});

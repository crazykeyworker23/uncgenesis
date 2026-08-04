import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/devotionals_repository_impl.dart';
import '../../domain/repositories/devotionals_repository.dart';
import '../../data/models/devotional_model.dart';

class DevotionalsState {
  final List<DevotionalModel> devotionals;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String searchQuery;

  DevotionalsState({
    this.devotionals = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.searchQuery = '',
  });

  DevotionalsState copyWith({
    List<DevotionalModel>? devotionals,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? searchQuery,
  }) {
    return DevotionalsState(
      devotionals: devotionals ?? this.devotionals,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final devotionalsRepositoryProvider = Provider<DevotionalsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DevotionalsRepositoryImpl(dio: apiClient.dio);
});

class DevotionalsNotifier extends StateNotifier<DevotionalsState> {
  final DevotionalsRepository _repository;
  int _currentRequestToken = 0;

  DevotionalsNotifier({required DevotionalsRepository repository})
      : _repository = repository,
        super(DevotionalsState()) {
    Future.microtask(() => loadNextPage());
  }

  Future<void> loadNextPage({bool force = false}) async {
    if (!force && (state.isLoading || !state.hasMore)) return;

    final requestToken = ++_currentRequestToken;
    state = state.copyWith(isLoading: true);

    try {
      final newDevotionals = await _repository.getDevotionals(
        page: state.page,
        searchQuery: state.searchQuery,
      );

      if (requestToken != _currentRequestToken) return;

      state = state.copyWith(
        devotionals: [...state.devotionals, ...newDevotionals],
        page: state.page + 1,
        hasMore: newDevotionals.length >= 10,
        isLoading: false,
      );
    } catch (e) {
      if (requestToken == _currentRequestToken) {
        debugPrint('Error loading devotionals: $e');
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    }
  }

  Future<void> setSearchQuery(String query) async {
    _currentRequestToken++;
    state = state.copyWith(
      searchQuery: query,
      page: 1,
      hasMore: true,
      devotionals: [],
      isLoading: false,
    );
    await loadNextPage(force: true);
  }
}

final devotionalsProvider = StateNotifierProvider<DevotionalsNotifier, DevotionalsState>((ref) {
  final repository = ref.watch(devotionalsRepositoryProvider);
  return DevotionalsNotifier(repository: repository);
});

final devotionalDetailProvider = FutureProvider.family<DevotionalModel, String>((ref, slug) async {
  final repository = ref.watch(devotionalsRepositoryProvider);
  return repository.getDevotionalDetail(slug);
});

// Saved (favorite) devotionals persisted locally in SharedPreferences
class SavedDevotionalsNotifier extends StateNotifier<List<String>> {
  static const _key = 'saved_devotional_slugs';

  SavedDevotionalsNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    state = list;
  }

  Future<void> toggleFavorite(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(state);
    if (updated.contains(slug)) {
      updated.remove(slug);
    } else {
      updated.add(slug);
    }
    await prefs.setStringList(_key, updated);
    state = updated;
  }
}

final savedDevotionalsProvider = StateNotifierProvider<SavedDevotionalsNotifier, List<String>>((ref) {
  return SavedDevotionalsNotifier();
});

/// Devocionales marcados como favoritos, resueltos contra el backend.
///
/// Antes la pantalla cruzaba los slugs guardados con la lista ya cargada en
/// memoria: un favorito que no estuviera en la primera página simplemente no
/// aparecía. Ahora se pide cada uno por su slug.
final savedDevotionalsDetailProvider =
    FutureProvider.autoDispose<List<DevotionalModel>>((ref) async {
  final slugs = ref.watch(savedDevotionalsProvider);
  if (slugs.isEmpty) return const [];

  final repository = ref.watch(devotionalsRepositoryProvider);
  final results = await Future.wait(
    slugs.map((slug) async {
      try {
        return await repository.getDevotionalDetail(slug);
      } catch (_) {
        // Un devocional eliminado en el servidor no debe romper la lista.
        return null;
      }
    }),
  );

  return results.whereType<DevotionalModel>().toList();
});

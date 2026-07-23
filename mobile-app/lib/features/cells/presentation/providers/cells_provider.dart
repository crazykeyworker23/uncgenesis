import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/cells_repository_impl.dart';
import '../../domain/repositories/cells_repository.dart';
import '../../data/models/cell_model.dart';

class CellsState {
  final List<CellGroupModel> cells;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String? errorMessage;
  final String selectedMeetingDay;
  final String searchQuery;

  CellsState({
    this.cells = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.errorMessage,
    this.selectedMeetingDay = 'ALL',
    this.searchQuery = '',
  });

  CellsState copyWith({
    List<CellGroupModel>? cells,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? selectedMeetingDay,
    String? searchQuery,
  }) {
    return CellsState(
      cells: cells ?? this.cells,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedMeetingDay: selectedMeetingDay ?? this.selectedMeetingDay,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final cellsRepositoryProvider = Provider<CellsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CellsRepositoryImpl(dio: apiClient.dio);
});

class CellsNotifier extends StateNotifier<CellsState> {
  final CellsRepository _repository;
  int _currentRequestToken = 0;

  CellsNotifier({required CellsRepository repository})
      : _repository = repository,
        super(CellsState()) {
    Future.microtask(() => loadNextPage());
  }

  Future<void> loadNextPage({bool force = false}) async {
    if (!force && (state.isLoading || !state.hasMore)) return;

    final requestToken = ++_currentRequestToken;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final newCells = await _repository.getCells(
        page: state.page,
        meetingDay: state.selectedMeetingDay,
        searchQuery: state.searchQuery,
      );

      if (requestToken != _currentRequestToken) return;

      state = state.copyWith(
        cells: [...state.cells, ...newCells],
        page: state.page + 1,
        hasMore: newCells.length >= 10,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (requestToken == _currentRequestToken) {
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
          errorMessage: 'Error al conectar con el servidor. Verifica tu conexión.',
        );
      }
    }
  }

  Future<void> setMeetingDay(String day) async {
    if (state.selectedMeetingDay == day) return;
    _currentRequestToken++;
    state = state.copyWith(
      selectedMeetingDay: day,
      page: 1,
      hasMore: true,
      cells: [],
      isLoading: false,
      clearError: true,
    );
    await loadNextPage(force: true);
  }

  Future<void> setSearchQuery(String query) async {
    _currentRequestToken++;
    state = state.copyWith(
      searchQuery: query,
      page: 1,
      hasMore: true,
      cells: [],
      isLoading: false,
      clearError: true,
    );
    await loadNextPage(force: true);
  }

  Future<void> refresh() async {
    _currentRequestToken++;
    state = state.copyWith(
      page: 1,
      hasMore: true,
      cells: [],
      isLoading: false,
      clearError: true,
    );
    await loadNextPage(force: true);
  }
}

final cellsProvider = StateNotifierProvider<CellsNotifier, CellsState>((ref) {
  final repository = ref.watch(cellsRepositoryProvider);
  return CellsNotifier(repository: repository);
});

final cellDetailProvider = FutureProvider.family<CellGroupModel, String>((ref, slug) async {
  final repository = ref.watch(cellsRepositoryProvider);
  return repository.getCellDetail(slug);
});

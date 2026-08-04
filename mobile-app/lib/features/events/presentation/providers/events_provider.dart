import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/repositories/events_repository.dart';
import '../../data/models/event_model.dart';

class EventsState {
  final List<EventModel> events;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String? errorMessage;
  final String selectedFilterType;
  final String searchQuery;

  EventsState({
    this.events = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilterType = 'ALL',
    this.searchQuery = '',
  });

  EventsState copyWith({
    List<EventModel>? events,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? selectedFilterType,
    String? searchQuery,
  }) {
    return EventsState(
      events: events ?? this.events,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilterType: selectedFilterType ?? this.selectedFilterType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventsRepositoryImpl(dio: apiClient.dio);
});

class EventsNotifier extends StateNotifier<EventsState> {
  final EventsRepository _repository;
  int _currentRequestToken = 0;

  EventsNotifier({required EventsRepository repository})
      : _repository = repository,
        super(EventsState()) {
    Future.microtask(() => loadNextPage());
  }

  Future<void> loadNextPage({bool force = false}) async {
    if (!force && (state.isLoading || !state.hasMore)) return;

    final requestToken = ++_currentRequestToken;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final pageEvents = await _repository.getEvents(
        page: state.page,
        filterType: state.selectedFilterType,
        searchQuery: state.searchQuery,
      );

      if (requestToken != _currentRequestToken) return;

      // `hasMore` se calcula sobre la página completa devuelta por el servidor
      // y el filtro sólo afecta a lo que se muestra.
      final visibleEvents = _applyDateFilter(pageEvents, state.selectedFilterType);

      state = state.copyWith(
        events: [...state.events, ...visibleEvents],
        page: state.page + 1,
        hasMore: pageEvents.length >= 10,
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

  List<EventModel> _applyDateFilter(List<EventModel> events, String filterType) {
    if (filterType != 'UPCOMING' && filterType != 'PAST') return events;

    final now = DateTime.now();
    return events.where((event) {
      final startDate = DateTime.tryParse(event.startDate);
      if (startDate == null) return false;
      final localStart = startDate.isUtc ? startDate.toLocal() : startDate;
      return filterType == 'UPCOMING' ? localStart.isAfter(now) : localStart.isBefore(now);
    }).toList();
  }

  Future<void> setFilterType(String type) async {
    if (state.selectedFilterType == type) return;
    _currentRequestToken++;
    state = state.copyWith(
      selectedFilterType: type,
      page: 1,
      hasMore: true,
      events: [],
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
      events: [],
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
      events: [],
      isLoading: false,
      clearError: true,
    );
    await loadNextPage(force: true);
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  final repository = ref.watch(eventsRepositoryProvider);
  return EventsNotifier(repository: repository);
});

final eventDetailProvider = FutureProvider.family<EventModel, String>((ref, slug) async {
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.getEventDetail(slug);
});

/// Inscripciones del usuario autenticado.
///
/// Antes "Mis Inscripciones" filtraba la lista ya cargada en memoria, así que
/// mostraba "no estás inscrito" si la pantalla de eventos no se había abierto
/// o si la inscripción estaba en una página posterior.
final myRegisteredEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.getMyRegisteredEvents();
});

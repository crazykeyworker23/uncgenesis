import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/services_repository_impl.dart';
import '../../domain/repositories/services_repository.dart';
import '../../data/models/service_model.dart';

class ServicesState {
  final List<ChurchServiceModel> services;
  final int page;
  final bool hasMore;
  final bool isLoading;

  ServicesState({
    this.services = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
  });

  ServicesState copyWith({
    List<ChurchServiceModel>? services,
    int? page,
    bool? hasMore,
    bool? isLoading,
  }) {
    return ServicesState(
      services: services ?? this.services,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServicesRepositoryImpl(dio: apiClient.dio);
});

class ServicesNotifier extends StateNotifier<ServicesState> {
  final ServicesRepository _repository;
  int _currentRequestToken = 0;

  ServicesNotifier({required ServicesRepository repository})
      : _repository = repository,
        super(ServicesState()) {
    Future.microtask(() => loadNextPage());
  }

  Future<void> loadNextPage({bool force = false}) async {
    if (!force && (state.isLoading || !state.hasMore)) return;

    final requestToken = ++_currentRequestToken;
    state = state.copyWith(isLoading: true);

    try {
      final newServices = await _repository.getServices(page: state.page);

      if (requestToken != _currentRequestToken) return;

      state = state.copyWith(
        services: [...state.services, ...newServices],
        page: state.page + 1,
        hasMore: newServices.length >= 10,
        isLoading: false,
      );
    } catch (e) {
      if (requestToken == _currentRequestToken) {
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    }
  }

  Future<void> refresh() async {
    _currentRequestToken++;
    state = ServicesState();
    await loadNextPage(force: true);
  }
}

final servicesProvider = StateNotifierProvider<ServicesNotifier, ServicesState>((ref) {
  final repository = ref.watch(servicesRepositoryProvider);
  return ServicesNotifier(repository: repository);
});

final serviceDetailProvider = FutureProvider.family<ChurchServiceModel, String>((ref, slug) async {
  final repository = ref.watch(servicesRepositoryProvider);
  return repository.getServiceDetail(slug);
});

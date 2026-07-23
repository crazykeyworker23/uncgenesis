import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/models/public_settings_model.dart';
import '../../../publications/data/models/publication_model.dart';
import '../../../devotionals/data/models/devotional_model.dart';
import '../../../events/data/models/event_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeRepositoryImpl(dio: apiClient.dio);
});

final publicSettingsProvider = FutureProvider<PublicSettingsModel>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getPublicSettings();
});

final recentPublicationsProvider = FutureProvider<List<PublicationModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getRecentPublications();
});

final todayDevotionalProvider = FutureProvider<DevotionalModel?>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getTodayDevotional();
});

final upcomingEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getUpcomingEvents();
});

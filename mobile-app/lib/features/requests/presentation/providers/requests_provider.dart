import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/requests_repository_impl.dart';
import '../../domain/repositories/requests_repository.dart';

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RequestsRepositoryImpl(dio: apiClient.dio);
});

final cellStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.dio.get('/visitor-requests/my-status/');
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return {'assigned_cell': null, 'pending_request': null};
  }
});

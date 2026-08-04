import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';

class MyEventsPage extends ConsumerWidget {
  const MyEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Inscripciones'),
      ),
      // Las inscripciones sólo existen con sesión iniciada: en modo invitado se
      // explica en lugar de mostrar una lista vacía sin contexto.
      body: authState.isGuest ? const _GuestView() : const _RegisteredEventsList(),
    );
  }
}

class _RegisteredEventsList extends ConsumerWidget {
  const _RegisteredEventsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myRegisteredEventsProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.dorado)),
      error: (error, _) => _ErrorView(
        message: ApiError.message(error, fallback: 'No pudimos cargar tus inscripciones.'),
        onRetry: () => ref.invalidate(myRegisteredEventsProvider),
      ),
      data: (events) {
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRegisteredEventsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 64, color: AppColors.dorado),
                      const SizedBox(height: 16),
                      Text(
                        'Todavía no estás inscrito en ningún evento.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.crema.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/events'),
                        child: const Text('EXPLORAR EVENTOS'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myRegisteredEventsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final formattedDate = DateFormatter.longDate(event.startDate);
              final formattedTime = DateFormatter.time(event.startDate);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/events/${event.slug}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.darkTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime != null
                                    ? '$formattedDate · $formattedTime'
                                    : formattedDate,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.doradoClaro),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.location,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.crema.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, color: AppColors.dorado, size: 14),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_outlined, size: 64, color: AppColors.dorado),
            const SizedBox(height: 16),
            Text(
              'Inicia sesión para ver tus inscripciones',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.doradoClaro, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Las inscripciones a eventos quedan guardadas en tu cuenta.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/auth/login'),
              child: const Text('INICIAR SESIÓN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.dorado),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('REINTENTAR')),
          ],
        ),
      ),
    );
  }
}

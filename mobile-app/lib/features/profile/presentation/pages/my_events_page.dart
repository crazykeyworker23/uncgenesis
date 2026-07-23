import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../events/presentation/providers/events_provider.dart';

class MyEventsPage extends ConsumerWidget {
  const MyEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState = ref.watch(eventsProvider);

    // Filter events where is_registered is true
    final registeredEvents = eventsState.events.where((e) => e.isRegistered ?? false).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Inscripciones'),
      ),
      body: registeredEvents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_available_outlined, size: 64, color: AppColors.dorado),
                    const SizedBox(height: 16),
                    Text(
                      'No estás inscrito en ningún evento.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.5)),
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
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(eventsProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: registeredEvents.length,
                itemBuilder: (context, index) {
                  final event = registeredEvents[index];
                  final formattedDate = event.startDate.split('T')[0];

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
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha: $formattedDate • Lugar: ${event.location}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.doradoClaro,
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
            ),
    );
  }
}

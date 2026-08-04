import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/storage/local_requests_store.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../requests/presentation/providers/requests_provider.dart';

/// Historial de peticiones de oración y solicitudes de visita enviadas desde
/// este dispositivo. Funciona igual en modo invitado y con sesión iniciada.
class MyRequestsPage extends ConsumerWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(submittedRequestsProvider);
    final cellStatusAsync = ref.watch(cellStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        actions: [
          if (requests.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar historial',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado de la solicitud de visita gestionada por la iglesia.
          cellStatusAsync.maybeWhen(
            data: (status) {
              final assignedCell = status['assigned_cell'];
              final pending = status['pending_request'];
              if (assignedCell == null && pending == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: assignedCell != null
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.dorado.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        assignedCell != null ? Icons.groups_rounded : Icons.hourglass_bottom_rounded,
                        color: assignedCell != null ? AppColors.success : AppColors.dorado,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignedCell != null ? 'Célula asignada' : 'Solicitud en proceso',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.doradoClaro,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              assignedCell != null
                                  ? (assignedCell['name']?.toString() ?? 'Tu célula')
                                  : 'Nuestro equipo ya recibió tu solicitud y se pondrá en contacto contigo.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          if (requests.isEmpty)
            _EmptyState(onSend: () => context.push('/connect'))
          else ...[
            Text(
              'HISTORIAL DE ESTE DISPOSITIVO',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.doradoClaro,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ...requests.map((request) => _RequestCard(
                  request: request,
                  onDelete: () => ref.read(submittedRequestsProvider.notifier).remove(request.id),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Vaciar historial', style: AppTextStyles.titleMedium),
        content: Text(
          'Se borrará el registro local de tus solicitudes. Las solicitudes ya enviadas seguirán recibidas por la iglesia.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.crema)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('VACIAR', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(submittedRequestsProvider.notifier).clear();
    }
  }
}

class _RequestCard extends StatelessWidget {
  final SubmittedRequest request;
  final VoidCallback onDelete;

  const _RequestCard({required this.request, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPrayer = request.type == SubmittedRequestType.prayer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.darkTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPrayer ? Icons.favorite : Icons.home_outlined,
                    color: AppColors.dorado,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.typeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.doradoClaro,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.subject.isNotEmpty ? request.subject : 'Sin asunto',
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar del historial',
                  icon: Icon(Icons.close, size: 18, color: AppColors.crema.withValues(alpha: 0.5)),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (request.detail.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                request.detail,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.75),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: AppColors.crema.withValues(alpha: 0.45)),
                const SizedBox(width: 5),
                Text(
                  'Enviada ${DateFormatter.relative(request.sentAt, fallback: 'recientemente').toLowerCase()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                if (request.isAnonymous) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.darkTeal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ANÓNIMA',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.doradoClaro,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSend;

  const _EmptyState({required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 8),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.dorado),
          const SizedBox(height: 16),
          Text(
            'Todavía no has enviado solicitudes',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.doradoClaro, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí verás tus peticiones de oración y solicitudes de visita enviadas desde este dispositivo.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onSend, child: const Text('ENVIAR UNA SOLICITUD')),
        ],
      ),
    );
  }
}

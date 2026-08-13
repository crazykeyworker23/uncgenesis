import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/events_provider.dart';
import '../../data/models/event_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final String slug;

  const EventDetailPage({
    super.key,
    required this.slug,
  });

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool _isSubmitting = false;

  Future<void> _openMap(String location) async {
    final query = Uri.encodeComponent(location);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    // Antes fallaba en silencio si no había app de mapas disponible.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No pudimos abrir el mapa en este dispositivo.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _register(int id) async {
    if (ref.read(authProvider).isGuest) {
      // El invitado ahora puede ir directo al login desde el mismo aviso.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Inicia sesión para inscribirte a los eventos.'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'INICIAR SESIÓN',
              textColor: AppColors.deepTeal,
              onPressed: () => context.push('/auth/login'),
            ),
          ),
        );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(eventsRepositoryProvider);
      await repository.registerToEvent(id);

      // Refrescamos antes de avisar para que el botón quede en "YA ESTÁS
      // REGISTRADO" y la lista de "Mis Inscripciones" incluya este evento.
      ref.invalidate(eventDetailProvider(widget.slug));
      ref.read(eventsProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('¡Te has inscrito con éxito a este evento!'),
              backgroundColor: AppColors.success,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                ApiError.message(e, fallback: 'No pudimos completar tu inscripción. Intenta de nuevo.'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(eventDetailProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Evento'),
      ),
      body: detailAsync.when(
        data: (event) => _EventDetailBody(
          event: event,
          isSubmitting: _isSubmitting,
          onRegister: () => _register(event.id),
          onOpenMap: () => _openMap(event.location),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al cargar el evento.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(eventDetailProvider(widget.slug)),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  final EventModel event;
  final bool isSubmitting;
  final VoidCallback onRegister;
  final VoidCallback onOpenMap;

  const _EventDetailBody({
    required this.event,
    required this.isSubmitting,
    required this.onRegister,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    // `split('T')[1]` reventaba con RangeError cuando el evento venía sólo con
    // fecha (sin hora). Ahora el formateo es seguro y en español.
    final formattedDate = DateFormatter.dateRange(event.startDate, event.endDate);
    final formattedTime = DateFormatter.timeRange(event.startDate, event.endDate);
    final isFull = event.capacity != null && (event.registeredCount ?? 0) >= event.capacity!;
    final isRegistered = event.isRegistered == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cover Image
          if (event.coverImage != null)
            Image.network(
              event.coverImage!,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: AppColors.darkTeal,
                child: const Icon(Icons.event, color: AppColors.dorado, size: 60),
              ),
            ),

          // 2. Main Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dorado.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.requiresRegistration ? 'REQUIERE INSCRIPCIÓN' : 'ACCESO LIBRE',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.doradoClaro),
                      ),
                    ),
                    if (isRegistered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'INSCRITO',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  event.title,
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 26, height: 1.2),
                ),
                const SizedBox(height: 20),

                // Details Row 1 (Date)
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Fecha',
                  subtitle: formattedTime != null
                      ? '$formattedDate · $formattedTime'
                      : formattedDate,
                ),
                const SizedBox(height: 16),

                // Details Row 2 (Location)
                GestureDetector(
                  onTap: onOpenMap,
                  child: _InfoRow(
                    icon: Icons.location_on_outlined,
                    title: 'Lugar (Toca para ver mapa)',
                    subtitle: event.location,
                    subtitleColor: AppColors.doradoClaro,
                  ),
                ),
                const SizedBox(height: 16),

                // Details Row 3 (Capacity)
                _InfoRow(
                  icon: Icons.people_outline,
                  title: 'Aforo disponible',
                  subtitle: event.capacity != null 
                      ? '${event.registeredCount ?? 0} registrados de ${event.capacity} cupos' 
                      : 'Aforo ilimitado',
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.darkTeal),
                const SizedBox(height: 16),

                // Description
                Text(
                  'ACERCA DEL EVENTO',
                  style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ),
                const SizedBox(height: 36),

                // 3. Action registration button
                if (event.requiresRegistration)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isSubmitting || isRegistered || isFull) ? null : onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRegistered ? AppColors.success : AppColors.dorado,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.deepTeal,
                              ),
                            )
                          : Text(
                              isRegistered
                                  ? '¡YA ESTÁS REGISTRADO!'
                                  : isFull
                                      ? 'AFORO COMPLETO'
                                      : 'CONFIRMAR ASISTENCIA',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isRegistered ? AppColors.white : AppColors.deepTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.dorado.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: AppColors.dorado, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.crema.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: subtitleColor ?? AppColors.crema,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/services_provider.dart';
import '../../data/models/service_model.dart';

class ServiceDetailPage extends ConsumerWidget {
  final String slug;

  const ServiceDetailPage({super.key, required this.slug});

  Future<void> _launchMediaUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      bool launched = false;

      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (_) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppBrowserView,
          );
        } catch (_) {}
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el enlace: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Servicio'),
      ),
      body: serviceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el servicio: $err',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        data: (service) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Status Badge
                if (service.isLive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.live_tv, size: 16, color: Colors.redAccent),
                        SizedBox(width: 6),
                        Text(
                          'EN VIVO AHORA',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Service Title
                Text(
                  service.title,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.dorado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Date & Views
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.crema),
                    const SizedBox(width: 4),
                    Text(
                      service.date,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.crema),
                    const SizedBox(width: 4),
                    Text(
                      '${service.viewsCount} reproducciones',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons (Video / Audio)
                if (service.videoUrl != null || service.audioUrl != null) ...[
                  Row(
                    children: [
                      if (service.videoUrl != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchMediaUrl(context, service.videoUrl!),
                            icon: const Icon(Icons.play_circle_fill, color: AppColors.deepTeal),
                            label: const Text('Ver Prédica en Video'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dorado,
                              foregroundColor: AppColors.deepTeal,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (service.videoUrl != null && service.audioUrl != null)
                        const SizedBox(width: 12),
                      if (service.audioUrl != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchMediaUrl(context, service.audioUrl!),
                            icon: const Icon(Icons.headphones, color: AppColors.dorado),
                            label: const Text('Escuchar Audio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dorado,
                              side: const BorderSide(color: AppColors.dorado),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Scripture Verses Section
                if (service.verses.isNotEmpty) ...[
                  const Text(
                    'Pasajes Bíblicos',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...service.verses.map((v) => _VerseCard(verse: v)),
                  const SizedBox(height: 24),
                ],

                // Sermon Notes Section
                if (service.sermonNotes != null && service.sermonNotes!.isNotEmpty) ...[
                  const Text(
                    'Notas de la Prédica',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dorado.withOpacity(0.2)),
                    ),
                    child: Text(
                      service.sermonNotes!,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final ServiceVerseModel verse;

  const _VerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dorado.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, size: 16, color: AppColors.dorado),
              const SizedBox(width: 6),
              Text(
                '${verse.book} ${verse.chapter}:${verse.verses}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.dorado,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${verse.text}"',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.crema,
            ),
          ),
        ],
      ),
    );
  }
}

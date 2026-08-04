import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/devotionals_provider.dart';
import '../../data/models/devotional_model.dart';

class DevotionalDetailPage extends ConsumerWidget {
  final String slug;

  const DevotionalDetailPage({
    super.key,
    required this.slug,
  });

  void _toggleSave(BuildContext context, WidgetRef ref, bool wasSaved) {
    ref.read(savedDevotionalsProvider.notifier).toggleFavorite(slug);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? 'Devocional quitado de guardados.'
                : 'Devocional guardado. Lo encontrarás en tu perfil.',
          ),
          backgroundColor: wasSaved ? AppColors.darkTeal : AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _playAudio(BuildContext context, String url) async {
    if (url.trim().isNotEmpty) {
      try {
        final launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (launched || !context.mounted) return;
      } catch (_) {
        if (!context.mounted) return;
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el enlace del audio.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(devotionalDetailProvider(slug));
    final savedSlugs = ref.watch(savedDevotionalsProvider);
    final isSaved = savedSlugs.contains(slug);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devocional Diario'),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Quitar de guardados' : 'Guardar devocional',
            icon: Icon(
              isSaved ? Icons.star : Icons.star_border,
              color: isSaved ? AppColors.dorado : AppColors.crema,
            ),
            // Guardar es una acción silenciosa: sin confirmación no quedaba
            // claro que el devocional se había añadido a "Guardados".
            onPressed: () => _toggleSave(context, ref, isSaved),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (devotional) => _DevotionalDetailBody(
          devotional: devotional,
          isSaved: isSaved,
          onToggleSave: () => _toggleSave(context, ref, isSaved),
          onPlayAudio: () => _playAudio(context, devotional.audioUrl ?? ''),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al cargar el devocional.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(devotionalDetailProvider(slug)),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevotionalDetailBody extends StatelessWidget {
  final DevotionalModel devotional;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onPlayAudio;

  const _DevotionalDetailBody({
    required this.devotional,
    required this.isSaved,
    required this.onToggleSave,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio = devotional.audioUrl != null && devotional.audioUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header (Date & Title)
          Text(
            DateFormatter.fullDate(devotional.date, fallback: 'Devocional').toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.crema.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            devotional.title,
            style: AppTextStyles.displayLarge.copyWith(fontSize: 26, height: 1.2),
          ),
          const SizedBox(height: 20),

          // 2. Audio Option Banner (if available)
          if (hasAudio) ...[
            InkWell(
              onTap: onPlayAudio,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.darkTeal, AppColors.cardColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dorado.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.dorado,
                      child: Icon(Icons.play_arrow, color: AppColors.deepTeal),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUDIO DEVOCIONAL DISPONIBLE',
                            style: TextStyle(
                              color: AppColors.doradoClaro,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toca aquí para escuchar el audio de hoy',
                            style: TextStyle(
                              color: AppColors.crema,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Bible Passage block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardColor.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: const Border(
                left: BorderSide(
                  color: AppColors.dorado,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  devotional.biblePassage,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.doradoClaro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  devotional.bibleText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.crema.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Main content body
          Text(
            devotional.content,
            style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

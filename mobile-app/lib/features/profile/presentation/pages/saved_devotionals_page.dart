import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../devotionals/presentation/providers/devotionals_provider.dart';

class SavedDevotionalsPage extends ConsumerWidget {
  const SavedDevotionalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedDevotionalsDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Devocionales Guardados'),
      ),
      body: savedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.dorado)),
        error: (error, _) => _MessageView(
          icon: Icons.cloud_off_outlined,
          message: ApiError.message(error, fallback: 'No pudimos cargar tus devocionales guardados.'),
          actionLabel: 'REINTENTAR',
          onAction: () => ref.invalidate(savedDevotionalsDetailProvider),
        ),
        data: (devotionals) {
          if (devotionals.isEmpty) {
            return _MessageView(
              icon: Icons.star_border,
              message:
                  'No tienes devocionales guardados.\nToca la estrella en un devocional para guardarlo aquí.',
              actionLabel: 'VER DEVOCIONALES',
              onAction: () => context.push('/devotionals'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(savedDevotionalsDetailProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devotionals.length,
              itemBuilder: (context, index) {
                final dev = devotionals[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/devotionals/${dev.slug}'),
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
                            child: const Icon(Icons.menu_book, color: AppColors.dorado, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dev.title,
                                  style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dev.biblePassage,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.doradoClaro),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.shortDate(dev.date, fallback: ''),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.crema.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar de guardados',
                            icon: const Icon(Icons.star, color: AppColors.dorado),
                            onPressed: () {
                              ref.read(savedDevotionalsProvider.notifier).toggleFavorite(dev.slug);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Text('Devocional quitado de guardados.'),
                                    backgroundColor: AppColors.darkTeal,
                                    action: SnackBarAction(
                                      label: 'DESHACER',
                                      textColor: AppColors.dorado,
                                      onPressed: () => ref
                                          .read(savedDevotionalsProvider.notifier)
                                          .toggleFavorite(dev.slug),
                                    ),
                                  ),
                                );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageView({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.dorado),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.crema.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

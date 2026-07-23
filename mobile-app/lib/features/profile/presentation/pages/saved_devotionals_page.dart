import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../devotionals/presentation/providers/devotionals_provider.dart';

class SavedDevotionalsPage extends ConsumerWidget {
  const SavedDevotionalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSlugs = ref.watch(savedDevotionalsProvider);
    final devotionalsState = ref.watch(devotionalsProvider);

    final savedDevotionals = devotionalsState.devotionals
        .where((d) => savedSlugs.contains(d.slug))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Devocionales Guardados'),
      ),
      body: savedDevotionals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_border, size: 64, color: AppColors.dorado),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes devocionales guardados.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedDevotionals.length,
              itemBuilder: (context, index) {
                final dev = savedDevotionals[index];

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
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dev.biblePassage,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.doradoClaro,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.star, color: AppColors.dorado),
                            onPressed: () {
                              ref.read(savedDevotionalsProvider.notifier).toggleFavorite(dev.slug);
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
  }
}

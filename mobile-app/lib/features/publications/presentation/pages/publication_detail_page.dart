import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/publications_provider.dart';
import '../../data/models/publication_model.dart';

class PublicationDetailPage extends ConsumerWidget {
  final String slug;

  const PublicationDetailPage({
    super.key,
    required this.slug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(publicationDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Publicación'),
      ),
      body: detailAsync.when(
        data: (publication) => _PublicationDetailBody(publication: publication),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al cargar la publicación.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(publicationDetailProvider(slug)),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicationDetailBody extends StatelessWidget {
  final PublicationModel publication;

  const _PublicationDetailBody({required this.publication});

  @override
  Widget build(BuildContext context) {
    final hasGallery = publication.galleryImages != null && publication.galleryImages!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cover Image
          if (publication.coverImage != null)
            Image.network(
              publication.coverImage!,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: AppColors.darkTeal,
                child: const Icon(Icons.image_outlined, color: AppColors.dorado, size: 60),
              ),
            ),

          // 2. Info Container
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Date row
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
                        publication.contentType.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.doradoClaro),
                      ),
                    ),
                    if (publication.publishedAt != null)
                      Text(
                        DateFormatter.fullDate(publication.publishedAt),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  publication.title,
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 26, height: 1.2),
                ),
                const SizedBox(height: 12),

                // Author Row
                if (publication.author != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.dorado,
                        backgroundImage: publication.author!.avatar != null
                            ? NetworkImage(publication.author!.avatar!)
                            : null,
                        child: publication.author!.avatar == null
                            ? Text(
                                publication.author!.fullName.isNotEmpty ? publication.author!.fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: AppColors.deepTeal, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            publication.author!.fullName,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Autor de la publicación',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.5), fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.darkTeal),
                const SizedBox(height: 16),

                // Content body text
                Text(
                  publication.content,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ),
                const SizedBox(height: 28),

                // 3. Image Gallery Section (if available)
                if (hasGallery) ...[
                  Text(
                    'GALERÍA DE IMÁGENES',
                    style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: publication.galleryImages!.length,
                      itemBuilder: (context, index) {
                        final img = publication.galleryImages![index];
                        return Container(
                          width: 240,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    img.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: AppColors.darkTeal,
                                      child: const Icon(Icons.image_outlined, color: AppColors.dorado),
                                    ),
                                  ),
                                ),
                                if (img.caption != null && img.caption!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Text(
                                      img.caption!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Tags section
                if (publication.tags != null && publication.tags!.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: publication.tags!.map((tag) {
                      return Chip(
                        label: Text('#${tag.name}', style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.darkTeal.withValues(alpha: 0.5),
                        side: BorderSide(color: AppColors.dorado.withValues(alpha: 0.1)),
                        labelStyle: const TextStyle(color: AppColors.dorado),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

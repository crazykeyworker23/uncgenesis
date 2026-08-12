import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_images.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/publications_provider.dart';
import '../../data/models/publication_model.dart';

class PublicationsPage extends ConsumerStatefulWidget {
  const PublicationsPage({super.key});

  @override
  ConsumerState<PublicationsPage> createState() => _PublicationsPageState();
}

class _PublicationsPageState extends ConsumerState<PublicationsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll > 0 && currentScroll >= maxScroll - 50) {
      Future.microtask(() {
        if (mounted) {
          ref.read(publicationsProvider.notifier).loadNextPage();
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final contentTypes = [
      {'label': 'Todas', 'value': 'ALL'},
      {'label': 'Noticias', 'value': 'NEWS'},
      {'label': 'Servicios', 'value': 'SERVICE'},
      {'label': 'Jóvenes', 'value': 'YOUTH'},
      {'label': 'Devocionales', 'value': 'DEVOTIONAL'},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Logo + App name & Bell badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 38),
                      const SizedBox(width: 8),
                      Text(
                        'GÉNESIS APP',
                        style: AppTextStyles.titleMedium.copyWith(
                          letterSpacing: 2.0,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.dorado,
                          size: 28,
                        ),
                        // Contador real de no leídas (antes fijo en "3").
                        if (unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
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
            ),

            // Large Title: Publicaciones
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Text(
                'Publicaciones',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),

            // Filter pills (Horizontal selection bar)
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: contentTypes.length,
                itemBuilder: (context, index) {
                  final type = contentTypes[index];
                  final isSelected = state.selectedContentType == type['value'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(publicationsProvider.notifier).setContentType(type['value']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.dorado : AppColors.deepTeal.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.dorado : AppColors.dorado.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          type['label']!,
                          style: TextStyle(
                            color: isSelected ? AppColors.deepTeal : AppColors.crema,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // List containing Banner + Feed List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.read(publicationsProvider.notifier).setSearchQuery(_searchController.text);
                },
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    // Featured Banner Card: Publicaciones por servicio
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.dorado.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: 'https://images.unsplash.com/photo-1438242447336-f68677c7b2a3?q=80&w=600',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.darkGreen),
                              errorWidget: (context, url, error) => Container(color: AppColors.darkGreen),
                            ),
                          ),
                          // Dark gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ),
                              ),
                            ),
                          ),
                          // Text and Button
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Publicaciones\npor servicio',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Encuentra aquí todo lo compartido en cada servicio.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.crema.withValues(alpha: 0.8),
                                  ),
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/services'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.dorado,
                                      foregroundColor: AppColors.deepTeal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Ver servicios >',
                                      style: TextStyle(
                                        fontSize: 11,
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
                    ),

                    // Feed Items Title
                    if (state.publications.isNotEmpty) ...[
                      const Text(
                        'Recientes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Feed Items
                    if (state.publications.isEmpty && !state.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No se encontraron publicaciones.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        state.publications.length,
                        (index) {
                          final pub = state.publications[index];
                          return _HorizontalPublicationCard(publication: pub);
                        },
                      ),

                    if (state.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.dorado),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalPublicationCard extends StatelessWidget {
  final PublicationModel publication;

  const _HorizontalPublicationCard({required this.publication});

  Widget _buildCoverImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(
        Icons.image_outlined,
        color: AppColors.dorado,
        size: 28,
      );
    }

    try {
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return const Icon(
          Icons.image_outlined,
          color: AppColors.dorado,
          size: 28,
        );
      }
    } catch (_) {
      return const Icon(
        Icons.image_outlined,
        color: AppColors.dorado,
        size: 28,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.dorado,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.image_outlined,
        color: AppColors.dorado,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.deepTeal.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dorado.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/publications/${publication.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Left side thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.darkGreen,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildCoverImage(publication.coverImage),
              ),
              const SizedBox(width: 16),

              // Middle: Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      // Antes, sin fecha real, se mostraba una fecha inventada
                      // fija ("25 de mayo, 2025") que confundía al lector.
                      DateFormatter.fullDate(publication.publishedAt, fallback: 'Sin fecha'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side chevron arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.dorado,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

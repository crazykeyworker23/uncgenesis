import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/services_provider.dart';
import '../../data/models/service_model.dart';
import 'service_detail_page.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll - 50) {
      Future.microtask(() {
        if (mounted) {
          ref.read(servicesProvider.notifier).loadNextPage();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Prédicas'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(servicesProvider.notifier).refresh();
        },
        color: AppColors.dorado,
        child: state.services.isEmpty && !state.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 48, color: AppColors.crema),
                      SizedBox(height: 12),
                      Text(
                        'No hay servicios o prédicas disponibles.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.services.length + (state.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.services.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppColors.dorado),
                      ),
                    );
                  }

                  final service = state.services[index];
                  return _ServiceCard(service: service);
                },
              ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ChurchServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: service.isLive
              ? Colors.redAccent
              : AppColors.dorado.withValues(alpha: 0.2),
          width: service.isLive ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceDetailPage(slug: service.slug),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Status Badge or Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (service.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.live_tv, size: 14, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text(
                            'EN VIVO',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.dorado),
                        const SizedBox(width: 6),
                        Text(
                          service.date,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.dorado,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.crema),
                      const SizedBox(width: 4),
                      Text(
                        '${service.viewsCount}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                service.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Sermon Notes Snippet
              if (service.sermonNotes != null && service.sermonNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  service.sermonNotes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crema.withValues(alpha: 0.8),
                  ),
                ),
              ],

              // Verses Chips
              if (service.verses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: service.verses.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.dorado.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.dorado.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${v.book} ${v.chapter}:${v.verses}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.dorado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: Colors.white10),

              // Bottom Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (service.videoUrl != null)
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, size: 16, color: AppColors.dorado),
                              SizedBox(width: 4),
                              Text('Video', style: TextStyle(fontSize: 12, color: AppColors.crema)),
                            ],
                          ),
                        ),
                      if (service.audioUrl != null)
                        const Row(
                          children: [
                            Icon(Icons.headphones, size: 16, color: AppColors.dorado),
                            SizedBox(width: 4),
                            Text('Audio', style: TextStyle(fontSize: 12, color: AppColors.crema)),
                          ],
                        ),
                    ],
                  ),

                  Row(
                    children: [
                      Text(
                        'Ver Prédica',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.dorado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.dorado),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

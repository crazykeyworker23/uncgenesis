import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/service_card.dart';
import '../providers/services_provider.dart';

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
                  return ServiceCard(service: service);
                },
              ),
      ),
    );
  }
}


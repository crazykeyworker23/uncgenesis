import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/events_provider.dart';
import '../../data/models/event_model.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(eventsProvider);
      if (state.events.isEmpty && !state.isLoading) {
        ref.read(eventsProvider.notifier).refresh();
      }
    });
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
          ref.read(eventsProvider.notifier).loadNextPage();
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(eventsProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);

    final filters = [
      {'label': 'Todos', 'value': 'ALL'},
      {'label': 'Próximos', 'value': 'UPCOMING'},
      {'label': 'Pasados', 'value': 'PAST'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search, color: AppColors.dorado),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.crema),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(eventsProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Horizontal Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final f = filters[index];
                final isSelected = state.selectedFilterType == f['value'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(f['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(eventsProvider.notifier).setFilterType(f['value']!);
                    },
                    selectedColor: AppColors.dorado,
                    backgroundColor: AppColors.cardColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.deepTeal : AppColors.crema,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Event List Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(eventsProvider.notifier).refresh();
              },
              child: _buildEventListContent(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventListContent(BuildContext context, EventsState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.dorado),
      );
    }

    if (state.errorMessage != null && state.events.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.dorado),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(eventsProvider.notifier).refresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dorado,
                  foregroundColor: AppColors.deepTeal,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('REINTENTAR CONEXIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.events.isEmpty && !state.isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_outlined, size: 54, color: AppColors.dorado),
              const SizedBox(height: 16),
              const Text(
                'No se encontraron eventos para este criterio.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(eventsProvider.notifier).setSearchQuery('');
                  ref.read(eventsProvider.notifier).setFilterType('ALL');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardColor,
                  foregroundColor: AppColors.dorado,
                ),
                child: const Text('VER TODOS LOS EVENTOS'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: state.events.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.events.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.dorado),
            ),
          );
        }

        final event = state.events[index];
        return _LargeEventCard(event: event);
      },
    );
  }
}

class _LargeEventCard extends StatelessWidget {
  final EventModel event;

  const _LargeEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateOnly = event.startDate.split('T')[0];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${event.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.coverImage != null)
              Image.network(
                event.coverImage!,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: AppColors.darkTeal,
                  child: const Icon(Icons.event, color: AppColors.dorado, size: 50),
                ),
              )
            else
              Container(
                height: 120,
                color: AppColors.darkTeal,
                child: const Icon(Icons.event, color: AppColors.dorado, size: 40),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dorado.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.requiresRegistration ? 'REQUIERE REGISTRO' : 'ACCESO LIBRE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.doradoClaro,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Text(
                        dateOnly,
                        style: TextStyle(
                          color: AppColors.crema.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.dorado),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.crema.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (event.capacity != null)
                        Text(
                          'Cupos: ${event.registeredCount ?? 0}/${event.capacity}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crema.withValues(alpha: 0.5),
                          ),
                        )
                      else
                        Text(
                          'Aforo ilimitado',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crema.withValues(alpha: 0.5),
                          ),
                        ),
                      const Icon(Icons.arrow_forward_outlined, size: 18, color: AppColors.dorado),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

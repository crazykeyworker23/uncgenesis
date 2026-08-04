import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/cells_provider.dart';
import '../../data/models/cell_model.dart';
import '../../../requests/presentation/providers/requests_provider.dart';

class CellsPage extends ConsumerStatefulWidget {
  const CellsPage({super.key});

  @override
  ConsumerState<CellsPage> createState() => _CellsPageState();
}

class _CellsPageState extends ConsumerState<CellsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(cellsProvider);
      if (state.cells.isEmpty && !state.isLoading) {
        ref.read(cellsProvider.notifier).refresh();
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
          ref.read(cellsProvider.notifier).loadNextPage();
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(cellsProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cellsProvider);
    final cellStatusAsync = ref.watch(cellStatusProvider);

    final days = [
      {'label': 'Todos', 'value': 'ALL'},
      {'label': 'Lunes', 'value': 'MONDAY'},
      {'label': 'Martes', 'value': 'TUESDAY'},
      {'label': 'Miércoles', 'value': 'WEDNESDAY'},
      {'label': 'Jueves', 'value': 'THURSDAY'},
      {'label': 'Viernes', 'value': 'FRIDAY'},
      {'label': 'Sábado', 'value': 'SATURDAY'},
      {'label': 'Domingo', 'value': 'SUNDAY'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Células de la Iglesia')),
      body: Column(
        children: [
          // "Mi Célula Asignada" Banner if accepted
          cellStatusAsync.maybeWhen(
            data: (statusData) {
              final assignedCell = statusData['assigned_cell'];
              if (assignedCell == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dorado, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.dorado, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '¡TU CÉLULA ASIGNADA!',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.dorado,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dorado.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'MIEMBRO',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.dorado, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assignedCell['name'] ?? '',
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reuniones: ${assignedCell['meeting_day'] ?? ''} • ${DateFormatter.clockTime(assignedCell['meeting_time'])} HS\nDirección: ${assignedCell['address'] ?? ''}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.crema.withValues(alpha: 0.8), height: 1.3),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, distrito o dirección...',
                prefixIcon: const Icon(Icons.search, color: AppColors.dorado),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.crema),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(cellsProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Horizontal Meeting Days Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final d = days[index];
                final isSelected = state.selectedMeetingDay == d['value'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(d['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(cellsProvider.notifier)
                          .setMeetingDay(d['value']!);
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

          // 3. Main Body Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.dorado,
              backgroundColor: AppColors.cardColor,
              onRefresh: () async {
                ref.invalidate(cellStatusProvider);
                await ref.read(cellsProvider.notifier).refresh();
              },
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CellsState state) {
    if (state.isLoading && state.cells.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.dorado),
      );
    }

    if (state.errorMessage != null && state.cells.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.dorado),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(cellsProvider.notifier).refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dorado,
                  foregroundColor: AppColors.deepTeal,
                ),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.cells.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 64, color: AppColors.crema),
            const SizedBox(height: 16),
            Text(
              'No se encontraron células',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.crema),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiando el día o el término de búsqueda',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.cells.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.cells.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.dorado),
            ),
          );
        }

        final cell = state.cells[index];
        return _CellCard(
          cell: cell,
          onTap: () => context.push('/cells/${cell.slug}'),
        );
      },
    );
  }
}

class _CellCard extends StatelessWidget {
  final CellGroupModel cell;
  final VoidCallback onTap;

  const _CellCard({required this.cell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      cell.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkTeal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cell.meetingDay,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.dorado,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (cell.leader != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.dorado),
                    const SizedBox(width: 6),
                    Text(
                      'Líder: ${cell.leader!.fullName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: AppColors.dorado,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cell.meetingTime,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.crema.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.dorado,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cell.address,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

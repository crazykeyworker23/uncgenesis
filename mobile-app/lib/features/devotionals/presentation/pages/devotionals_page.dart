import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/devotionals_provider.dart';
import '../../data/models/devotional_model.dart';

class DevotionalsPage extends ConsumerStatefulWidget {
  const DevotionalsPage({super.key});

  @override
  ConsumerState<DevotionalsPage> createState() => _DevotionalsPageState();
}

class _DevotionalsPageState extends ConsumerState<DevotionalsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSavedOnly = false;

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
    if (_showSavedOnly) return;
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll > 0 && currentScroll >= maxScroll - 50) {
      Future.microtask(() {
        if (mounted) {
          ref.read(devotionalsProvider.notifier).loadNextPage();
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(devotionalsProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devotionalsProvider);
    final savedSlugs = ref.watch(savedDevotionalsProvider);

    // Filter devotionals based on selection
    final List<DevotionalModel> displayedDevotionals = _showSavedOnly
        ? state.devotionals.where((d) => savedSlugs.contains(d.slug)).toList()
        : state.devotionals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devocionales'),
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
                hintText: 'Buscar devocionales...',
                prefixIcon: const Icon(Icons.search, color: AppColors.dorado),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.crema),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(devotionalsProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. View Toggle Segment (Todos / Guardados)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.menu_book),
                        label: Text('Todos'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.star),
                        label: Text('Guardados'),
                      ),
                    ],
                    selected: {_showSavedOnly},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _showSavedOnly = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.dorado,
                      selectedForegroundColor: AppColors.deepTeal,
                      foregroundColor: AppColors.crema,
                      backgroundColor: AppColors.cardColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Devotionals List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(devotionalsProvider.notifier).setSearchQuery(_searchController.text);
              },
              child: displayedDevotionals.isEmpty && !state.isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          _showSavedOnly
                              ? 'Aún no has guardado devocionales.'
                              : 'No se encontraron devocionales.',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: displayedDevotionals.length + (state.isLoading && !_showSavedOnly ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayedDevotionals.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: AppColors.dorado),
                            ),
                          );
                        }

                        final devotional = displayedDevotionals[index];
                        final isSaved = savedSlugs.contains(devotional.slug);

                        return _DevotionalCard(
                          devotional: devotional,
                          isSaved: isSaved,
                          onToggleSave: () {
                            ref.read(savedDevotionalsProvider.notifier).toggleFavorite(devotional.slug);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevotionalCard extends StatelessWidget {
  final DevotionalModel devotional;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _DevotionalCard({
    required this.devotional,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/devotionals/${devotional.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      devotional.date,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      devotional.title,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      devotional.biblePassage,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.doradoClaro,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.star : Icons.star_border,
                  color: isSaved ? AppColors.dorado : AppColors.crema.withValues(alpha: 0.4),
                ),
                onPressed: onToggleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

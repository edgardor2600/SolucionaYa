import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/worker_profile_model.dart' show ServiceCategory;
import '../../domain/explore_filter_model.dart';
import '../../providers/explore_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/worker_list_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialCategory});
  
  final ServiceCategory? initialCategory;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Configurar categoría inicial si se pasó
    if (widget.initialCategory != null) {
      Future.microtask(() {
        ref.read(exploreFilterProvider.notifier).state =
            ExploreFilterModel(category: widget.initialCategory!.name);
        ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
      });
    }

    _searchController.text = ref.read(exploreFilterProvider).searchQuery ?? '';
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(exploreNotifierProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final currentFilter = ref.read(exploreFilterProvider);
      ref.read(exploreFilterProvider.notifier).state = currentFilter.copyWith(searchQuery: query);
      ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
    });
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exploreState = ref.watch(exploreNotifierProvider);
    final currentFilter = ref.watch(exploreFilterProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Search Bar & Filter Icon
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'search_bar',
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Busca un experto o categoría...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openFilters,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: currentFilter.hasActiveFilters ? theme.colorScheme.primary : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentFilter.hasActiveFilters ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: currentFilter.hasActiveFilters ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                          if (currentFilter.hasActiveFilters)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters Chips
            if (currentFilter.hasActiveFilters)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (currentFilter.category != null)
                      _buildChip(
                        theme,
                        label: currentFilter.category!,
                        onDeleted: () {
                          ref.read(exploreFilterProvider.notifier).state = currentFilter.copyWith(clearCategory: true);
                          ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
                        },
                      ),
                    if (currentFilter.availableNowOnly)
                      _buildChip(
                        theme,
                        label: 'Disponibles Ahora',
                        onDeleted: () {
                          ref.read(exploreFilterProvider.notifier).state = currentFilter.copyWith(availableNowOnly: false);
                          ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
                        },
                      ),
                    if (currentFilter.verifiedOnly)
                      _buildChip(
                        theme,
                        label: 'Verificados',
                        onDeleted: () {
                          ref.read(exploreFilterProvider.notifier).state = currentFilter.copyWith(verifiedOnly: false);
                          ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
                        },
                      ),
                    if (currentFilter.maxDistanceKm != null)
                      _buildChip(
                        theme,
                        label: '< ${currentFilter.maxDistanceKm!.round()} km',
                        onDeleted: () {
                          ref.read(exploreFilterProvider.notifier).state = currentFilter.copyWith(clearMaxDistanceKm: true);
                          ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
                        },
                      ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),

            // Worker List
            Expanded(
              child: exploreState.workers.isEmpty && exploreState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : exploreState.workers.isEmpty && !exploreState.isLoading
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: exploreState.workers.length + (exploreState.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == exploreState.workers.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return WorkerListCard(worker: exploreState.workers[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, {required String label, required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8),
      child: RawChip(
        label: Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        deleteIcon: Icon(Icons.close_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text(
            'No encontramos expertos',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o tu búsqueda.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

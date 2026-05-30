import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/worker_profile_model.dart';
import '../../domain/explore_filter_model.dart';
import '../../providers/explore_provider.dart';
import 'dart:math' as math;

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late ExploreFilterModel _currentFilter;

  @override
  void initState() {
    super.initState();
    // Clona el estado actual al abrir el bottom sheet
    _currentFilter = ref.read(exploreFilterProvider);
  }

  void _applyFilters() {
    ref.read(exploreFilterProvider.notifier).state = _currentFilter;
    // Forzamos recarga desde cero con los nuevos filtros
    ref.read(exploreNotifierProvider.notifier).loadMore(refresh: true);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = const ExploreFilterModel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      top: 24,
      left: 24,
      right: 24,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: insets,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtros Avanzados',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text('Limpiar todo', style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Categoría Dropdown
            Text('Categoría', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _currentFilter.category,
                  hint: const Text('Cualquier categoría'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Cualquier categoría'),
                    ),
                    ...ServiceCategory.values.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.name,
                        child: Text(cat.label),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    setState(() => _currentFilter = _currentFilter.copyWith(category: val, clearCategory: val == null));
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Toggles
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Disponible Ahora', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Trabajadores listos para ir de inmediato'),
              value: _currentFilter.availableNowOnly,
              onChanged: (val) {
                setState(() => _currentFilter = _currentFilter.copyWith(availableNowOnly: val));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Perfil Verificado', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              value: _currentFilter.verifiedOnly,
              onChanged: (val) {
                setState(() => _currentFilter = _currentFilter.copyWith(verifiedOnly: val));
              },
            ),
            const SizedBox(height: 16),

            // Distancia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distancia Máxima', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  _currentFilter.maxDistanceKm != null ? '${_currentFilter.maxDistanceKm!.round()} km' : 'Cualquiera',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
            Slider(
              value: _currentFilter.maxDistanceKm ?? 20,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (val) {
                setState(() => _currentFilter = _currentFilter.copyWith(maxDistanceKm: val));
              },
              onChangeEnd: (val) {
                if (val >= 20) {
                  setState(() => _currentFilter = _currentFilter.copyWith(clearMaxDistanceKm: true));
                }
              },
            ),
            const SizedBox(height: 16),

            // Rating
            Text('Calificación mínima', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final isSelected = _currentFilter.minRating > index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentFilter = _currentFilter.copyWith(minRating: index + 1.0));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? AppColors.warning : theme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Aplicar Filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

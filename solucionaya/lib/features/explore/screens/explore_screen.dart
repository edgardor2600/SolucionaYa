import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_profile_model.dart';
import '../../worker_profile/screens/worker_profile_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  ServiceCategory? _selectedCategory;
  String _sortBy = 'rating'; // 'rating' | 'price' | 'distance'
  bool _verifiedOnly = false;
  bool _availableNow = true;

  static const _mockResults = [
    (name: 'Carlos Medina', trade: 'Plomería', rating: 4.9, price: 50000, verified: true, available: true, color: AppColors.plomeria, jobs: 138),
    (name: 'Luis Roa', trade: 'Electricidad', rating: 4.8, price: 60000, verified: true, available: true, color: AppColors.electricidad, jobs: 94),
    (name: 'Marta Villa', trade: 'Pintura', rating: 4.7, price: 45000, verified: false, available: true, color: AppColors.pintura, jobs: 72),
    (name: 'Ana Gómez', trade: 'Aseo', rating: 5.0, price: 35000, verified: true, available: false, color: AppColors.aseo, jobs: 211),
    (name: 'Pedro Ruiz', trade: 'Cerrajería', rating: 4.6, price: 55000, verified: true, available: true, color: AppColors.cerrajeria, jobs: 56),
    (name: 'Diego Pérez', trade: 'Computadores', rating: 4.5, price: 70000, verified: false, available: false, color: AppColors.computadores, jobs: 33),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filtrar resultados
    final results = _mockResults.where((w) {
      if (_verifiedOnly && !w.verified) return false;
      if (_availableNow && !w.available) return false;
      if (_selectedCategory != null &&
          w.trade != _selectedCategory!.label) return false;
      return true;
    }).toList();

    // Ordenar
    results.sort((a, b) {
      if (_sortBy == 'rating') return b.rating.compareTo(a.rating);
      if (_sortBy == 'price') return a.price.compareTo(b.price);
      return 0;
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar con búsqueda
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: _SearchField(onChanged: (_) {}),
          ),

          // Filtros rápidos
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCategoryChips(context),
                _buildFilterBar(context),
                const Divider(height: 1),
              ],
            ),
          ),

          // Header de resultados
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${results.length} resultado${results.length != 1 ? 's' : ''}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            size: 18,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de trabajadores
          results.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final w = results[i];
                        return _WorkerListCard(
                          name: w.name,
                          trade: w.trade,
                          rating: w.rating,
                          price: w.price,
                          verified: w.verified,
                          available: w.available,
                          accentColor: w.color,
                          jobs: w.jobs,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WorkerProfileDetailScreen(
                                workerId: 'mock-id',
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: results.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String get _sortLabel {
    if (_sortBy == 'rating') return 'Mejor calificados';
    if (_sortBy == 'price') return 'Menor precio';
    return 'Más cercanos';
  }

  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Todos"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todos'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
              selectedColor:
                  theme.colorScheme.primary.withAlpha(30),
              checkmarkColor: theme.colorScheme.primary,
            ),
          ),
          ...ServiceCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar:
                      Icon(cat.icon, size: 14, color: cat.color),
                  label: Text(cat.label),
                  selected: _selectedCategory == cat,
                  onSelected: (_) => setState(() {
                    _selectedCategory =
                        _selectedCategory == cat ? null : cat;
                  }),
                  selectedColor: cat.color.withAlpha(30),
                  checkmarkColor: cat.color,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterToggle(
            label: 'Disponible ahora',
            value: _availableNow,
            onChanged: (v) => setState(() => _availableNow = v),
            color: const Color(0xFF00C853),
          ),
          const SizedBox(width: 10),
          _FilterToggle(
            label: 'Solo verificados',
            value: _verifiedOnly,
            onChanged: (v) => setState(() => _verifiedOnly = v),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ordenar por',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _SortOption(
                label: 'Mejor calificados',
                icon: Icons.star_rounded,
                selected: _sortBy == 'rating',
                onTap: () {
                  setState(() => _sortBy = 'rating');
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                label: 'Menor precio',
                icon: Icons.attach_money_rounded,
                selected: _sortBy == 'price',
                onTap: () {
                  setState(() => _sortBy = 'price');
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                label: 'Más cercanos',
                icon: Icons.location_on_rounded,
                selected: _sortBy == 'distance',
                onTap: () {
                  setState(() => _sortBy = 'distance');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─── Components ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      autofocus: false,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar electricista, plomero...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: const Icon(Icons.mic_outlined),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withAlpha(20) : theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? color.withAlpha(100) : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value) ...[
              Icon(Icons.check_rounded, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: value ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerListCard extends StatelessWidget {
  const _WorkerListCard({
    required this.name,
    required this.trade,
    required this.rating,
    required this.price,
    required this.verified,
    required this.available,
    required this.accentColor,
    required this.jobs,
    required this.onTap,
  });

  final String name;
  final String trade;
  final double rating;
  final int price;
  final bool verified;
  final bool available;
  final Color accentColor;
  final int jobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded,
                      color: accentColor, size: 34),
                ),
                if (available)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(trade,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: accentColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: const Color(0xFFFFB300)),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(' · $jobs trabajos',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(price / 1000).toStringAsFixed(0)}k',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text('/hora',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant),
      title: Text(label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? theme.colorScheme.primary : null,
          )),
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
          const SizedBox(height: 16),
          Text('Sin resultados',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Prueba cambiando los filtros\no buscando otra categoría.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

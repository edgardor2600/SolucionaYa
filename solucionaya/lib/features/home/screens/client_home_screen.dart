import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_profile_model.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  // Mock de trabajadores para la UI inicial
  static const _mockWorkers = [
    (name: 'Carlos Medina', trade: 'Plomería', rating: '4.9', price: '\$50k/h', color: AppColors.plomeria),
    (name: 'Ana Gómez', trade: 'Aseo', rating: '5.0', price: '\$35k/h', color: AppColors.aseo),
    (name: 'Luis Roa', trade: 'Electricidad', rating: '4.8', price: '\$60k/h', color: AppColors.electricidad),
    (name: 'Marta Villa', trade: 'Pintura', rating: '4.7', price: '\$45k/h', color: AppColors.pintura),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchBar(context),
                const SizedBox(height: 24),
                _buildBannerCard(context),
                const SizedBox(height: 28),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildSectionTitle(context, 'Categorías', onTap: () {}),
                const SizedBox(height: 16),
                _buildCategoriesGrid(context),
                const SizedBox(height: 28),
                _buildSectionTitle(context, 'Destacados cerca de ti', onTap: () {}),
                const SizedBox(height: 16),
                _buildFeaturedWorkers(context),
                const SizedBox(height: 28),
                _buildHowItWorks(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      toolbarHeight: 68,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu ubicación',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 3),
              Text(
                'Bucaramanga',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            label: const Text('3'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person_outline_rounded,
                color: theme.colorScheme.primary, size: 20),
          ),
        ),
      ],
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Qué necesitas hoy?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner Card ────────────────────────────────────────────────────────────

  Widget _buildBannerCard(BuildContext context) {
    return Container(
      // Altura 152px: 20px padding top/bottom cada lado → 112px disponibles para el contenido
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF003D99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¡Primera visita gratis!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra tu cuenta y consigue\ntu primera inspección gratuita.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(200),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Reclamar oferta',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title,
      {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Ver todo',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  // ─── Categories Grid ────────────────────────────────────────────────────────

  Widget _buildCategoriesGrid(BuildContext context) {
    final cats = ServiceCategory.values.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final cat = cats[i];
        return GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: cat.color.withAlpha(22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(cat.icon, color: cat.color, size: 26),
              ),
              const SizedBox(height: 7),
              Text(
                cat.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Featured Workers Carousel ───────────────────────────────────────────────

  Widget _buildFeaturedWorkers(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mockWorkers.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, i) {
          final w = _mockWorkers[i];
          return _WorkerCard(
            name: w.name,
            trade: w.trade,
            rating: w.rating,
            price: w.price,
            accentColor: w.color,
          );
        },
      ),
    );
  }

  // ─── Quick Actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    const actions = [
      (icon: Icons.emergency_rounded, label: 'Urgente', color: Color(0xFFD32F2F)),
      (icon: Icons.star_rounded, label: 'Top Rated', color: Color(0xFFFFB300)),
      (icon: Icons.verified_rounded, label: 'Verificados', color: AppColors.primary),
      (icon: Icons.near_me_rounded, label: 'Cerca', color: AppColors.aseo),
    ];
    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: a.color.withAlpha(18),
                    shape: BoxShape.circle,
                    border: Border.all(color: a.color.withAlpha(50)),
                  ),
                  child: Icon(a.icon, color: a.color, size: 24),
                ),
                const SizedBox(height: 7),
                Text(
                  a.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── How It Works ────────────────────────────────────────────────────────────

  Widget _buildHowItWorks(BuildContext context) {
    final theme = Theme.of(context);
    const steps = [
      (number: '1', title: 'Busca', desc: 'Elige la categoría que necesitas', icon: Icons.search_rounded),
      (number: '2', title: 'Compara', desc: 'Revisa perfiles, precios y reseñas', icon: Icons.compare_rounded),
      (number: '3', title: 'Contacta', desc: 'Habla directamente con el experto', icon: Icons.chat_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo funciona?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: steps.map((s) {
              final isLast = s == steps.last;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            s.number,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 2),
                            Text(s.desc,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                      Icon(s.icon,
                          color: theme.colorScheme.primary.withAlpha(120),
                          size: 22),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 19),
                      child: Container(
                        width: 2,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}


// ─── Worker Card Component ──────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.name,
    required this.trade,
    required this.rating,
    required this.price,
    required this.accentColor,
  });

  final String name;
  final String trade;
  final String rating;
  final String price;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        // TODO: Navegar a worker profile detail
      },
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar area
            Container(
              height: 108,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withAlpha(30), accentColor.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withAlpha(40),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 36, color: accentColor),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB300), size: 11),
                          const SizedBox(width: 3),
                          Text(rating,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  // Verified badge
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text('Verificado',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    trade,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      Text(
                        price,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
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

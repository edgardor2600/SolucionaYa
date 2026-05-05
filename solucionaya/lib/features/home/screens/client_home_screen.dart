import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/worker_profile_model.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';

String _formatCOP(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final nearbyAsync = ref.watch(nearbyWorkersProvider);
    final availableAsync = ref.watch(availableWorkersProvider);
    final theme = Theme.of(context);

    final displayName = userProfile?.displayName ?? 'Usuario';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref, firstName),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchBar(context),
                const SizedBox(height: 24),
                if (userProfile?.photoUrl == null) ...[
                  _buildBannerCard(context),
                  const SizedBox(height: 28),
                ],
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildSectionTitle(context, 'Categorías', onTap: () {
                  // TODO: Ir a Explore
                }),
                const SizedBox(height: 16),
                _buildCategoriesGrid(context),
                const SizedBox(height: 28),

                // Disponibles Ahora
                _buildSectionTitle(context, 'Disponibles ahora', onTap: () {}),
                const SizedBox(height: 16),
                _buildWorkersCarousel(
                  context,
                  availableAsync,
                  emptyMessage: 'Nadie tiene el modo "Disponible ahora" encendido.',
                ),

                const SizedBox(height: 28),

                // Más cercanos
                _buildSectionTitle(context, 'Más cercanos a ti', onTap: () {}),
                const SizedBox(height: 16),
                _buildWorkersCarousel(
                  context,
                  nearbyAsync,
                  clientLat: userProfile?.latitude,
                  clientLng: userProfile?.longitude,
                  emptyMessage: 'No hay trabajadores con ubicación detectada cerca de ti.',
                ),

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

  Widget _buildAppBar(BuildContext context, WidgetRef ref, String firstName) {
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
            '${_getGreeting()}, $firstName',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 3),
              Text(
                'Bucaramanga',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Badge(
            label: Text('3'),
            child: Icon(Icons.notifications_none_rounded),
          ),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.loginEmail);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Mi Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary, size: 20),
            ),
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
              Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant, size: 22),
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
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner Card ────────────────────────────────────────────────────────────

  Widget _buildBannerCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NUEVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Completa tu perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sube una foto para que los expertos te reconozcan mejor.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Subir foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.add_a_photo_rounded, size: 70, color: Colors.white.withAlpha(50)),
        ],
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

  // ─── Categorías Grid ────────────────────────────────────────────────────────

  Widget _buildCategoriesGrid(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ServiceCategory.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return GestureDetector(
          onTap: () {},
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cat.color.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 28),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Workers Carousel ───────────────────────────────────────────────────────

  Widget _buildWorkersCarousel(
    BuildContext context,
    AsyncValue<List<WorkerProfileModel>> asyncWorkers, {
    double? clientLat,
    double? clientLng,
    String emptyMessage = 'No hay trabajadores en este momento.',
  }) {
    final theme = Theme.of(context);
    return asyncWorkers.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Error: $e')),
      ),
      data: (workers) {
        if (workers.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: workers.length,
            itemBuilder: (context, i) {
              return _WorkerCard(
                worker: workers[i],
                clientLat: clientLat,
                clientLng: clientLng,
              );
            },
          ),
        );
      },
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
                      Icon(s.icon, color: theme.colorScheme.primary.withAlpha(120), size: 22),
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

  // ─── Título de sección con botón "Ver todos" ────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Ver todos',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Worker Card Component ──────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    this.clientLat,
    this.clientLng,
  });

  final WorkerProfileModel worker;
  final double? clientLat;
  final double? clientLng;

  String? _getDistanceText() {
    if (clientLat != null && clientLng != null && worker.latitude != null && worker.longitude != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        clientLat!, clientLng!, worker.latitude!, worker.longitude!
      );
      final distanceInKm = distanceInMeters / 1000;
      if (distanceInKm < 1) {
        return 'A ${distanceInMeters.toStringAsFixed(0)} m';
      }
      return 'A ${distanceInKm.toStringAsFixed(1)} km';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = worker.category.color;

    return GestureDetector(
      onTap: () {
        context.push('/worker/${worker.uid}');
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
                  colors: [accentColor.withAlpha(30), accentColor.withAlpha(10)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: worker.photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: worker.photoUrl!,
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                              )
                            : Center(
                                child: Text(
                                  worker.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (worker.isAvailableNow)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text('AHORA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    worker.category.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_getDistanceText() != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          _getDistanceText()!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        worker.rating > 0 ? worker.rating.toStringAsFixed(1) : 'Nuevo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (worker.startingPrice != null)
                        Text(
                          _formatCOP(worker.startingPrice!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
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

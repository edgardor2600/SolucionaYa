import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/service_models.dart';
import '../../../data/models/worker_profile_model.dart';

String _formatCOP(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

// ─── Pantalla Principal ───────────────────────────────────────────────────────

class WorkerProfileDetailScreen extends ConsumerStatefulWidget {
  const WorkerProfileDetailScreen({super.key, required this.workerId});

  final String workerId;

  @override
  ConsumerState<WorkerProfileDetailScreen> createState() =>
      _WorkerProfileDetailScreenState();
}

class _WorkerProfileDetailScreenState
    extends ConsumerState<WorkerProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(workerPublicProfileProvider(widget.workerId));

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('No se pudo cargar el perfil:\n$e', textAlign: TextAlign.center)),
      ),
      data: (data) {
        final profile = data.profile;
        final prices = data.prices;
        final gallery = data.gallery;
        final schedule = data.schedule;

        final primaryColor = profile.category.color;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildHeroAppBar(context, profile, primaryColor),
              _buildProfileHeader(context, profile, primaryColor),
              _buildTabBar(context, primaryColor),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _AboutTab(
                  profile: profile,
                  prices: prices,
                  schedule: schedule,
                  primaryColor: primaryColor,
                ),
                _GalleryTab(
                  gallery: gallery,
                  primaryColor: primaryColor,
                ),
                _ReviewsTab(
                  primaryColor: primaryColor,
                  profile: profile,
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildContactBar(context, profile, prices, primaryColor),
        );
      },
    );
  }

  // ─── Hero App Bar ──────────────────────────────────────────────────────────

  Widget _buildHeroAppBar(BuildContext context, WorkerProfileModel profile, Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            child: IconButton(
              icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo con foto borrosa o color
            if (profile.photoUrl != null)
              CachedNetworkImage(
                imageUrl: profile.photoUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.darken,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Foto circular en el centro
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profile.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profile.photoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            profile.displayName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profile Header Card ───────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context, WorkerProfileModel profile, Color primaryColor) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.displayName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.category.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Disponibilidad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: profile.isAvailableNow
                        ? AppColors.success.withValues(alpha: 0.1)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: profile.isAvailableNow
                          ? AppColors.success.withValues(alpha: 0.3)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: profile.isAvailableNow
                              ? AppColors.success
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        profile.isAvailableNow ? 'Disponible' : 'No disponible',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: profile.isAvailableNow
                              ? AppColors.success
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.warning,
                  value: profile.rating.toStringAsFixed(1),
                  label: '${profile.totalReviews} reseñas',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.work_outline_rounded,
                  iconColor: primaryColor,
                  value: '${profile.totalJobsDone}',
                  label: 'trabajos',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.schedule_rounded,
                  iconColor: primaryColor,
                  value: profile.yearsExperience.toString(),
                  label: 'años exp',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Galería'),
            Tab(text: 'Reseñas'),
          ],
        ),
        color: theme.colorScheme.surface,
      ),
    );
  }

  // ─── Contact Bottom Bar ───────────────────────────────────────────────────

  Widget _buildContactBar(BuildContext context, WorkerProfileModel profile, List<PriceModel> prices, Color primaryColor) {
    final theme = Theme.of(context);
    final hasPrices = prices.isNotEmpty;
    final lowestPrice = hasPrices
        ? prices.map((p) => p.priceMin).reduce((a, b) => a < b ? a : b)
        : profile.startingPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desde',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  lowestPrice != null ? _formatCOP(lowestPrice) : 'A convenir',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
              label: const Text('Contactar ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab: Información ─────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.profile,
    required this.prices,
    required this.schedule,
    required this.primaryColor,
  });

  final WorkerProfileModel profile;
  final List<PriceModel> prices;
  final ScheduleModel schedule;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bio = (profile.bio != null && profile.bio!.isNotEmpty)
        ? profile.bio!
        : 'Profesional en ${profile.category.label.toLowerCase()} con ${profile.yearsExperience} años de experiencia.';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Bio
        _SectionHeader(title: 'Sobre mí'),
        const SizedBox(height: 10),
        Text(
          bio,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 24),

        // Especialidades (Chips visuales basados en la categoría, para dar riqueza a la UI)
        _SectionHeader(title: 'Especialidad'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SkillChip(label: profile.category.label, color: primaryColor),
            if (profile.yearsExperience >= 5) _SkillChip(label: 'Experto', color: primaryColor),
            if (profile.isVerified) _SkillChip(label: 'Verificado', color: primaryColor),
          ],
        ),
        const SizedBox(height: 24),

        // Precios
        _SectionHeader(title: 'Precios de referencia'),
        const SizedBox(height: 10),
        if (prices.isEmpty)
          Text(
            'Este profesional aún no ha definido precios detallados.',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
          )
        else
          ...prices.map((p) => _PriceRow(price: p, primaryColor: primaryColor)),
        const SizedBox(height: 24),

        // Horario
        _SectionHeader(title: 'Horario de atención'),
        const SizedBox(height: 10),
        _ScheduleCard(schedule: schedule, primaryColor: primaryColor),
      ],
    );
  }
}

// ─── Tab: Galería ─────────────────────────────────────────────────────────────

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({
    required this.gallery,
    required this.primaryColor,
  });

  final List<GalleryPhotoModel> gallery;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Aún no hay fotos de trabajos',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: gallery.length,
        itemBuilder: (context, i) {
          final photo = gallery[i];
          final url = photo.thumbnailUrl ?? photo.url;

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: primaryColor.withValues(alpha: 0.1),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: primaryColor.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(Icons.broken_image_rounded, color: primaryColor.withValues(alpha: 0.5)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab: Reseñas (Simulado según el plan original) ──────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({
    required this.primaryColor,
    required this.profile,
  });

  final Color primaryColor;
  final WorkerProfileModel profile;

  static const _reviews = [
    (name: 'María López', rating: 5, comment: 'Excelente trabajo, muy puntual y limpio.', ago: 'hace 2 días'),
    (name: 'Pedro Sánchez', rating: 5, comment: 'Lo contraté para un arreglo y quedó perfecto. Recomendado.', ago: 'hace 1 semana'),
    (name: 'Claudia R.', rating: 4, comment: 'Buen trabajo aunque llegó un poco tarde. El resultado fue bueno.', ago: 'hace 2 semanas'),
  ];

  @override
  Widget build(BuildContext context) {
    if (profile.totalReviews == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded, size: 64, color: primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Aún no hay reseñas',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RatingSummaryCard(rating: profile.rating, total: profile.totalReviews, primaryColor: primaryColor),
        const SizedBox(height: 16),
        ..._reviews.map((r) => _ReviewCard(
              name: r.name,
              rating: r.rating,
              comment: r.comment,
              ago: r.ago,
              primaryColor: primaryColor,
            )),
      ],
    );
  }
}

// ─── Small Components ──────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price, required this.primaryColor});
  final PriceModel price;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = price.priceMax != null
        ? '${_formatCOP(price.priceMin)} - ${_formatCOP(price.priceMax!)}'
        : _formatCOP(price.priceMin);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.serviceName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${price.unit.label} ${price.notes != null ? '· ${price.notes}' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.primaryColor});
  final ScheduleModel schedule;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (schedule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Horario sujeto a coordinación directa.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int day = 1; day <= 7; day++) ...[
            Builder(builder: (context) {
              final isLast = day == 7;
              final slots = schedule.days[day] ?? [];
              final hasSlots = slots.isNotEmpty;
              final dayName = ScheduleModel.dayNames[day]!;
              
              String hoursText = 'No disponible';
              if (hasSlots) {
                hoursText = slots.map((s) => '${s.startLabel}–${s.endLabel}').join(', ');
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasSlots ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        hoursText,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasSlots ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: hasSlots ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]
        ],
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.rating,
    required this.total,
    required this.primaryColor,
  });

  final double rating;
  final int total;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    color: i < rating.round() ? AppColors.warning : theme.colorScheme.outline.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('$total reseñas', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                // Simulación visual de barras
                final fill = star == 5 ? 0.75 : star == 4 ? 0.15 : 0.05;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fill,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.comment,
    required this.ago,
    required this.primaryColor,
  });

  final String name;
  final int rating;
  final String comment;
  final String ago;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Text(
                  name[0].toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(ago, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (i) => const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

// ─── SliverDelegate para pinear el TabBar ─────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SliverTabBarDelegate(this.tabBar, {required this.color});
  final TabBar tabBar;
  final Color color;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: color, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => tabBar != old.tabBar;
}

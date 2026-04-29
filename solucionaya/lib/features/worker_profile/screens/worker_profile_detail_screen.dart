import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/service_models.dart';
import '../../../data/models/worker_profile_model.dart';

/// Pantalla completa del perfil público de un trabajador.
/// Inspirada en Airbnb / Thumbtack: foto hero, pestañas, info rica.
class WorkerProfileDetailScreen extends StatefulWidget {
  const WorkerProfileDetailScreen({
    super.key,
    required this.workerId,
    this.worker, // pasamos el mock para pruebas
  });

  final String workerId;
  final _MockWorker? worker;

  @override
  State<WorkerProfileDetailScreen> createState() =>
      _WorkerProfileDetailScreenState();
}

class _WorkerProfileDetailScreenState
    extends State<WorkerProfileDetailScreen>
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
    final w = widget.worker ?? _MockWorker.sample;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildHeroAppBar(context, w),
          _buildProfileHeader(context, w),
          _buildTabBar(context),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AboutTab(worker: w),
            _GalleryTab(accentColor: w.accentColor),
            _ReviewsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildContactBar(context, w),
    );
  }

  // ─── Hero App Bar ──────────────────────────────────────────────────────────

  Widget _buildHeroAppBar(BuildContext context, _MockWorker w) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: w.accentColor,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.favorite_border_rounded,
                  color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                w.accentColor,
                w.accentColor.withAlpha(160),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
                border: Border.all(color: Colors.white.withAlpha(80), width: 2),
              ),
              child: Icon(Icons.person_rounded, size: 50, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Profile Header Card ───────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context, _MockWorker w) {
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
                          Text(
                            w.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        w.trade,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: w.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Disponibilidad
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF00C853).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Disponible',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF00C853),
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
                  iconColor: const Color(0xFFFFB300),
                  value: w.rating,
                  label: '${w.reviews} reseñas',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.work_outline_rounded,
                  iconColor: AppColors.primary,
                  value: '${w.jobs}',
                  label: 'trabajos',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.primary,
                  value: '< 30min',
                  label: 'respuesta',
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

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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

  Widget _buildContactBar(BuildContext context, _MockWorker w) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  w.priceFrom,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
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
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Contactar ahora'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
  const _AboutTab({required this.worker});
  final _MockWorker worker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Bio
        _SectionHeader(title: 'Sobre mí'),
        const SizedBox(height: 10),
        Text(
          'Soy profesional con más de ${worker.years} años de experiencia en '
          '${worker.trade.toLowerCase()}. Me especializo en trabajos '
          'residenciales y comerciales. Trabajo de manera limpia, puntual y '
          'con garantía en todos mis servicios.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 24),

        // Precios
        _SectionHeader(title: 'Precios de referencia'),
        const SizedBox(height: 10),
        ...worker.prices.map((p) => _PriceRow(price: p)),
        const SizedBox(height: 24),

        // Habilidades
        _SectionHeader(title: 'Especialidades'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: worker.tags.map((t) => _SkillChip(label: t)).toList(),
        ),
        const SizedBox(height: 24),

        // Horario
        _SectionHeader(title: 'Horario de atención'),
        const SizedBox(height: 10),
        _ScheduleCard(),
      ],
    );
  }
}

// ─── Tab: Galería ─────────────────────────────────────────────────────────────

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: 9,
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withAlpha(40 + (i * 15)),
                    accentColor.withAlpha(20 + (i * 10)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(Icons.image_outlined,
                    color: accentColor.withAlpha(180), size: 32),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab: Reseñas ─────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  static const _reviews = [
    (name: 'María López', rating: 5, comment: 'Excelente trabajo, muy puntual y limpio.', ago: 'hace 2 días'),
    (name: 'Pedro Sánchez', rating: 5, comment: 'Lo contraté para arreglar una tubería y quedó perfecto. Recomendado.', ago: 'hace 1 semana'),
    (name: 'Claudia R.', rating: 4, comment: 'Buen trabajo aunque llegó un poco tarde. El resultado fue bueno.', ago: 'hace 2 semanas'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RatingSummaryCard(),
        const SizedBox(height: 16),
        ..._reviews.map((r) => _ReviewCard(
              name: r.name,
              rating: r.rating,
              comment: r.comment,
              ago: r.ago,
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
                  color: theme.colorScheme.onSurfaceVariant,
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
  const _PriceRow({required this.price});
  final ({String service, String amount}) price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(price.service, style: theme.textTheme.bodyMedium),
          ),
          Text(
            price.amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  static const _days = [
    (day: 'Lunes', hours: '7:00 AM – 6:00 PM', active: true),
    (day: 'Martes', hours: '7:00 AM – 6:00 PM', active: true),
    (day: 'Miércoles', hours: '7:00 AM – 6:00 PM', active: true),
    (day: 'Jueves', hours: '7:00 AM – 6:00 PM', active: true),
    (day: 'Viernes', hours: '7:00 AM – 4:00 PM', active: true),
    (day: 'Sábado', hours: '8:00 AM – 12:00 PM', active: true),
    (day: 'Domingo', hours: 'No disponible', active: false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _days.map((d) {
          final isLast = d == _days.last;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withAlpha(60))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.day,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: d.active
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  d.hours,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: d.active
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withAlpha(120),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text('4.9',
                  style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary)),
              Row(
                children: List.generate(
                    5,
                    (i) => const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB300), size: 14)),
              ),
              const SizedBox(height: 4),
              Text('47 reseñas', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
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
                            backgroundColor: theme.colorScheme.outlineVariant.withAlpha(80),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFB300)),
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
  });

  final String name;
  final int rating;
  final String comment;
  final String ago;

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
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  name[0],
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(ago,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    rating,
                    (i) => const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB300), size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment,
              style:
                  theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
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
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: color, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => tabBar != old.tabBar;
}

// ─── Mock data ────────────────────────────────────────────────────────────────

class _MockWorker {
  const _MockWorker({
    required this.name,
    required this.trade,
    required this.rating,
    required this.reviews,
    required this.jobs,
    required this.years,
    required this.priceFrom,
    required this.accentColor,
    required this.prices,
    required this.tags,
  });

  final String name;
  final String trade;
  final String rating;
  final int reviews;
  final int jobs;
  final int years;
  final String priceFrom;
  final Color accentColor;
  final List<({String service, String amount})> prices;
  final List<String> tags;

  static const sample = _MockWorker(
    name: 'Carlos Medina',
    trade: 'Plomería',
    rating: '4.9',
    reviews: 47,
    jobs: 138,
    years: 8,
    priceFrom: '\$50,000/h',
    accentColor: AppColors.plomeria,
    prices: [
      (service: 'Inspección básica', amount: '\$50.000'),
      (service: 'Cambio de tubería', amount: '\$80.000 – 120.000'),
      (service: 'Destape de cañería', amount: '\$60.000'),
      (service: 'Instalación de grifo', amount: '\$45.000'),
    ],
    tags: [
      'Plomería general',
      'Destapes',
      'Grifería',
      'Calentadores',
      'Acueducto',
      'Alcantarillado',
    ],
  );
}

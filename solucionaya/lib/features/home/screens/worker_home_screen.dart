import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/profile_completeness.dart';
import '../../../data/models/worker_profile_model.dart';

// ─── Provider local para persistir si ya se mostró el banner ─────────────────
final _bannerDismissedProvider = StateProvider<bool>((ref) => false);

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  Timer? _autoOffTimer;

  @override
  void dispose() {
    _autoOffTimer?.cancel();
    super.dispose();
  }

  /// Activa o desactiva la disponibilidad. Si se activa, programa auto-apagado a las 8h.
  Future<void> _toggleAvailability(
    WorkerProfileModel profile,
    bool newValue,
  ) async {
    final repo = ref.read(workerRepositoryProvider);
    try {
      await repo.toggleAvailability(profile.uid, newValue);

      // Auto-apagado a las 8 horas si se activa disponibilidad.
      if (newValue) {
        _autoOffTimer?.cancel();
        _autoOffTimer = Timer(const Duration(hours: 8), () async {
          if (mounted) {
            await repo.toggleAvailability(profile.uid, false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tu disponibilidad se apagó automáticamente después de 8 horas.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        });
      } else {
        _autoOffTimer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar disponibilidad: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userProfile = ref.watch(currentUserProfileProvider).value;
    final workerAsync = ref.watch(currentWorkerProfileProvider);

    return workerAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (worker) {
        if (worker == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty_rounded, size: 64),
                  const SizedBox(height: 16),
                  const Text('Perfil no encontrado.'),
                  TextButton(
                    onPressed: () => ref.read(authProvider).signOut(),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }

        return _WorkerDashboard(
          worker: worker,
          displayName: userProfile?.displayName ?? worker.displayName,
          onToggle: _toggleAvailability,
        );
      },
    );
  }
}

// ─── Dashboard Principal ──────────────────────────────────────────────────────
class _WorkerDashboard extends ConsumerWidget {
  const _WorkerDashboard({
    required this.worker,
    required this.displayName,
    required this.onToggle,
  });

  final WorkerProfileModel worker;
  final String displayName;
  final Future<void> Function(WorkerProfileModel, bool) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bannerDismissed = ref.watch(_bannerDismissedProvider);

    final pricesAsync = ref.watch(workerPricesProvider(worker.uid));
    final galleryAsync = ref.watch(workerGalleryProvider(worker.uid));

    final prices = pricesAsync.value ?? [];
    final gallery = galleryAsync.value ?? [];

    final completeness = ProfileCompleteness.calculate(
      profile: worker,
      prices: prices,
      gallery: gallery,
    );

    // ¿Se acaba de aprobar (primera vez como aprobado)?
    final showApprovalBanner = worker.isApproved && !bannerDismissed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar con gradiente ──
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.blurBackground,
                StretchMode.zoomBackground,
              ],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: worker.photoUrl != null
                              ? NetworkImage(worker.photoUrl!)
                              : null,
                          child: worker.photoUrl == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¡Hola, ${displayName.split(' ').first}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    worker.category.icon,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    worker.category.label,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Logout
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                          onPressed: () => ref.read(authProvider).signOut(),
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Banner de Aprobación ──
                if (showApprovalBanner) ...[
                  _ApprovalBanner(
                    onDismiss: () =>
                        ref.read(_bannerDismissedProvider.notifier).state = true,
                  ).animate().slideY(begin: -0.3).fade(),
                  const SizedBox(height: 20),
                ],

                // ── Toggle de Disponibilidad ──
                _AvailabilityToggle(
                  worker: worker,
                  onToggle: onToggle,
                ).animate().slideY(begin: 0.2, duration: 500.ms).fade(),

                const SizedBox(height: 24),

                // ── Completitud del Perfil ──
                _CompletenessCard(completeness: completeness)
                    .animate()
                    .slideY(begin: 0.2, duration: 500.ms, delay: 100.ms)
                    .fade(),

                const SizedBox(height: 24),

                // ── Estadísticas Rápidas ──
                _StatsRow(worker: worker)
                    .animate()
                    .slideY(begin: 0.2, duration: 500.ms, delay: 200.ms)
                    .fade(),

                const SizedBox(height: 24),

                // ── Acciones Rápidas ──
                _QuickActions(workerUid: worker.uid)
                    .animate()
                    .slideY(begin: 0.2, duration: 500.ms, delay: 300.ms)
                    .fade(),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Banner de Aprobación ─────────────────────────────────────────────────────
class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, Color(0xFF00E676)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Tu perfil fue aprobado! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ya puedes recibir solicitudes de clientes. Activa tu disponibilidad.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ─── Toggle de Disponibilidad ─────────────────────────────────────────────────
class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({required this.worker, required this.onToggle});
  final WorkerProfileModel worker;
  final Future<void> Function(WorkerProfileModel, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final isAvailable = worker.isAvailableNow;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onToggle(worker, !isAvailable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: isAvailable
              ? const LinearGradient(
                  colors: [AppColors.secondary, AppColors.secondaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAvailable
              ? null
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isAvailable
                    ? Icons.wifi_tethering_rounded
                    : Icons.wifi_tethering_off_rounded,
                color: isAvailable
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvailable ? 'DISPONIBLE AHORA' : 'NO DISPONIBLE',
                    style: TextStyle(
                      color: isAvailable
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAvailable
                        ? 'Los clientes pueden contactarte • Auto-apaga en 8h'
                        : 'Toca para activar y recibir solicitudes',
                    style: TextStyle(
                      color: isAvailable
                          ? Colors.white70
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isAvailable,
              onChanged: (v) => onToggle(worker, v),
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta de Completitud ───────────────────────────────────────────────────
class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.completeness});
  final CompletenessResult completeness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final score = completeness.score;
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                'Completitud del perfil',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),

          if (completeness.missingItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Para completar tu perfil:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...completeness.missingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text(
                  '¡Perfil 100% completo!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Fila de Estadísticas Rápidas ────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.worker});
  final WorkerProfileModel worker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.warning,
            value: worker.rating > 0
                ? worker.rating.toStringAsFixed(1)
                : '–',
            label: 'Calificación',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.handyman_rounded,
            iconColor: AppColors.primary,
            value: worker.totalJobsDone.toString(),
            label: 'Trabajos',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.visibility_rounded,
            iconColor: AppColors.secondary,
            value: worker.profileViews.toString(),
            label: 'Visitas',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Acciones Rápidas ─────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.workerUid});
  final String workerUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      _Action(
        icon: Icons.edit_rounded,
        label: 'Editar perfil',
        color: AppColors.primary,
        route: AppRoutes.workerEditProfile,
      ),
      _Action(
        icon: Icons.attach_money_rounded,
        label: 'Mis precios',
        color: AppColors.success,
        route: AppRoutes.workerPrices,
      ),
      _Action(
        icon: Icons.photo_library_rounded,
        label: 'Mi galería',
        color: AppColors.secondary,
        route: AppRoutes.workerGallery,
      ),
      _Action(
        icon: Icons.calendar_month_rounded,
        label: 'Mi horario',
        color: AppColors.warning,
        route: AppRoutes.workerSchedule,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: actions
              .map(
                (a) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: a != actions.last ? 10 : 0,
                    ),
                    child: InkWell(
                      onTap: () => context.push(a.route),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: a.color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(a.icon, color: a.color, size: 26),
                            const SizedBox(height: 8),
                            Text(
                              a.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: a.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        // Botón de vista previa de perfil
        InkWell(
          onTap: () => context.push('/worker/$workerUid'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_red_eye_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ver mi perfil público',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Mira cómo te ven los clientes en la app',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Action {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
}


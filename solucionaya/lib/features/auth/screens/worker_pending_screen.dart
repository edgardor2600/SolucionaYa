import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';

/// Pantalla de espera mientras el Admin revisa los documentos del trabajador.
/// Escucha en tiempo real el campo [isApproved] y el router redirige
/// automáticamente al workerHome cuando sea true.
class WorkerPendingScreen extends ConsumerWidget {
  const WorkerPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // El stream ya está activo en currentWorkerProfileProvider.
    // El Router reacciona al cambio de isApproved → redirige al Home.
    final workerAsync = ref.watch(currentWorkerProfileProvider);
    final displayName = ref.watch(currentUserProfileProvider).value?.displayName ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logout ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => ref.read(authProvider).signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Salir'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),

              const Spacer(),

              // ── Ilustración animada ──
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.07),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          duration: 2.seconds,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.1, 1.1),
                          end: const Offset(0.9, 0.9),
                          duration: 2.seconds,
                          curve: Curves.easeInOut,
                        ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .rotate(
                          begin: -0.05,
                          end: 0.05,
                          duration: 1.5.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Textos ──
              Text(
                '¡Ya casi, ${displayName.split(' ').first}!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate().slideY(begin: 0.2, duration: 500.ms).fade(),

              const SizedBox(height: 12),

              Text(
                'Estamos revisando tu información y documentos de identidad. Este proceso toma máximo 24 horas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ).animate().slideY(begin: 0.2, duration: 500.ms, delay: 100.ms).fade(),

              const SizedBox(height: 32),

              // ── Steps de revisión ──
              _ReviewStep(
                icon: Icons.upload_file_rounded,
                title: 'Documentos recibidos',
                subtitle: 'Tu cédula fue recibida exitosamente.',
                status: _StepStatus.done,
                delay: 200,
              ),
              const SizedBox(height: 14),
              _ReviewStep(
                icon: Icons.manage_search_rounded,
                title: 'En revisión por el equipo',
                subtitle: 'Verificando autenticidad e identidad.',
                status: _StepStatus.inProgress,
                delay: 300,
              ),
              const SizedBox(height: 14),
              _ReviewStep(
                icon: Icons.verified_rounded,
                title: 'Perfil aprobado',
                subtitle: 'Recibirás una notificación y accederás al app.',
                status: _StepStatus.pending,
                delay: 400,
              ),

              const Spacer(),

              // ── Estado del stream ──
              workerAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (worker) {
                  if (worker == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Esperando aprobación...',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step de revisión ─────────────────────────────────────────────────────────
enum _StepStatus { done, inProgress, pending }

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _StepStatus status;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = switch (status) {
      _StepStatus.done => AppColors.success,
      _StepStatus.inProgress => AppColors.primary,
      _StepStatus.pending => theme.colorScheme.onSurface.withValues(alpha: 0.3),
    };

    final leadingIcon = switch (status) {
      _StepStatus.done => Icons.check_circle_rounded,
      _StepStatus.inProgress => Icons.radio_button_checked_rounded,
      _StepStatus.pending => Icons.radio_button_unchecked_rounded,
    };

    return Row(
      children: [
        // Ícono del step
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: status == _StepStatus.pending
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : null,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Icon(leadingIcon, color: color, size: 20),
      ],
    ).animate().slideX(begin: 0.2, duration: 500.ms, delay: Duration(milliseconds: delay)).fade();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// Proveedor temporal para guardar el rol seleccionado antes de completar el registro
final intendedRoleProvider = StateProvider<UserRole?>((ref) => null);

class SelectRoleScreen extends ConsumerWidget {
  const SelectRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Cómo quieres usar la app?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ).animate().slideY(begin: 0.3, duration: 500.ms).fade(),
              
              const SizedBox(height: 8),
              
              Text(
                'Selecciona la opción que mejor se adapte a lo que buscas hoy.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 100.ms).fade(),

              const SizedBox(height: 48),

              // ── Opción Cliente ──
              _RoleCard(
                title: 'Quiero contratar',
                description: 'Busco expertos para solucionar problemas en mi hogar u oficina.',
                icon: Icons.person_search_rounded,
                color: AppColors.primary,
                delay: 200,
                onTap: () {
                  ref.read(intendedRoleProvider.notifier).state = UserRole.client;
                  context.push(AppRoutes.registerProfile);
                },
              ),

              const SizedBox(height: 24),

              // ── Opción Trabajador ──
              _RoleCard(
                title: 'Quiero trabajar',
                description: 'Ofrezco mis servicios profesionales y busco nuevos clientes.',
                icon: Icons.handyman_rounded,
                color: AppColors.secondary,
                delay: 300,
                onTap: () {
                  ref.read(intendedRoleProvider.notifier).state = UserRole.worker;
                  context.push(AppRoutes.registerProfile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      splashColor: color.withValues(alpha: 0.1),
      highlightColor: color.withValues(alpha: 0.05),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            )
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2, duration: 500.ms, delay: delay.ms).fade();
  }
}

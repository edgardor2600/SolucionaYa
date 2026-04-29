import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/client_home_screen.dart';
import '../features/home/screens/worker_home_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/worker_profile/screens/worker_profile_detail_screen.dart';
import '../features/shell/client_shell.dart';
import '../features/shell/worker_shell.dart';

// ── Provider del router ──────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return _buildRouter();
});

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    routes: [
      // ── Splash ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.loginEmail,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPhone,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Shell Cliente (con bottom nav) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (_, __) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.clientExplore,
            builder: (_, __) => const ExploreScreen(),
          ),
          GoRoute(
            path: AppRoutes.clientChats,
            builder: (_, __) => const _PlaceholderScreen(label: 'Chats'),
          ),
          GoRoute(
            path: AppRoutes.clientProfile,
            builder: (_, __) => const _PlaceholderScreen(label: 'Mi Perfil'),
          ),
        ],
      ),

      // ── Shell Trabajador (con bottom nav) ─────────────────────────
      ShellRoute(
        builder: (context, state, child) => WorkerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.workerHome,
            builder: (_, __) => const WorkerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.workerActivity,
            builder: (_, __) =>
                const _PlaceholderScreen(label: 'Actividad'),
          ),
          GoRoute(
            path: AppRoutes.workerChats,
            builder: (_, __) => const _PlaceholderScreen(label: 'Mensajes'),
          ),
          GoRoute(
            path: AppRoutes.workerStats,
            builder: (_, __) =>
                const _PlaceholderScreen(label: 'Estadísticas'),
          ),
        ],
      ),

      // ── Perfil público del trabajador (fuera del shell) ───────────
      GoRoute(
        path: '/worker/:workerId',
        builder: (_, state) => WorkerProfileDetailScreen(
          workerId: state.pathParameters['workerId'] ?? '',
        ),
      ),
    ],
  );
}

/// Guard global: redirige según estado de sesión.
String? _globalRedirect(BuildContext context, GoRouterState state) {
  final user = FirebaseAuth.instance.currentUser;
  final isSplash = state.matchedLocation == AppRoutes.splash;
  final isAuthRoute = state.matchedLocation == AppRoutes.loginEmail ||
      state.matchedLocation == AppRoutes.registerPhone;

  // En el splash no redirigimos — él mismo maneja la lógica
  if (isSplash) return null;

  // No hay sesión y no está en una ruta de auth → login
  if (user == null && !isAuthRoute) return AppRoutes.loginEmail;

  // Hay sesión y está intentando ir a auth → home de cliente
  if (user != null && isAuthRoute) return AppRoutes.clientHome;

  return null;
}

// ── Placeholder temporal para rutas no implementadas aún ────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

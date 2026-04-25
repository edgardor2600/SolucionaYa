import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';

// Pantallas temporales (se reemplazarán en días posteriores)
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';

/// Punto de entrada de la aplicación SolucionaYa.
/// Usa Riverpod como gestor de estado y go_router para navegación.
class SolucionaYaApp extends ConsumerWidget {
  const SolucionaYaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SolucionaYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Router (se expandirá en el Día 8 con guards por rol)
// ─────────────────────────────────────────────────────────────
final GoRouter _router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginEmail,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerPhone,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientHome,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

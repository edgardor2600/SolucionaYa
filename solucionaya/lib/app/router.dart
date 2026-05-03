import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../data/models/user_model.dart';
import '../data/models/worker_profile_model.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/select_role_screen.dart';
import '../features/auth/screens/phone_auth_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/complete_profile_screen.dart';
import '../features/auth/screens/worker_docs_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../data/models/category_model.dart';
import '../features/home/screens/client_home_screen.dart';
import '../features/home/screens/worker_home_screen.dart';
import '../features/shell/client_shell.dart';
import '../features/shell/worker_shell.dart';
import '../features/worker_profile/screens/worker_profile_detail_screen.dart';
import 'providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUserProfile = ref.watch(currentUserProfileProvider);
  final workerProfile = ref.watch(currentWorkerProfileProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect:
        (context, state) => _globalRedirect(
          state: state,
          authState: authState,
          currentUserProfile: currentUserProfile,
          workerProfile: workerProfile,
        ),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.loginEmail,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerEmail,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectRole,
        builder: (_, __) => const SelectRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPhone,
        builder: (_, __) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerOtp,
        builder: (_, __) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerProfile,
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerWorkerDocs,
        builder: (_, __) => const WorkerDocsScreen(),
      ),
      GoRoute(
        path: AppRoutes.workerPending,
        builder:
            (_, __) => const _PlaceholderScreen(label: 'Perfil en revision'),
      ),
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (_, __) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.clientExplore,
            builder: (_, state) => ExploreScreen(
              initialCategory: state.extra as CategoryModel?,
            ),
          ),
          GoRoute(
            path: AppRoutes.clientChats,
            builder: (_, __) => const _PlaceholderScreen(label: 'Chats'),
          ),
          GoRoute(
            path: AppRoutes.clientProfile,
            builder: (_, __) => const _PlaceholderScreen(label: 'Mi perfil'),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => WorkerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.workerHome,
            builder: (_, __) => const WorkerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.workerActivity,
            builder: (_, __) => const _PlaceholderScreen(label: 'Actividad'),
          ),
          GoRoute(
            path: AppRoutes.workerChats,
            builder: (_, __) => const _PlaceholderScreen(label: 'Mensajes'),
          ),
          GoRoute(
            path: AppRoutes.workerStats,
            builder: (_, __) => const _PlaceholderScreen(label: 'Estadisticas'),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.workerProfileDetail,
        builder:
            (_, state) => WorkerProfileDetailScreen(
              workerId: state.pathParameters['workerId'] ?? '',
            ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const _PlaceholderScreen(label: 'Admin dashboard'),
      ),
      GoRoute(
        path: AppRoutes.adminWorkers,
        builder: (_, __) => const _PlaceholderScreen(label: 'Admin workers'),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (_, __) => const _PlaceholderScreen(label: 'Admin reports'),
      ),
      GoRoute(
        path: AppRoutes.adminCategories,
        builder: (_, __) => const _PlaceholderScreen(label: 'Admin categories'),
      ),
    ],
  );
});

String? _globalRedirect({
  required GoRouterState state,
  required AsyncValue<User?> authState,
  required AsyncValue<UserModel?> currentUserProfile,
  required AsyncValue<WorkerProfileModel?> workerProfile,
}) {
  final location = state.matchedLocation;
  final isSplash = location == AppRoutes.splash;
  final isAuthRoute = _authRoutes.contains(location);
  final isLoading =
      authState.isLoading ||
      (authState.valueOrNull != null && currentUserProfile.isLoading) ||
      (currentUserProfile.valueOrNull?.role == UserRole.worker && workerProfile.isLoading);

  if (isLoading) {
    return isSplash ? null : AppRoutes.splash;
  }

  final user = authState.valueOrNull;
  final profile = currentUserProfile.valueOrNull;

  if (user == null) {
    return _isProtectedRoute(location) ? AppRoutes.registerPhone : null;
  }

  if (profile == null) {
    // Si no hay perfil, el usuario debe seleccionar rol o completar perfil
    if (location == AppRoutes.selectRole || location == AppRoutes.registerProfile) {
      return null;
    }
    return AppRoutes.selectRole;
  }

  // Lógica específica para trabajadores: si no tienen perfil de trabajador, obligarlos a crearlo.
  if (profile.role == UserRole.worker && workerProfile.valueOrNull == null) {
    return location == AppRoutes.registerWorkerDocs
        ? null
        : AppRoutes.registerWorkerDocs;
  }

  final home = _homeForRole(profile.role);

  if (isSplash || isAuthRoute) {
    return home;
  }

  if (_isAdminRoute(location) && profile.role != UserRole.admin) {
    return home;
  }

  if (_isWorkerPrivateRoute(location) && profile.role != UserRole.worker) {
    return home;
  }

  if (_isClientRoute(location) && profile.role != UserRole.client) {
    return home;
  }

  return null;
}

const _authRoutes = {
  AppRoutes.onboarding,
  AppRoutes.selectRole,
  AppRoutes.loginEmail,
  AppRoutes.registerPhone,
  AppRoutes.registerOtp,
  AppRoutes.registerProfile,
  AppRoutes.registerWorkerDocs,
};

String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.client:
      return AppRoutes.clientHome;
    case UserRole.worker:
      return AppRoutes.workerHome;
    case UserRole.admin:
      return AppRoutes.adminDashboard;
  }
}

bool _isProtectedRoute(String location) {
  return _isClientRoute(location) ||
      _isWorkerPrivateRoute(location) ||
      _isAdminRoute(location) ||
      location.startsWith('/chat/');
}

bool _isClientRoute(String location) => location.startsWith('/client/');

bool _isAdminRoute(String location) => location.startsWith('/admin/');

bool _isWorkerPrivateRoute(String location) {
  return location == AppRoutes.workerHome ||
      location == AppRoutes.workerActivity ||
      location == AppRoutes.workerChats ||
      location == AppRoutes.workerStats ||
      location == AppRoutes.workerEditProfile ||
      location == AppRoutes.workerPrices ||
      location == AppRoutes.workerGallery ||
      location == AppRoutes.workerPending;
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/user_model.dart';
import 'select_role_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final userRepo = ref.read(userRepositoryProvider);
      
      // Recuperar el rol que el usuario seleccionó antes. Por defecto: cliente.
      final role = ref.read(intendedRoleProvider) ?? UserRole.client;

      final userModel = UserModel(
        uid: user.uid,
        role: role,
        displayName: _nameCtrl.text.trim(),
        phone: user.phoneNumber ?? '',
        email: user.email ?? '', // Puede estar vacío si entró con teléfono
        city: _cityCtrl.text.trim(),
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        isActive: true,
        fcmTokens: const [],
      );

      await userRepo.createUser(userModel);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil creado exitosamente!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Limpiamos el rol temporal
      ref.read(intendedRoleProvider.notifier).state = null;

      // El router nos enviará al home automáticamente porque el perfil ya no es null.
      // Pero podemos forzarlo por si acaso:
      if (role == UserRole.client) {
        context.go(AppRoutes.clientHome);
      } else {
        context.go(AppRoutes.workerHome);
      }
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear perfil: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final intendedRole = ref.watch(intendedRoleProvider) ?? UserRole.client;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Icon ──
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: intendedRole == UserRole.worker 
                          ? AppColors.secondary.withValues(alpha: 0.1) 
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      size: 48,
                      color: intendedRole == UserRole.worker ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                Text(
                  'Un último paso...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 100.ms).fade(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Necesitamos tu nombre y ciudad para que las demás personas puedan contactarte.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 200.ms).fade(),

                const SizedBox(height: 48),

                // ── Inputs ──
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                    if (v.trim().length < 3) return 'El nombre es muy corto';
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 300.ms).fade(),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _completeProfile(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Ciudad donde vives',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Indica tu ciudad';
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 400.ms).fade(),

                const SizedBox(height: 48),

                // ── Botón Finalizar ──
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: intendedRole == UserRole.worker ? AppColors.secondary : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: (intendedRole == UserRole.worker ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Finalizar Registro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 500.ms).fade(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

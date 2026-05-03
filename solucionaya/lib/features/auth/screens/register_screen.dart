import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authProvider);
    final success = await notifier.registerWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      // Si el registro es exitoso, el sistema nos auto-logeó.
      // El GoRouter detectará user != null && profile == null
      // y nos redirigirá a SelectRoleScreen automáticamente.
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear la cuenta.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(authProvider).isLoading;

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
      body: Stack(
        children: [
          // ── Fondo decorativo animado ──
          Positioned(
            top: -150,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutCubic),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Hero ──
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                            Container(
                              height: 72,
                              width: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, size: 36, color: Colors.white),
                            ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // ── Textos ──
                      Text(
                        'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ).animate().slideY(begin: 0.3, duration: 500.ms).fade(),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Registra tu correo y contraseña para unirte.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 100.ms).fade(),

                      const SizedBox(height: 48),

                      // ── Formulario ──
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Por favor ingresa tu correo.';
                          if (!v.contains('@')) return 'Ingresa un correo válido.';
                          return null;
                        },
                      ).animate().slideY(begin: 0.2, duration: 500.ms, delay: 200.ms).fade(),
                      
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Crea una contraseña.';
                          if (v.length < 6) return 'Mínimo 6 caracteres.';
                          return null;
                        },
                      ).animate().slideY(begin: 0.2, duration: 500.ms, delay: 300.ms).fade(),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: Icon(Icons.lock_clock_outlined, color: colorScheme.primary),
                        ),
                        validator: (v) {
                          if (v != _passCtrl.text) return 'Las contraseñas no coinciden.';
                          return null;
                        },
                      ).animate().slideY(begin: 0.2, duration: 500.ms, delay: 400.ms).fade(),

                      // ── CTA ──
                      const SizedBox(height: 48),
                      
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Registrarme',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold, 
                                    letterSpacing: 0.5
                                  ),
                                ),
                        ),
                      ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 500.ms).fade(),
                      
                      const SizedBox(height: 24),
                      
                      // ── Footer ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta?',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.pop(), // Vuelve al login de correo
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 600.ms, duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

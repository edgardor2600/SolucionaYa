import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) return;

    setState(() => _isVerifying = true);

    final notifier = ref.read(authProvider);
    final success = await notifier.verifyOtp(otp: otp);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (!success) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Código incorrecto. Intenta de nuevo.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // Si es exitoso, el GoRouter automáticamente detectará el cambio de estado 
    // y redirigirá a registerProfile o al Home según exista el perfil.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isComplete = _otpCtrl.text.length == 6;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(authProvider.notifier).clearTransientState();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Icon ──
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 40,
                    color: AppColors.secondary,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 24),
              
              // ── Textos ──
              Text(
                'Verifica tu número',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 100.ms).fade(),
              
              const SizedBox(height: 8),
              
              Text(
                'Hemos enviado un código de 6 dígitos por SMS. Por favor, ingrésalo a continuación.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 200.ms).fade(),

              const SizedBox(height: 48),

              // ── Input de OTP ──
              Center(
                child: SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 16,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 300.ms).fade(),

              const Spacer(),

              // ── Botón de Verificar ──
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (!isComplete || _isVerifying) ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Confirmar código',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 400.ms).fade(),
              
              const SizedBox(height: 16),
              
              // ── Opción Reenviar ──
              TextButton(
                onPressed: () {
                  // TODO: Implementar lógica de reenvío
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código reenviado (simulación)')),
                  );
                },
                child: Text(
                  '¿No recibiste el código? Reenviar',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fade(delay: 500.ms),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

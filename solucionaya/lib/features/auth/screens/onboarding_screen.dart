import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/providers/shared_prefs_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Soluciones al instante',
      description:
          'Encuentra profesionales calificados para cualquier reparación o mantenimiento en tu hogar, al alcance de un clic.',
      icon: Icons.flash_on_rounded,
      color: AppColors.primary,
    ),
    OnboardingSlideData(
      title: 'Seguridad y confianza',
      description:
          'Todos nuestros trabajadores pasan por un riguroso proceso de verificación. Tu tranquilidad es nuestra prioridad.',
      icon: Icons.verified_user_rounded,
      color: AppColors.success,
    ),
    OnboardingSlideData(
      title: 'Pagos transparentes',
      description:
          'Acuerda el precio antes de empezar el trabajo. Sin sorpresas, con total claridad y soporte en todo momento.',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.secondary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await ref.read(onboardingSeenProvider.notifier).setSeen(prefs);
    if (mounted) {
      context.go(AppRoutes.loginEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLastPage = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Fondo decorativo abstracto ──
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _slides[_currentIndex].color.withValues(alpha: 0.1),
              ),
            ).animate(target: _currentIndex.toDouble()).scale(
              duration: 600.ms,
              curve: Curves.easeInOut,
            ),
          ),
          
          // ── PageView ──
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index], index == _currentIndex);
                  },
                ),
              ),
              
              // ── Botonera y Controles ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    children: [
                      // Indicadores de página
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentIndex == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? _slides[_currentIndex].color
                                  : colorScheme.onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _slides[_currentIndex].color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isLastPage ? 'Comenzar' : 'Siguiente',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                      ),
                      
                      // Botón Saltar (solo visible si no es la última)
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isLastPage ? 0.0 : 1.0,
                        child: TextButton(
                          onPressed: isLastPage ? null : _finishOnboarding,
                          child: Text(
                            'Saltar',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingSlideData slide, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // ── Icono Central con Efecto Glassmorphism ──
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.color.withValues(alpha: 0.15),
                ),
              ).animate(target: isActive ? 1 : 0)
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack)
               .fade(duration: 400.ms),
              
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.color.withValues(alpha: 0.25),
                ),
                child: Icon(
                  slide.icon,
                  size: 64,
                  color: slide.color,
                ),
              ).animate(target: isActive ? 1 : 0)
               .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutBack)
               .fade(duration: 400.ms),
            ],
          ),
          const Spacer(flex: 1),
          
          // ── Textos ──
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ).animate(target: isActive ? 1 : 0)
           .slideY(begin: 0.5, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
           .fade(duration: 500.ms),
           
          const SizedBox(height: 16),
          
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ).animate(target: isActive ? 1 : 0)
           .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
           .fade(duration: 600.ms),
           
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

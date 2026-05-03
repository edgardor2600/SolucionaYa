import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_profile_model.dart';
import '../../../core/constants/app_routes.dart';

class WorkerDocsScreen extends ConsumerStatefulWidget {
  const WorkerDocsScreen({super.key});

  @override
  ConsumerState<WorkerDocsScreen> createState() => _WorkerDocsScreenState();
}

class _WorkerDocsScreenState extends ConsumerState<WorkerDocsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experienceCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  ServiceCategory? _selectedCategory;
  bool _docsUploaded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _experienceCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDocs() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría de servicio')),
      );
      return;
    }
    if (!_docsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor sube tus documentos de identidad')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = ref.read(currentUserProfileProvider).value;
      if (userModel == null) throw Exception('Usuario no encontrado');

      final workerRepo = ref.read(workerRepositoryProvider);
      final yearsExp = int.tryParse(_experienceCtrl.text.trim()) ?? 0;

      final workerProfile = WorkerProfileModel(
        uid: userModel.uid,
        displayName: userModel.displayName,
        category: _selectedCategory!,
        city: userModel.city,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false, // Inactivo hasta ser aprobado
        isAvailableNow: false,
        isVerified: false,
        isApproved: false,
        totalReviews: 0,
        rating: 0.0,
        totalJobsDone: 0,
        profileViews: 0,
        responseTimeMinutes: 30,
        profileCompleteness: 50,
        yearsExperience: yearsExp,
        bio: _bioCtrl.text.trim(),
        pendingReason: 'Revisión de documentos de identidad',
      );

      await workerRepo.createWorkerProfile(workerProfile);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Documentos enviados! Tu perfil está en revisión.'),
          backgroundColor: AppColors.success,
        ),
      );

      // El Router detectará la creación del WorkerProfileModel y redirigirá al WorkerHome.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: AppColors.error,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Completar Solicitud'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Icon ──
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      size: 40,
                      color: AppColors.secondary,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 24),
                
                Text(
                  'Únete como Profesional',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 100.ms).fade(),
                
                const SizedBox(height: 8),
                
                Text(
                  'Dinos qué sabes hacer y sube tu identificación para verificar tu perfil.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 200.ms).fade(),

                const SizedBox(height: 32),

                // ── Especialidad ──
                Text(
                  '¿Cuál es tu especialidad?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 300.ms).fade(),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: ServiceCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 16,
                            color: isSelected ? Colors.white : category.color,
                          ),
                          const SizedBox(width: 8),
                          Text(category.label),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: category.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = category);
                      },
                    );
                  }).toList(),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 400.ms).fade(),

                const SizedBox(height: 32),

                // ── Años de experiencia ──
                TextFormField(
                  controller: _experienceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Años de experiencia',
                    prefixIcon: Icon(Icons.timeline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (int.tryParse(v) == null) return 'Ingresa un número';
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 500.ms).fade(),

                const SizedBox(height: 20),

                // ── Breve descripción ──
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos un poco sobre ti (Opcional)',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 32.0),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 600.ms).fade(),

                const SizedBox(height: 32),

                // ── Subir Documentos ──
                Text(
                  'Documentos de Verificación',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 700.ms).fade(),
                const SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    // Simular subida de documentos
                    setState(() => _docsUploaded = !_docsUploaded);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _docsUploaded ? AppColors.success : colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: _docsUploaded ? AppColors.success.withValues(alpha: 0.05) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _docsUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                          size: 32,
                          color: _docsUploaded ? AppColors.success : colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _docsUploaded ? 'Documento cargado' : 'Subir documento de identidad',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Foto de tu cédula (Frente y Reverso)',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 800.ms).fade(),

                const SizedBox(height: 48),

                // ── Botón Enviar ──
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitDocs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Enviar Solicitud',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 900.ms).fade(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

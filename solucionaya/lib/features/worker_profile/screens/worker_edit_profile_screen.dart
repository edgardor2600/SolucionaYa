import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_profile_model.dart';

// ─── Ciudades disponibles (MVP Colombia) ────────────────────────────────────
const _cities = [
  'Bucaramanga',
  'Barrancabermeja',
  'Medellín',
  'Bogotá',
  'Cali',
  'Barranquilla',
  'Cartagena',
  'Cúcuta',
  'Manizales',
  'Pereira',
];

class WorkerEditProfileScreen extends ConsumerStatefulWidget {
  const WorkerEditProfileScreen({super.key});

  @override
  ConsumerState<WorkerEditProfileScreen> createState() =>
      _WorkerEditProfileScreenState();
}

class _WorkerEditProfileScreenState
    extends ConsumerState<WorkerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String? _selectedCity;
  int _yearsExperience = 0;
  bool _isLoading = false;
  bool _initialized = false;

  // Para el contador de bio
  int get _bioChars => _bioCtrl.text.length;
  static const _bioMaxChars = 300;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  /// Precarga los datos actuales del trabajador en los campos.
  void _initFromWorker(WorkerProfileModel worker) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = worker.displayName;
    _bioCtrl.text = worker.bio ?? '';
    _selectedCity = _cities.contains(worker.city) ? worker.city : _cities.first;
    _yearsExperience = worker.yearsExperience.clamp(0, 20);
    _whatsappCtrl.text = worker.whatsappNumber?.replaceFirst('+57', '') ?? '';
    setState(() {});
  }

  Future<void> _save(WorkerProfileModel current) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(workerRepositoryProvider);

      final whatsappRaw = _whatsappCtrl.text.trim();
      final whatsappFull =
          whatsappRaw.isNotEmpty ? '+57$whatsappRaw' : null;

      await repo.updateWorkerProfile(current.uid, {
        'displayName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'city': _selectedCity!,
        'yearsExperience': _yearsExperience,
        if (whatsappFull != null) 'whatsappNumber': whatsappFull,
        if (whatsappFull == null) 'whatsappNumber': null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil actualizado con éxito!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
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
    final workerAsync = ref.watch(currentWorkerProfileProvider);

    return workerAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (worker) {
        if (worker == null) {
          return const Scaffold(
            body: Center(child: Text('Perfil no encontrado.')),
          );
        }
        _initFromWorker(worker);
        return _buildForm(context, worker);
      },
    );
  }

  Widget _buildForm(BuildContext context, WorkerProfileModel worker) {
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
        title: const Text(
          'Editar Perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _save(worker),
            child: Text(
              'Guardar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Foto de perfil ──
              _PhotoSection(worker: worker)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // ── Sección: Información Básica ──
              _SectionHeader(
                icon: Icons.person_outline_rounded,
                title: 'Información básica',
              ).animate().slideY(begin: 0.2, duration: 400.ms).fade(),

              const SizedBox(height: 16),

              // Nombre completo
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 50.ms).fade(),

              const SizedBox(height: 20),

              // Ciudad
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  prefixIcon: Icon(Icons.location_city_rounded),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                validator: (v) => v == null ? 'Selecciona tu ciudad' : null,
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fade(),

              const SizedBox(height: 32),

              // ── Sección: Experiencia ──
              _SectionHeader(
                icon: Icons.timeline_rounded,
                title: 'Experiencia profesional',
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 150.ms).fade(),

              const SizedBox(height: 16),

              // Años de experiencia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Años de experiencia',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _yearsExperience == 0
                                ? 'Sin especificar'
                                : _yearsExperience >= 20
                                    ? '20+ años'
                                    : '$_yearsExperience ${_yearsExperience == 1 ? 'año' : 'años'}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        thumbColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _yearsExperience.toDouble(),
                        min: 0,
                        max: 20,
                        divisions: 20,
                        onChanged: (v) =>
                            setState(() => _yearsExperience = v.round()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0', style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          )),
                          Text('20+', style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 200.ms).fade(),

              const SizedBox(height: 32),

              // ── Sección: Descripción ──
              _SectionHeader(
                icon: Icons.description_outlined,
                title: 'Sobre ti',
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 250.ms).fade(),

              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioCtrl,
                maxLines: 4,
                maxLength: _bioMaxChars,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Descripción breve',
                  alignLabelWithHint: true,
                  hintText:
                      'Cuéntales a los clientes quién eres, tu especialidad y qué hace tu trabajo diferente...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60.0),
                    child: Icon(Icons.notes_rounded),
                  ),
                  // Reemplazamos el counter por uno personalizado
                  counterText: '',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(top: 60, right: 12),
                    child: Text(
                      '$_bioChars/$_bioMaxChars',
                      style: TextStyle(
                        fontSize: 11,
                        color: _bioChars > _bioMaxChars * 0.9
                            ? AppColors.warning
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && v.trim().length < 20) {
                    return 'La descripción debe tener al menos 20 caracteres o estar vacía';
                  }
                  return null;
                },
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 300.ms).fade(),

              const SizedBox(height: 32),

              // ── Sección: Contacto ──
              _SectionHeader(
                icon: Icons.contact_phone_outlined,
                title: 'Contacto',
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 350.ms).fade(),

              const SizedBox(height: 8),

              Text(
                'Opcional. Los clientes podrán contactarte directamente por WhatsApp.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ).animate().fade(delay: 350.ms),

              const SizedBox(height: 16),

              // WhatsApp
              TextFormField(
                controller: _whatsappCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(worker),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
                decoration: InputDecoration(
                  labelText: 'WhatsApp (opcional)',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Color(0xFF25D366),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+57',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length != 10) {
                    return 'Ingresa los 10 dígitos del número colombiano';
                  }
                  return null;
                },
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 400.ms).fade(),

              const SizedBox(height: 48),

              // ── Botón Guardar ──
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _save(worker),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Guardando...' : 'Guardar cambios',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ).animate().slideY(begin: 0.3, duration: 400.ms, delay: 500.ms).fade(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sección de foto de perfil ────────────────────────────────────────────────
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.worker});
  final WorkerProfileModel worker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: worker.photoUrl != null
                ? NetworkImage(worker.photoUrl!)
                : null,
            child: worker.photoUrl == null
                ? Text(
                    worker.displayName.isNotEmpty
                        ? worker.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          // Botón de editar foto (Día 19 integra image_picker)
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 3,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'La subida de fotos se habilitará en el Día 19 (Galería).'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

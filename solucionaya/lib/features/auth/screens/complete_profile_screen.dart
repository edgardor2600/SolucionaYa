import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/location_service.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:geocoding/geocoding.dart' show locationFromAddress, placemarkFromCoordinates;
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
  double? _latitude;
  double? _longitude;

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      final service = LocationService();
      final result = await service.getCurrentLocationAndCity();
      if (!mounted) return;
      setState(() {
        _cityCtrl.text = result.city;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Ubicación detectada: ${result.city}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on GpsPermissionPermanentlyDeniedException catch (e) {
      if (!mounted) return;
      // El permiso fue denegado permanentemente → guiar al usuario a los ajustes del sistema
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: AppColors.error),
              SizedBox(width: 10),
              Text('Permiso requerido'),
            ],
          ),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Abrir Ajustes'),
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    } on GpsServiceDisabledException catch (e) {
      if (!mounted) return;
      // El GPS está apagado → guiar al usuario a activarlo
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.gps_off_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Text('GPS desactivado'),
            ],
          ),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: const Text('Activar GPS'),
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    } on GpsPermissionDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _getLocation,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      
      // Si la ubicación es editada manualmente o las coordenadas son nulas, intentar resolverlas
      if (_latitude == null || _longitude == null) {
        try {
          final query = _cityCtrl.text.trim();
          if (query.isNotEmpty) {
            final locations = await locationFromAddress(query);
            if (locations.isNotEmpty) {
              _latitude = locations.first.latitude;
              _longitude = locations.first.longitude;
              debugPrint('Geocodificado manual exitoso: $query -> $_latitude, $_longitude');
            }
          }
        } catch (e) {
          debugPrint('No se pudo geocodificar la dirección manual ($e). Usando Bucaramanga por defecto.');
          // Fallback a coordenadas de Bucaramanga
          _latitude = 7.1139;
          _longitude = -73.1198;
        }
      }

      // Obtener dirección física aproximada detallada para registrar como 'Casa' por defecto
      String streetAddress = 'Calle Principal, ${_cityCtrl.text.trim()}';
      if (_latitude != null && _longitude != null) {
        try {
          final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final street = p.thoroughfare?.isNotEmpty == true ? p.thoroughfare! : 'Calle';
            final number = p.subThoroughfare?.isNotEmpty == true ? ' #${p.subThoroughfare!}' : '';
            final cityStr = p.locality?.isNotEmpty == true ? p.locality! : _cityCtrl.text.trim();
            streetAddress = '$street$number, $cityStr';
          }
        } catch (e) {
          debugPrint('No se pudo resolver la calle detallada ($e). Usando calle aproximada.');
        }
      }

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
        latitude: _latitude,
        longitude: _longitude,
        savedAddresses: [
          {'type': 'Casa', 'address': streetAddress},
        ],
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
                  readOnly: false, // Permitir escribir manualmente si falla el GPS
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Ciudad donde vives',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                      onPressed: _getLocation,
                      tooltip: 'Detectar por GPS',
                    ),
                    hintText: 'Escribe tu ciudad o toca el icono para detectar',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Por favor escribe o detecta tu ubicación';
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

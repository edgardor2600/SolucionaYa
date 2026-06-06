import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/worker_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/location_service.dart';
import '../../favorites/favorites_repository.dart';
import 'package:geocoding/geocoding.dart' show placemarkFromCoordinates;

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  bool _isDarkMode = false;

  void _addOrEditAddress(UserModel user, int? index) {
    final typeController = TextEditingController(text: index != null ? user.savedAddresses[index]['type'] : '');
    final addressController = TextEditingController(text: index != null ? user.savedAddresses[index]['address'] : '');
    bool isGpsDetecting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            index != null ? '📝 Editar dirección' : '📍 Agregar dirección',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Etiqueta (Ej: Casa, Oficina, Trabajo)',
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Dirección completa',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Ej: Calle 36 # 14-20, Bucaramanga',
                  suffixIcon: isGpsDetecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                          tooltip: 'Detectar ubicación actual',
                          onPressed: () async {
                            setDialogState(() => isGpsDetecting = true);
                            try {
                              final service = ref.read(locationServiceProvider);
                              final result = await service.getCurrentLocationAndCity();
                              final lat = result.latitude;
                              final lng = result.longitude;
                              
                              // Geocodificación inversa detallada de la calle
                              String detailedStreet = 'Calle Principal, ${result.city}';
                              try {
                                final placemarks = await placemarkFromCoordinates(lat, lng);
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  final street = p.thoroughfare?.isNotEmpty == true ? p.thoroughfare! : 'Calle';
                                  final number = p.subThoroughfare?.isNotEmpty == true ? ' #${p.subThoroughfare!}' : '';
                                  final cityStr = p.locality?.isNotEmpty == true ? p.locality! : result.city;
                                  detailedStreet = '$street$number, $cityStr';
                                }
                              } catch (_) {}

                              setDialogState(() {
                                addressController.text = detailedStreet;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error GPS: $e')),
                                );
                              }
                            } finally {
                              setDialogState(() => isGpsDetecting = false);
                            }
                          },
                        ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (typeController.text.trim().isNotEmpty && addressController.text.trim().isNotEmpty) {
                  final userRepo = ref.read(userRepositoryProvider);
                  final currentAddresses = List<Map<String, String>>.from(user.savedAddresses);
                  final newAddress = {
                    'type': typeController.text.trim(),
                    'address': addressController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
                  };

                  if (index != null) {
                    currentAddresses[index] = newAddress;
                  } else {
                    currentAddresses.add(newAddress);
                  }

                  await userRepo.updateUser(user.uid, {'savedAddresses': currentAddresses});
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Esta acción es definitiva. Se borrarán tus datos de perfil, historial de solicitudes y favoritos de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final authNotifier = ref.read(authProvider);
              await authNotifier.deleteCurrentAccount();
              if (mounted) {
                context.go(AppRoutes.onboarding);
              }
            },
            child: const Text('Eliminar definitivamente', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar perfil:\n$e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no autenticado'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header del Perfil
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user.photoUrl != null
                              ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    user.displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      // Nombre y Ciudad
                      Text(
                        user.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            user.city,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido Principal
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 🏠 DIRECCIONES GUARDADAS
                    _buildSectionTitle(theme, 'Direcciones guardadas'),
                    const SizedBox(height: 12),
                    if (user.savedAddresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Aún no tienes direcciones guardadas. Agrega una para facilitar tus solicitudes.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(user.savedAddresses.length, (index) {
                        final addr = user.savedAddresses[index];
                        final type = addr['type'] ?? 'Dirección';
                        final address = addr['address'] ?? '';
                        
                        // Icono dinámico según la etiqueta
                        IconData iconData = Icons.location_on_rounded;
                        final t = type.toLowerCase();
                        if (t.contains('casa') || t.contains('hogar') || t.contains('home')) {
                          iconData = Icons.home_rounded;
                        } else if (t.contains('trabajo') || t.contains('oficina') || t.contains('work') || t.contains('empleo') || t.contains('negocio')) {
                          iconData = Icons.work_rounded;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                iconData,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              type,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(address),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                                  tooltip: 'Editar',
                                  onPressed: () => _addOrEditAddress(user, index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  tooltip: 'Eliminar',
                                  onPressed: () async {
                                    final userRepo = ref.read(userRepositoryProvider);
                                    final currentAddresses = List<Map<String, String>>.from(user.savedAddresses);
                                    currentAddresses.removeAt(index);
                                    await userRepo.updateUser(user.uid, {'savedAddresses': currentAddresses});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Dirección eliminada'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _addOrEditAddress(user, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar nueva dirección'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                    const SizedBox(height: 24),

                    // ❤️ TRABAJADORES FAVORITOS
                    _buildSectionTitle(theme, 'Trabajadores favoritos'),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // Lista Horizontal / Grid de Favoritos
              _buildFavoritesGrid(ref, theme),

              // Ajustes y Cuenta
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildSectionTitle(theme, 'Ajustes y Cuenta'),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                            title: const Text('Modo oscuro'),
                            trailing: Switch.adaptive(
                              value: _isDarkMode,
                              onChanged: (val) {
                                setState(() {
                                  _isDarkMode = val;
                                });
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                            title: const Text('Política de privacidad'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                            title: const Text('Términos y condiciones'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                            title: const Text('Cerrar sesión'),
                            onTap: () async {
                              final authNotifier = ref.read(authProvider);
                              await authNotifier.signOut();
                              if (mounted) {
                                context.go(AppRoutes.onboarding);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: _confirmDeleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Eliminar mi cuenta'),
                    ),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildFavoritesGrid(WidgetRef ref, ThemeData theme) {
    final favoritesAsync = ref.watch(favoriteWorkersProvider);

    return favoritesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error al cargar favoritos: $e')),
      ),
      data: (workers) {
        if (workers.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes favoritos aún',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explora profesionales en tu zona y guárdalos aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final worker = workers[index];
                return GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.workerDetail(worker.uid));
                  },
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: worker.category.color.withValues(alpha: 0.1),
                            backgroundImage: worker.photoUrl != null ? NetworkImage(worker.photoUrl!) : null,
                            child: worker.photoUrl == null
                                ? Text(
                                    worker.displayName[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: worker.category.color,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            worker.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            worker.category.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: worker.category.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                worker.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: workers.length,
            ),
          ),
        );
      },
    );
  }
}

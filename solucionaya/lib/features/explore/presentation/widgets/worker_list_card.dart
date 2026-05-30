import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/worker_profile_model.dart';

class WorkerListCard extends ConsumerWidget {
  const WorkerListCard({super.key, required this.worker});

  final WorkerProfileModel worker;

  String _formatCOP(double amount) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
  }

  String? _getDistanceText(double? clientLat, double? clientLng) {
    if (clientLat != null && clientLng != null && worker.latitude != null && worker.longitude != null) {
      final distanceInMeters = Geolocator.distanceBetween(clientLat, clientLng, worker.latitude!, worker.longitude!);
      final distanceInKm = distanceInMeters / 1000;
      if (distanceInKm < 1) return 'A ${distanceInMeters.toStringAsFixed(0)} m';
      return 'A ${distanceInKm.toStringAsFixed(1)} km';
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accentColor = worker.category.color;
    final clientProfile = ref.watch(currentUserProfileProvider).value;
    final distanceText = _getDistanceText(clientProfile?.latitude, clientProfile?.longitude);

    return GestureDetector(
      onTap: () => context.push('/worker/${worker.uid}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top Header: Avatar & Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: accentColor.withOpacity(0.1),
                        child: worker.photoUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: worker.photoUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                worker.displayName[0].toUpperCase(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (worker.isAvailableNow)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                worker.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (worker.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                worker.category.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (distanceText != null) ...[
                              Icon(Icons.location_on_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(distanceText, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              worker.rating > 0 ? worker.rating.toStringAsFixed(1) : 'Nuevo',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (worker.totalReviews > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${worker.totalReviews})',
                                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                            const Spacer(),
                            if (worker.startingPrice != null)
                              Text(
                                'Desde ${_formatCOP(worker.startingPrice!)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Action Bar (Opcional, mini info)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Responde en ~${worker.responseTimeMinutes ?? 30} min',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    'Ver perfil',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// ─── Excepciones específicas para el manejo de permisos en la UI ─────────────

/// El GPS del dispositivo está desactivado en la configuración del sistema.
class GpsServiceDisabledException implements Exception {
  final String message;
  const GpsServiceDisabledException(
      [this.message =
          'El GPS está desactivado. Actívalo en los ajustes del dispositivo.']);
  @override
  String toString() => message;
}

/// El permiso de ubicación fue denegado permanentemente.
class GpsPermissionPermanentlyDeniedException implements Exception {
  final String message;
  const GpsPermissionPermanentlyDeniedException(
      [this.message =
          'Permiso de ubicación denegado de forma permanente. Ábrelo desde Ajustes → Aplicaciones → SolucionaYa → Permisos.']);
  @override
  String toString() => message;
}

/// El permiso de ubicación fue rechazado en el diálogo del sistema.
class GpsPermissionDeniedException implements Exception {
  final String message;
  const GpsPermissionDeniedException(
      [this.message =
          'Permiso de ubicación denegado. Toca "Permitir" en el diálogo de permisos.']);
  @override
  String toString() => message;
}

// ─── Servicio Principal ───────────────────────────────────────────────────────

class LocationService {
  /// Verifica y solicita permisos de ubicación de forma secuencial.
  Future<LocationPermission> _ensurePermission() async {
    // 1. Verificar si el GPS del sistema está activado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: El GPS físico del dispositivo está desactivado.');
      throw const GpsServiceDisabledException();
    }

    // 2. Verificar el estado actual del permiso
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('LocationService: Permiso actual detectado: $permission');

    if (permission == LocationPermission.deniedForever) {
      throw const GpsPermissionPermanentlyDeniedException();
    }

    // 3. Si está denegado, solicitar al usuario
    if (permission == LocationPermission.denied) {
      debugPrint('LocationService: Solicitando permisos al usuario...');
      permission = await Geolocator.requestPermission();
      debugPrint('LocationService: Permiso tras solicitud: $permission');

      if (permission == LocationPermission.deniedForever) {
        throw const GpsPermissionPermanentlyDeniedException();
      }
      if (permission == LocationPermission.denied) {
        throw const GpsPermissionDeniedException();
      }
    }

    return permission;
  }

  /// Obtiene la posición GPS actual del dispositivo de forma segura con fallback rápido.
  Future<Position?> getCurrentPosition() async {
    try {
      await _ensurePermission();

      // Fallback 1: Intentar posición de caché (instantánea)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }

      // Fallback 2: Consultar al sensor GPS
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3), // Timeout reducido a 3 segundos
      );
    } catch (e) {
      debugPrint('LocationService (getCurrentPosition) Falló: $e');
      return null;
    }
  }

  /// Obtiene la ubicación GPS y resuelve el nombre de la ciudad usando geocodificación inversa.
  /// En caso de Timeout (típico en emulador) o fallos de sensor, aplica un fallback seguro
  /// devolviendo Bucaramanga para evitar que el usuario se quede bloqueado.
  Future<({String city, double latitude, double longitude})>
      getCurrentLocationAndCity() async {
    try {
      await _ensurePermission();
    } catch (e) {
      // Si los permisos fallan (denegados), dejamos que la excepción suba para orientar al usuario.
      rethrow;
    }

    Position? position;
    try {
      // 1. Intentar posición de caché
      position = await Geolocator.getLastKnownPosition();
      
      // 2. Si no hay caché, preguntar al sensor (máx 3 segundos)
      if (position == null) {
        debugPrint('LocationService: Consultando sensor GPS...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Si da Timeout (como en tu emulador) o falla el sensor virtual, retornamos Bucaramanga como fallback
      debugPrint('LocationService: Falló obtención real ($e). Usando Bucaramanga como fallback.');
      return (
        city: 'Bucaramanga',
        latitude: 7.1139,
        longitude: -73.1198,
      );
    }

    if (position == null) {
      return (
        city: 'Bucaramanga',
        latitude: 7.1139,
        longitude: -73.1198,
      );
    }

    // Geocodificación inversa: coordenadas → nombre de ciudad
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final cityName = place.locality?.isNotEmpty == true
            ? place.locality!
            : place.subAdministrativeArea?.isNotEmpty == true
                ? place.subAdministrativeArea!
                : place.administrativeArea ?? 'Bucaramanga';
        return (
          city: cityName,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      debugPrint('LocationService: Error geocodificación ($e). Usando coordenadas detectadas.');
    }

    return (
      city: 'Mi ciudad',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Calcula la distancia en kilómetros entre dos coordenadas GPS.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final distanceInMeters =
        Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distanceInMeters / 1000.0;
  }

  /// Formatea la distancia de forma legible.
  String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000.0).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Expone la posición GPS actual del usuario.
final userLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentPosition();
});

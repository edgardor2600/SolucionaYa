import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String city;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
  });
}

class LocationService {
  /// Solicita permisos y obtiene la posición actual del usuario y su ciudad.
  Future<LocationResult> getCurrentLocationAndCity() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verifica si el servicio de ubicación está habilitado.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados. Por favor, actívalos en tu dispositivo.');
    }

    // 2. Verifica y solicita permisos.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos de ubicación están denegados permanentemente. No podemos solicitar permisos.');
    }

    // 3. Obtiene la posición actual.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // 4. Realiza geocodificación inversa para obtener la ciudad.
    String city = 'Desconocida';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // La propiedad 'locality' suele tener el nombre de la ciudad.
        // Como fallback usamos 'subAdministrativeArea' o 'administrativeArea'.
        city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Desconocida';
        if (city.isEmpty) {
          city = 'Ubicación Desconocida';
        }
      }
    } catch (e) {
      // Ignorar el error de geocodificación y dejar la ciudad como desconocida
      // en caso de que la API de geocodificación falle.
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
    );
  }
}

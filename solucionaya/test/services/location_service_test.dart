import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/data/services/location_service.dart';

void main() {
  group('LocationService Unit Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('calculateDistance calcula la distancia aproximada entre dos puntos', () {
      // Coordenadas aproximadas de Bucaramanga a Floridablanca (Parque Principal)
      const latBga = 7.1139;
      const lonBga = -73.1198;
      
      const latFloridablanca = 7.0622;
      const lonFloridablanca = -73.0864;

      // Calcular distancia
      final distance = locationService.calculateDistance(latBga, lonBga, latFloridablanca, lonFloridablanca);
      
      // La distancia real es de unos 6.8 km en línea recta
      expect(distance, closeTo(6.8, 1.0));
    });

    test('formatDistance formatea distancias menores a 1 km en metros', () {
      final formattedMeters = locationService.formatDistance(0.350); // 350 metros
      expect(formattedMeters, '350 m');

      final formattedMetersSmall = locationService.formatDistance(0.005); // 5 metros
      expect(formattedMetersSmall, '5 m');
    });

    test('formatDistance formatea distancias mayores o iguales a 1 km en kilómetros', () {
      final formattedKm1 = locationService.formatDistance(1.0);
      expect(formattedKm1, '1.0 km');

      final formattedKmDec = locationService.formatDistance(4.567);
      expect(formattedKmDec, '4.6 km'); // Redondeado a un decimal
      
      final formattedKmLarge = locationService.formatDistance(12.34);
      expect(formattedKmLarge, '12.3 km');
    });
  });
}

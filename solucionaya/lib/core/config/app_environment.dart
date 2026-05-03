import 'package:flutter/foundation.dart';

/// Centraliza configuración sensible al entorno para evitar valores quemados
/// dispersos en la aplicación.
abstract final class AppEnvironment {
  static const String _emulatorHostOverride = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
  );

  static String get firebaseEmulatorHost {
    if (_emulatorHostOverride.isNotEmpty) {
      return _emulatorHostOverride;
    }

    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Usamos 10.0.2.2 para que el Emulador de Android encuentre el PC local.
        // Si vas a probar en un dispositivo FÍSICO, cambia esto a la IP de tu Wi-Fi (ej: 192.168.1.29).
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'localhost';
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }
}

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Configuración de las 8 categorías de servicio.
/// Sirve como fuente de verdad para íconos, colores y precios sugeridos.
enum ServiceCategory {
  plomeria,
  electricidad,
  cerrajeria,
  aseo,
  pintura,
  camaras,
  computadores,
  enchape,
}

/// Extensión con propiedades de cada categoría.
extension ServiceCategoryX on ServiceCategory {
  String get displayName {
    switch (this) {
      case ServiceCategory.plomeria:
        return AppStrings.plomeria;
      case ServiceCategory.electricidad:
        return AppStrings.electricidad;
      case ServiceCategory.cerrajeria:
        return AppStrings.cerrajeria;
      case ServiceCategory.aseo:
        return AppStrings.aseo;
      case ServiceCategory.pintura:
        return AppStrings.pintura;
      case ServiceCategory.camaras:
        return AppStrings.camaras;
      case ServiceCategory.computadores:
        return AppStrings.computadores;
      case ServiceCategory.enchape:
        return AppStrings.enchape;
    }
  }

  /// Key usada en Firestore y rutas.
  String get key => name;

  /// Color distintivo de la categoría.
  int get colorValue {
    switch (this) {
      case ServiceCategory.plomeria:
        return AppColors.plomeria.value;
      case ServiceCategory.electricidad:
        return AppColors.electricidad.value;
      case ServiceCategory.cerrajeria:
        return AppColors.cerrajeria.value;
      case ServiceCategory.aseo:
        return AppColors.aseo.value;
      case ServiceCategory.pintura:
        return AppColors.pintura.value;
      case ServiceCategory.camaras:
        return AppColors.camaras.value;
      case ServiceCategory.computadores:
        return AppColors.computadores.value;
      case ServiceCategory.enchape:
        return AppColors.enchape.value;
    }
  }

  /// Emoji / ícono representativo de la categoría (fallback si no hay SVG).
  String get emoji {
    switch (this) {
      case ServiceCategory.plomeria:
        return '🔧';
      case ServiceCategory.electricidad:
        return '⚡';
      case ServiceCategory.cerrajeria:
        return '🔐';
      case ServiceCategory.aseo:
        return '🧹';
      case ServiceCategory.pintura:
        return '🖌️';
      case ServiceCategory.camaras:
        return '📷';
      case ServiceCategory.computadores:
        return '💻';
      case ServiceCategory.enchape:
        return '🪟';
    }
  }

  /// Rango de precio mínimo sugerido (COP).
  int get suggestedPriceMin {
    switch (this) {
      case ServiceCategory.plomeria:
        return 50000;
      case ServiceCategory.electricidad:
        return 60000;
      case ServiceCategory.cerrajeria:
        return 40000;
      case ServiceCategory.aseo:
        return 80000;
      case ServiceCategory.pintura:
        return 15000; // por m²
      case ServiceCategory.camaras:
        return 150000;
      case ServiceCategory.computadores:
        return 50000;
      case ServiceCategory.enchape:
        return 20000; // por m²
    }
  }

  /// Rango de precio máximo sugerido (COP).
  int get suggestedPriceMax {
    switch (this) {
      case ServiceCategory.plomeria:
        return 300000;
      case ServiceCategory.electricidad:
        return 400000;
      case ServiceCategory.cerrajeria:
        return 200000;
      case ServiceCategory.aseo:
        return 250000;
      case ServiceCategory.pintura:
        return 40000;
      case ServiceCategory.camaras:
        return 800000;
      case ServiceCategory.computadores:
        return 300000;
      case ServiceCategory.enchape:
        return 60000;
    }
  }

  /// Unidad de cobro sugerida.
  String get suggestedUnit {
    switch (this) {
      case ServiceCategory.plomeria:
        return 'por servicio';
      case ServiceCategory.electricidad:
        return 'por servicio';
      case ServiceCategory.cerrajeria:
        return 'por servicio';
      case ServiceCategory.aseo:
        return 'por servicio';
      case ServiceCategory.pintura:
        return 'por m²';
      case ServiceCategory.camaras:
        return 'por instalación';
      case ServiceCategory.computadores:
        return 'por servicio';
      case ServiceCategory.enchape:
        return 'por m²';
    }
  }

  /// Convierte un String (guardado en Firestore) a enum.
  static ServiceCategory? fromKey(String key) {
    return ServiceCategory.values.where((c) => c.key == key).firstOrNull;
  }
}

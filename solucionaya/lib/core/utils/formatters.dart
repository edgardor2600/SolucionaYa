import 'package:intl/intl.dart';

/// Formateadores de texto para datos de la app.
/// Centralizar aquí garantiza consistencia visual en toda la UI.
abstract final class AppFormatters {
  // ── Precios en COP ────────────────────────────────────────────

  /// Formatea un entero como moneda colombiana.
  /// Ejemplo: 150000 → "$150.000"
  static String cop(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Formatea un rango de precios.
  /// Ejemplo: (50000, 150000) → "$50.000 – $150.000"
  static String copRange(int min, int max) {
    return '${cop(min)} – ${cop(max)}';
  }

  /// Formato compacto para precios grandes.
  /// Ejemplo: 1500000 → "$1.5M"
  static String copCompact(int amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}k';
    }
    return cop(amount);
  }

  // ── Teléfonos ─────────────────────────────────────────────────

  /// Formatea un teléfono colombiano.
  /// Ejemplo: "3001234567" → "+57 300 123 4567"
  static String phone(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+57 ${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    }
    return digits;
  }

  // ── Fechas ────────────────────────────────────────────────────

  /// Fecha corta: "24 abr 2026"
  static String dateShort(DateTime date) {
    return DateFormat('d MMM yyyy', 'es_CO').format(date);
  }

  /// Fecha larga: "viernes, 24 de abril de 2026"
  static String dateLong(DateTime date) {
    return DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_CO').format(date);
  }

  /// Hora: "3:45 PM"
  static String time(DateTime date) {
    return DateFormat('h:mm a', 'es_CO').format(date);
  }

  /// Fecha y hora: "24 abr · 3:45 PM"
  static String dateTime(DateTime date) {
    return '${dateShort(date)} · ${time(date)}';
  }

  /// Tiempo relativo (para chats y actividad).
  /// Ejemplo: "hace 5 min", "ayer", "hace 3 días"
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return dateShort(date);
  }

  // ── Números ───────────────────────────────────────────────────

  /// Calificación con 1 decimal: 4.8
  static String rating(double value) => value.toStringAsFixed(1);

  /// Cuenta compacta: 1000 → "1k reseñas"
  static String reviewCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k reseñas';
    return '$count ${count == 1 ? 'reseña' : 'reseñas'}';
  }

  /// Distancia en km.
  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}

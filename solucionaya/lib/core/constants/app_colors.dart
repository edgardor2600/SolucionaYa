import 'package:flutter/material.dart';

/// Paleta de colores oficial de SolucionaYa.
/// Todos los colores de la app deben provenir de esta clase.
abstract final class AppColors {
  // ── Colores de marca ─────────────────────────────────────────
  static const Color primary = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFF4C8FFF);
  static const Color primaryDark = Color(0xFF003A99);

  static const Color secondary = Color(0xFFFF6B00);
  static const Color secondaryLight = Color(0xFFFF9A4D);
  static const Color secondaryDark = Color(0xFFCC5500);

  // ── Estados ──────────────────────────────────────────────────
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // ── Superficies ───────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // ── Textos ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Bordes ────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF2C2C2C);

  // ── Categorías de servicio ────────────────────────────────────
  static const Color plomeria = Color(0xFF1565C0);
  static const Color electricidad = Color(0xFFF57F17);
  static const Color cerrajeria = Color(0xFF4E342E);
  static const Color aseo = Color(0xFF00897B);
  static const Color pintura = Color(0xFF6A1B9A);
  static const Color camaras = Color(0xFF1B5E20);
  static const Color computadores = Color(0xFF0277BD);
  static const Color enchape = Color(0xFF558B2F);

  // ── Degradados ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF003A99), Color(0xFF0052CC), Color(0xFF1A6FE0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Opacidades de uso común ───────────────────────────────────
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);

  static Color errorWithOpacity(double opacity) => error.withValues(alpha: opacity);
}

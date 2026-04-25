/// Dimensiones, espaciados y radios usados en toda la app.
/// Evitar valores mágicos en los widgets.
abstract final class AppDimensions {
  // ── Padding / Margin ──────────────────────────────────────────
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ── Radio de bordes ───────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ── Elevación (sombras) ───────────────────────────────────────
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;

  // ── Altura de componentes ─────────────────────────────────────
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double categoryCardHeight = 90.0;
  static const double workerCardHeight = 120.0;
  static const double thumbnailSize = 80.0;

  // ── Tamaño de íconos ──────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Avatares ──────────────────────────────────────────────────
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 72.0;
  static const double avatarXl = 120.0;

  // ── Tipografía ────────────────────────────────────────────────
  static const double fontXs = 12.0;
  static const double fontSm = 14.0;
  static const double fontMd = 16.0;
  static const double fontLg = 18.0;
  static const double fontXl = 20.0;
  static const double fontXxl = 24.0;
  static const double fontDisplay = 28.0;

  // ── Padding de pantalla ───────────────────────────────────────
  static const double screenHorizontalPadding = 20.0;
  static const double screenVerticalPadding = 24.0;

  // ── Límites de contenido ──────────────────────────────────────
  static const int maxGalleryPhotos = 12;
  static const int maxCategories = 3;
  static const int bioMaxLength = 300;
  static const int minNameLength = 3;
}

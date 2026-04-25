/// Todas las rutas nombradas de la aplicación SolucionaYa.
/// Centralizar rutas evita strings mágicos dispersos por el código.
abstract final class AppRoutes {
  // ── Auth / Onboarding ─────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String selectRole = '/select-role';
  static const String registerPhone = '/register/phone';
  static const String registerOtp = '/register/otp';
  static const String registerProfile = '/register/profile';
  static const String registerWorkerCategories = '/register/worker/categories';
  static const String registerWorkerDocs = '/register/worker/docs';
  static const String workerPending = '/worker/pending';
  static const String loginEmail = '/login/email';

  // ── Cliente ───────────────────────────────────────────────────
  static const String clientHome = '/client/home';
  static const String clientExplore = '/client/explore';
  static const String clientChats = '/client/chats';
  static const String clientProfile = '/client/profile';
  static const String clientFavorites = '/client/favorites';

  // ── Trabajador ────────────────────────────────────────────────
  static const String workerHome = '/worker/home';
  static const String workerActivity = '/worker/activity';
  static const String workerChats = '/worker/chats';
  static const String workerStats = '/worker/stats';
  static const String workerEditProfile = '/worker/edit-profile';
  static const String workerPrices = '/worker/prices';
  static const String workerGallery = '/worker/gallery';
  static const String workerSchedule = '/worker/schedule';

  // ── Compartidas ───────────────────────────────────────────────
  static const String workerProfileDetail = '/worker/:workerId';
  static const String chatDetail = '/chat/:chatId';
  static const String galleryViewer = '/gallery-viewer';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  // ── Admin ─────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminWorkers = '/admin/workers';
  static const String adminWorkerDetail = '/admin/workers/:workerId';
  static const String adminReports = '/admin/reports';
  static const String adminCategories = '/admin/categories';

  // ── Deep links / Perfil público ───────────────────────────────
  static const String publicWorkerProfile = '/p/:slug';

  // ── Helper para rutas con parámetros ─────────────────────────
  static String workerDetail(String workerId) => '/worker/$workerId';
  static String chat(String chatId) => '/chat/$chatId';
  static String adminWorkerDetailPath(String workerId) =>
      '/admin/workers/$workerId';
  static String publicProfile(String slug) => '/p/$slug';
}

/// Centralización de todas las rutas nombradas de la aplicación.
/// Usar siempre estas constantes — nunca strings literales en el código.
class AppRoutes {
  AppRoutes._();

  // ── Auth ────────────────────────────────────────────────────────
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const selectRole = '/select-role';
  static const loginEmail = '/login';
  static const registerEmail = '/register/email';
  static const registerPhone = '/register/phone';
  static const registerOtp = '/register/otp';
  static const registerProfile = '/register/profile';
  static const registerWorkerDocs = '/register/worker/docs';
  static const workerPending = '/worker/pending';

  // ── Cliente ─────────────────────────────────────────────────────
  static const clientHome = '/client/home';
  static const clientExplore = '/client/explore';
  static const clientChats = '/client/chats';
  static const clientProfile = '/client/profile';

  // ── Trabajador ──────────────────────────────────────────────────
  static const workerHome = '/worker/home';
  static const workerActivity = '/worker/activity';
  static const workerChats = '/worker/chats';
  static const workerStats = '/worker/stats';
  static const workerEditProfile = '/worker/edit-profile';
  static const workerPrices = '/worker/prices';
  static const workerGallery = '/worker/gallery';
  static const workerSchedule = '/worker/schedule';

  // ── Compartidas ─────────────────────────────────────────────────
  static const workerProfileDetail = '/worker/:workerId';
  static const chatDetail = '/chat/:chatId';
  static const galleryViewer = '/gallery-viewer';

  // ── Admin ────────────────────────────────────────────────────────
  static const adminDashboard = '/admin/dashboard';
  static const adminWorkers = '/admin/workers';
  static const adminWorkerDetail = '/admin/workers/:workerId';
  static const adminReports = '/admin/reports';
  static const adminCategories = '/admin/categories';

  // ── Helpers de rutas con parámetros ─────────────────────────────
  static String workerDetail(String workerId) => '/worker/$workerId';
  static String chat(String chatId) => '/chat/$chatId';
  static String adminWorkerDetails(String workerId) =>
      '/admin/workers/$workerId';
}

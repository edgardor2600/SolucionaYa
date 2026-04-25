/// Textos y copys de la interfaz de SolucionaYa.
/// Centralizar aquí facilita futuras traducciones (i18n).
abstract final class AppStrings {
  // ── App ───────────────────────────────────────────────────────
  static const String appName = 'SolucionaYa';
  static const String appTagline =
      'Conecta con técnicos verificados al instante';

  // ── Auth ──────────────────────────────────────────────────────
  static const String welcomeBack = 'Bienvenido de vuelta';
  static const String createAccount = 'Crear cuenta';
  static const String signIn = 'Iniciar sesión';
  static const String signOut = 'Cerrar sesión';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String email = 'Correo electrónico';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar contraseña';
  static const String phone = 'Número de teléfono';
  static const String enterOtp = 'Ingresa el código de verificación';
  static const String resendCode = 'Reenviar código';
  static const String sendCode = 'Enviar código';
  static const String verifyCode = 'Verificar código';

  // ── Roles ─────────────────────────────────────────────────────
  static const String iNeedService = 'Necesito un servicio';
  static const String iOfferService = 'Ofrezco mis servicios';
  static const String clientDescription =
      'Encuentra técnicos verificados cerca de ti';
  static const String workerDescription =
      'Publica tu perfil y consigue más clientes';

  // ── Perfil ────────────────────────────────────────────────────
  static const String fullName = 'Nombre completo';
  static const String city = 'Ciudad';
  static const String bio = 'Descripción (bio)';
  static const String experience = 'Años de experiencia';
  static const String workRadius = 'Radio de trabajo (km)';
  static const String whatsapp = 'Número de WhatsApp';
  static const String profilePhoto = 'Foto de perfil';
  static const String saveChanges = 'Guardar cambios';
  static const String editProfile = 'Editar perfil';

  // ── Categorías ────────────────────────────────────────────────
  static const String plomeria = 'Plomería';
  static const String electricidad = 'Electricidad';
  static const String cerrajeria = 'Cerrajería';
  static const String aseo = 'Aseo';
  static const String pintura = 'Pintura';
  static const String camaras = 'Cámaras';
  static const String computadores = 'Computadores';
  static const String enchape = 'Enchape';

  // ── Ciudades ──────────────────────────────────────────────────
  static const List<String> availableCities = [
    'Bucaramanga',
    'Floridablanca',
    'Piedecuesta',
    'Girón',
    'Barrancabermeja',
  ];

  // ── Errores comunes ───────────────────────────────────────────
  static const String errorGeneric = 'Ocurrió un error. Intenta de nuevo.';
  static const String errorNetwork =
      'Sin conexión a internet. Verifica tu red.';
  static const String errorNotFound = 'No encontrado.';
  static const String errorInvalidPhone = 'Número de teléfono inválido.';
  static const String errorInvalidEmail =
      'Correo electrónico inválido.';
  static const String errorWeakPassword =
      'La contraseña debe tener al menos 8 caracteres.';
  static const String errorPasswordsNoMatch = 'Las contraseñas no coinciden.';
  static const String errorOtpInvalid = 'Código incorrecto. Intenta de nuevo.';
  static const String errorOtpExpired =
      'El código expiró. Solicita uno nuevo.';

  // ── Vacíos ────────────────────────────────────────────────────
  static const String emptyWorkers =
      'No encontramos técnicos disponibles en tu zona.';
  static const String emptyChats = 'Aún no tienes conversaciones.';
  static const String emptyReviews = 'Sin reseñas todavía.';
  static const String emptyGallery = 'No hay fotos en la galería.';
  static const String emptyPrices = 'No has agregado precios aún.';

  // ── Acciones ──────────────────────────────────────────────────
  static const String retry = 'Reintentar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String next = 'Siguiente';
  static const String skip = 'Omitir';
  static const String done = 'Listo';
  static const String back = 'Volver';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String add = 'Agregar';
  static const String upload = 'Subir foto';
  static const String share = 'Compartir';
  static const String accept = 'Aceptar';
  static const String reject = 'Rechazar';

  // ── Disponibilidad ────────────────────────────────────────────
  static const String availableNow = 'Disponible ahora';
  static const String notAvailable = 'No disponible';
  static const String toggleAvailability = 'Cambiar disponibilidad';

  // ── Verificación ──────────────────────────────────────────────
  static const String verified = 'Verificado';
  static const String pendingVerification = 'Pendiente de verificación';
  static const String pendingTitle = '¡Ya casi!';
  static const String pendingDescription =
      'Estamos revisando tu documentación. Tu perfil estará activo en máximo 24 horas.';
}

PLAN DE DESARROLLO DIARIO — SOLUCIONAYA
Para el desarrollador — Guía incremental completa
16 semanas · 80 días laborales · De cero a app publicada

REGLAS DE ORO ANTES DE EMPEZAR

Nunca avances al día siguiente si el día actual tiene algo roto. Cada día construye sobre el anterior.
Usa el Emulador de Firebase para todo el desarrollo. Solo conectas a producción en la Semana 16.
Commit en Git al final de cada día con mensaje descriptivo. Rama main solo cuando está estable.
No te saltes el diseño en Figma. Diseñar antes de codear ahorra el triple de tiempo.
Cada funcionalidad tiene su test. Si no lo pruebas, está roto.

SEMANA 1 — SETUP COMPLETO DEL PROYECTO
DÍA 1 — Firebase + Proyecto Flutter
Objetivo: Tener el esqueleto del proyecto corriendo en tu máquina.
Firebase (1h):

Ir a console.firebase.google.com
Crear proyecto: solucionaya-mvp
Activar servicios en este orden exacto:

Authentication → Proveedores: Email/Contraseña ✓ y Teléfono ✓
Firestore Database → Crear en modo TEST (luego cambias las reglas)
Storage → Crear en modo TEST
Hosting → Activar (para el Admin Panel web)
Analytics → Activar
Crashlytics → Activar
App Check → NO activar aún (lo haces en semana 11)

Flutter (2h):
bash# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Crear proyecto

flutter create solucionaya --org com.solucionaya --platforms android,ios,web

# Entrar al proyecto

cd solucionaya

# Conectar con Firebase

flutterfire configure

# → selecciona proyecto solucionaya-mvp

# → plataformas: Android, iOS, Web

# → esto genera google-services.json, GoogleService-Info.plist y firebase_options.dart

Git (30min):
bashgit init
git add .
git commit -m "feat: proyecto inicial Flutter + Firebase configurado"

# Crear repo en GitHub/GitLab y conectar

git remote add origin [URL_REPO]
git push -u origin main
Verificación del día:

flutter run → App vacía corre en Android/iOS sin errores
Firebase Console muestra el proyecto conectado

DÍA 2 — Estructura de carpetas + pubspec.yaml
Objetivo: Crear la arquitectura Clean Architecture feature-first con todas las dependencias.
pubspec.yaml — agregar todas las dependencias:
yamldependencies:
flutter:
sdk: flutter

# Firebase

firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_storage: ^12.3.2
firebase_messaging: ^15.1.3
firebase_analytics: ^11.3.3
firebase_crashlytics: ^4.1.3
firebase_app_check: ^0.3.1+3

# Estado

flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5

# Navegación

go_router: ^14.3.0

# UX / Animaciones

flutter_animate: ^4.5.0
shimmer: ^3.0.0
lottie: ^3.1.0
cached_network_image: ^3.4.1

# Chat

flutter_chat_ui: ^2.0.0
flutter_chat_types: ^3.6.2
image_picker: ^1.1.2

# Mapas y ubicación

google_maps_flutter: ^2.9.0
geolocator: ^13.0.1
geocoding: ^3.0.0

# Utilidades

intl: ^0.19.0
url_launcher: ^6.3.1
share_plus: ^10.0.0
package_info_plus: ^8.1.0
connectivity_plus: ^6.0.6
uuid: ^4.5.1
image: ^4.2.0
flutter_image_compress: ^2.3.0
path_provider: ^2.1.4
shared_preferences: ^2.3.3

dev_dependencies:
flutter_test:
sdk: flutter
flutter_lints: ^4.0.0
riverpod_generator: ^2.4.3
build_runner: ^2.4.13
mocktail: ^1.0.4
fake_cloud_firestore: ^3.0.2
Estructura de carpetas (crear todas vacías con .gitkeep):
lib/
core/
constants/
app_colors.dart
app_strings.dart
app_routes.dart
app_dimensions.dart
theme/
app_theme.dart
dark_theme.dart
utils/
validators.dart
formatters.dart
date_helpers.dart
price_helpers.dart
widgets/
app_button.dart
app_text_field.dart
loading_widget.dart
error_widget.dart
empty_state_widget.dart
features/
auth/
data/
domain/
presentation/
screens/
widgets/
providers/
home/
presentation/
screens/
widgets/
providers/
explore/
worker_profile/
chat/
reviews/
favorites/
payments/
admin/
notifications/
settings/
data/
models/
repositories/
services/
main.dart
app.dart
firebase_options.dart
Verificación del día:

flutter pub get sin errores
Estructura de carpetas creada
Commit: "chore: estructura Clean Architecture + dependencias completas"

DÍA 3 — Tema global, colores y componentes base
Objetivo: Tener el sistema de diseño en código antes de cualquier pantalla.
lib/core/constants/app_colors.dart:
dartimport 'package:flutter/material.dart';

class AppColors {
AppColors.\_();

static const primary = Color(0xFF0052CC);
static const secondary = Color(0xFFFF6B00);
static const success = Color(0xFF00C853);
static const warning = Color(0xFFFFB300);
static const error = Color(0xFFD32F2F);

static const surfaceLight = Color(0xFFF8F9FA);
static const surfaceDark = Color(0xFF121212);

static const textPrimary = Color(0xFF1F1F1F);
static const textSecondary = Color(0xFF757575);

// Categorías
static const plomeria = Color(0xFF1565C0);
static const electricidad = Color(0xFFF57F17);
static const cerrajeria = Color(0xFF4E342E);
static const aseo = Color(0xFF00897B);
static const pintura = Color(0xFF6A1B9A);
static const camaras = Color(0xFF1B5E20);
static const computadores = Color(0xFF0277BD);
static const enchape = Color(0xFF558B2F);
}
lib/core/theme/app_theme.dart: Crear MaterialTheme 3 completo con:

colorScheme basado en AppColors.primary
useMaterial3: true
fontFamily: 'Inter'
Configurar Inter en pubspec.yaml → fonts:
Descargar Inter desde Google Fonts y agregar a assets/fonts/
CardTheme: elevación 2, bordes 16 dp
ElevatedButtonTheme: altura 56, bordes 12 dp
InputDecorationTheme: bordes redondeados 12 dp

lib/core/widgets/app_button.dart: Widget reutilizable con estados: normal, loading, disabled.
lib/app.dart: MaterialApp.router con go_router básico + Riverpod ProviderScope.
Agregar fuente Inter en pubspec.yaml y descargar archivos .ttf.
Verificación del día:

La app corre con el tema aplicado
Los colores de categorías están definidos
Commit: "feat: design system completo - colores, tema, componentes base"

DÍA 4 — Firebase Emulator Suite
Objetivo: Desarrollo 100% local, sin tocar datos de producción.
Instalar Firebase CLI:
bashnpm install -g firebase-tools
firebase login
cd [tu_proyecto]
firebase init emulators

# Seleccionar: Authentication, Firestore, Storage, Functions (aunque no uses Functions)

# Puertos por defecto están bien

firebase.json — configurar emuladores:
json{
"emulators": {
"auth": { "port": 9099 },
"firestore": { "port": 8080 },
"storage": { "port": 9199 },
"ui": { "enabled": true, "port": 4000 }
}
}
lib/main.dart — conectar a emuladores en modo debug:
dartif (kDebugMode) {
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
Script de arranque (agregar a README):
bash# Terminal 1: emuladores
firebase emulators:start

# Terminal 2: app

flutter run
Semilla de datos de prueba (crear test_data/seed.sh): Script que agrega via REST API de Firestore Emulator:

3 categorías de prueba
2 trabajadores de prueba
1 cliente de prueba

Verificación del día:

firebase emulators:start → UI disponible en localhost:4000
La app conecta al emulador (verificar en la UI del emulador)
Commit: "feat: Firebase Emulator Suite configurado"

DÍA 5 — Figma: Sistema de diseño + primeras 8 pantallas
Objetivo: Tener el diseño de referencia antes de codear las pantallas. (Día completo en Figma)
En Figma, crear:
Página 1: Design System

Paleta de colores (todos los tokens)
Tipografía: Inter en todos los tamaños (28/24/20/18/16/14/12)
Componentes: botón primario, secundario, campo de texto, card de trabajador, badge verificado, toggle disponible, chip de categoría, bottom sheet base, skeleton loader

Página 2: Pantallas — Flujo de Auth

Splash Screen (logo centrado, fondo azul)
Onboarding Slide 1 (mapa con pins)
Onboarding Slide 2 (lista de precios)
Onboarding Slide 3 (badge verificado)
Onboarding Slide 4 (CTA registro)
Elegir Rol (2 tarjetas grandes)
Registro Teléfono (campo + botón)
Registro OTP (6 dígitos)

Página 3: Pantallas — Cliente 9. Home (buscador + grid categorías + carrusel) 10. Explorar (barra búsqueda + filtros + lista) 11. Perfil Trabajador (completo) 12. Chat (conversación) 13. Mi Perfil Cliente
Página 4: Pantallas — Trabajador 14. Home Trabajador (Mi Perfil con toggle) 15. Editar Perfil 16. Mis Precios (lista + agregar) 17. Mis Estadísticas
Verificación del día:

17 pantallas diseñadas
Sistema de diseño completo y consistente
Compartir link de Figma (read-only)

SEMANA 2 — FIGMA + RUTAS + MODELOS
DÍA 6 — Figma: Pantallas restantes
Diseñar en Figma: 18. Admin Dashboard 19. Admin Lista Trabajadores 20. Admin Detalle Trabajador (aprobar/rechazar) 21. Onboarding Trabajador post-aprobación 22. Galería (viewer full-screen) 23. Bottom Sheet Filtros 24. Bottom Sheet Calificación 25. Pantalla Pago Wompi 26. Éxito de Pago 27. Error de Pago 28. Empty States (3 variantes: sin resultados, sin chats, error de red) 29. Estados de carga (skeleton loaders para Home y Explorar)
Total: 29 pantallas diseñadas al finalizar la semana 1-2.

DÍA 7 — Modelos de datos Dart
Objetivo: Todos los modelos con fromJson/toJson listos.
Crear en lib/data/models/:
user_model.dart:
dartclass UserModel {
final String uid;
final String role; // 'client' | 'worker' | 'admin'
final String displayName;
final String? photoUrl;
final String phone;
final String? email;
final String city;
final DateTime createdAt;
final DateTime lastActiveAt;
final bool isActive;
final bool isSuspended;
final String? suspendedReason;
final List<String> fcmTokens;
final DateTime? acceptedTermsAt;

// Constructor, fromJson, toJson, copyWith
}
worker_profile_model.dart: Todos los campos del plan maestro incluyendo availableSchedule, profileCompleteness, responseTimeMinutes, shareableSlug.
price_model.dart: serviceId, serviceType, category, unit, priceMin, priceMax, currency, notes, isActive.
gallery_photo_model.dart: photoId, url, thumbnailUrl, caption, category, order.
review_model.dart: Todos los campos incluyendo workerReply y workerReplyAt.
chat_model.dart: Todos los campos incluyendo paymentStatus y canReview.
message_model.dart: messageId, senderUid, type (enum), text, imageUrl, location, paymentData, sentAt, readAt.
category_model.dart: Configuración global de categorías.
report_model.dart: Todos los campos del plan maestro.
Verificación del día:

Todos los modelos tienen fromJson, toJson, copyWith
Test unitario básico para cada modelo (serialización/deserialización)
Commit: "feat: modelos de datos completos con tests"

DÍA 8 — Sistema de rutas con go_router
Objetivo: Navegación completa con protección por rol.
lib/core/constants/app_routes.dart:
dartclass AppRoutes {
static const splash = '/';
static const onboarding = '/onboarding';
static const selectRole = '/select-role';
static const registerPhone = '/register/phone';
static const registerOtp = '/register/otp';
static const registerProfile = '/register/profile';
static const registerWorkerDocs = '/register/worker/docs';
static const workerPending = '/worker/pending';

// Cliente
static const clientHome = '/client/home';
static const clientExplore = '/client/explore';
static const clientChats = '/client/chats';
static const clientProfile = '/client/profile';

// Trabajador
static const workerHome = '/worker/home';
static const workerActivity = '/worker/activity';
static const workerChats = '/worker/chats';
static const workerStats = '/worker/stats';
static const workerEditProfile = '/worker/edit-profile';
static const workerPrices = '/worker/prices';
static const workerGallery = '/worker/gallery';

// Compartidos
static const workerProfileDetail = '/worker/:workerId';
static const chatDetail = '/chat/:chatId';
static const galleryViewer = '/gallery-viewer';

// Admin
static const adminDashboard = '/admin/dashboard';
static const adminWorkers = '/admin/workers';
static const adminWorkerDetail = '/admin/workers/:workerId';
static const adminReports = '/admin/reports';
static const adminCategories = '/admin/categories';
}
lib/app.dart: Configurar GoRouter con:

redirect → chequea sesión y rol → redirige al home correcto
Guards por rol (cliente no puede entrar a rutas de admin)
ShellRoute para el bottom navigation de cada rol
Manejo de deep links (/p/:slug)

Verificación del día:

La navegación básica entre pantallas vacías funciona
El guard de roles redirige correctamente
Commit: "feat: sistema de rutas completo con guards por rol"

DÍA 9 — Repositorios base + Auth Provider
Objetivo: Capa de abstracción entre Firestore y la UI.
lib/data/repositories/auth_repository.dart:
dartabstract class AuthRepository {
Stream<UserModel?> get authStateChanges;
Future<void> signInWithPhone(String phone);
Future<UserCredential> verifyOtp(String verificationId, String otp);
Future<void> signInWithEmail(String email, String password);
Future<void> signOut();
Future<void> deleteAccount();
}

class FirebaseAuthRepository implements AuthRepository {
// Implementación completa con FirebaseAuth
}
lib/data/repositories/user_repository.dart:
dartabstract class UserRepository {
Future<UserModel?> getUser(String uid);
Future<void> createUser(UserModel user);
Future<void> updateUser(String uid, Map<String, dynamic> data);
Future<void> updateFcmToken(String uid, String token);
Stream<UserModel?> watchUser(String uid);
}
lib/features/auth/presentation/providers/auth_provider.dart: Riverpod provider que expone el estado de autenticación global.
Verificación del día:

Los repositorios tienen interface + implementación Firebase
El auth provider detecta cambios de sesión
Commit: "feat: repositorios base y auth provider"

DÍA 10 — Workers Repository + Categories Repository
Objetivo: Los repositorios más importantes del dominio.
lib/data/repositories/worker_repository.dart:
dartabstract class WorkerRepository {
Future<WorkerProfileModel?> getWorkerProfile(String uid);
Future<void> createWorkerProfile(WorkerProfileModel profile);
Future<void> updateWorkerProfile(String uid, Map<String, dynamic> data);
Future<void> toggleAvailability(String uid, bool available);
Future<List<WorkerProfileModel>> getWorkersByCategory(
String category, {
String? city,
bool? availableNow,
bool? verifiedOnly,
double? maxPriceMin,
double? minRating,
});
Stream<WorkerProfileModel?> watchWorkerProfile(String uid);
Future<void> incrementProfileViews(String uid);

// Precios
Future<List<PriceModel>> getPrices(String uid);
Future<void> addPrice(String uid, PriceModel price);
Future<void> updatePrice(String uid, PriceModel price);
Future<void> deletePrice(String uid, String priceId);

// Galería
Future<List<GalleryPhotoModel>> getGallery(String uid);
Future<void> addPhoto(String uid, GalleryPhotoModel photo);
Future<void> deletePhoto(String uid, String photoId);
Future<void> reorderPhotos(String uid, List<String> orderedIds);
}
lib/data/repositories/categories_repository.dart: Leer categorías desde Firestore + caché local.
Seed inicial de categorías en Firestore Emulator: Crear las 8 categorías del plan maestro con precios sugeridos.
Verificación del día:

Repositorios de workers y categorías con implementación Firebase
Datos de prueba en el emulador
Commit: "feat: worker y categories repositories completos"

SEMANA 3 — AUTENTICACIÓN COMPLETA
DÍA 11 — Splash Screen + Onboarding
Pantallas a crear:
lib/features/auth/presentation/screens/splash_screen.dart:

Logo con flutter_animate: fade + scale en 0.8s
Verificar sesión con ref.watch(authProvider)
Si hay sesión → ir al home del rol
Si no → ir a onboarding (primera vez) o login

lib/features/auth/presentation/screens/onboarding_screen.dart:

PageView con 4 slides
Cada slide: ilustración Lottie + título + descripción
Indicadores de posición (dots)
Botón "Siguiente" / "Comenzar" en el último slide
Botón "Omitir" en los primeros 3
Guardar "ya vio el onboarding" en SharedPreferences

Assets Lottie: Descargar de lottiefiles.com animaciones gratuitas para:

Mapa con pin
Lista de precios
Badge de verificación
Celebración/confetti

Verificación del día:

Splash funciona con redirección correcta
Onboarding completo con todos los slides
Commit: "feat: splash screen y onboarding completos"

DÍA 12 — Pantalla de selección de rol + Registro Teléfono
lib/features/auth/presentation/screens/select_role_screen.dart:

Dos tarjetas grandes con ícono, título y descripción
Tarjeta 1: "Necesito un servicio" (ícono: casa)
Tarjeta 2: "Ofrezco mis servicios" (ícono: maletín de herramientas)
Al seleccionar: guarda el rol en el provider y navega a registro

lib/features/auth/presentation/screens/register_phone_screen.dart:

Campo de teléfono con prefijo +57 (Colombia)
Validación: exactamente 10 dígitos
Botón "Enviar código"
Loading state mientras llama a Firebase Auth
Manejo de error: "Número inválido", "Error de red"
Botón secundario: "¿Prefieres usar email?"

lib/features/auth/presentation/providers/register_provider.dart:

Estado: registrationRole, phoneVerificationId, currentStep
Método sendOtp(phone) → llama Firebase Auth → guarda verificationId

Verificación del día:

Flujo hasta el envío del OTP funciona con el emulador
La selección de rol se guarda correctamente
Commit: "feat: selección de rol y registro con teléfono"

DÍA 13 — Pantalla OTP + Registro con Email
lib/features/auth/presentation/screens/register_otp_screen.dart:

6 campos de 1 dígito (auto-foco entre campos)
Auto-submit cuando se completan los 6 dígitos
Timer de 60 segundos para reenviar
Botón "Reenviar código" (deshabilitado hasta que expire el timer)
Manejo de error: "Código incorrecto", "Código expirado"
Loading state durante la verificación

lib/features/auth/presentation/screens/register_email_screen.dart:

Email + contraseña + confirmar contraseña
Validaciones: email válido, contraseña mínimo 8 caracteres, coinciden

Lógica post-verificación:

Si es nuevo usuario → ir a register_profile_screen
Si es usuario existente → ir al home de su rol

Verificación del día:

OTP funciona completamente con el emulador de Firebase Auth
El emulador de Firebase Auth muestra el código OTP en la UI
Commit: "feat: verificación OTP y registro email completos"

DÍA 14 — Registro de perfil básico (Cliente)
lib/features/auth/presentation/screens/register_profile_screen.dart:

Foto de perfil (opcional para clientes): image_picker → compresión → Storage
Nombre completo (validación: mínimo 3 caracteres)
Ciudad: Dropdown con "Bucaramanga" y "Barrancabermeja"
Checkbox de política de privacidad (obligatorio)
Al confirmar: crear documento en users/{uid} en Firestore

Compresión de imagen (lib/core/utils/image_utils.dart):
dartFuture<Uint8List> compressImage(File file) async {
return await FlutterImageCompress.compressWithFile(
file.path,
quality: 80,
minWidth: 400,
minHeight: 400,
);
}
Upload a Storage:
dart// path: profile_photos/{uid}/profile.jpg
Future<String> uploadProfilePhoto(String uid, Uint8List bytes) async {
final ref = FirebaseStorage.instance.ref('profile_photos/$uid/profile.jpg');
await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
return await ref.getDownloadURL();
}
Post-registro cliente: Navega a clientHome.
Verificación del día:

El cliente puede completar su registro completo
El documento users/{uid} se crea correctamente en Firestore
La foto se sube a Storage
Commit: "feat: registro completo de cliente"

DÍA 15 — Registro de Trabajador (categorías + documentos)
lib/features/auth/presentation/screens/register_worker_categories_screen.dart:

Grid de las 8 categorías con checkbox
Selección múltiple
Mínimo 1 categoría obligatoria
Máximo 3 categorías (para enfoque y calidad)

lib/features/auth/presentation/screens/register_worker_docs_screen.dart:

Instrucciones claras: "Necesitamos verificar tu identidad"
Foto de cédula FRENTE (obligatoria)
Upload a Storage: id_documents/{uid}/cedula_frente.jpg
Mensaje informativo: "Tu perfil estará activo en máximo 24 horas"
Al confirmar: crear worker_profiles/{uid} con verified: false

Pantalla de estado pendiente (worker_pending_screen.dart):

Ilustración de reloj/espera (Lottie)
Título: "¡Ya casi!"
Descripción del proceso de verificación
Tiempo estimado: "antes de las próximas 24 horas"
Stream que escucha worker_profiles/{uid}/verified → cuando sea true, navega al home

Crear Admin en Firestore Emulator (para pruebas):

Documento en users/admin_test_uid con role: 'admin'
Custom claim admin: true en Firebase Auth emulator

Verificación del día:

El trabajador completa el registro completo incluyendo la cédula
El documento worker_profiles/{uid} se crea con verified: false
La foto de cédula está en Storage
Commit: "feat: registro completo de trabajador con documentos"

SEMANA 4 — PERFIL DEL TRABAJADOR (Creación y Edición)
DÍA 16 — Home del Trabajador Aprobado
Flujo de aprobación (simular desde Firebase Emulator UI):

Abrir localhost:4000 (Emulator UI)
Ir a Firestore → worker_profiles/{uid}
Cambiar verified a true y verifiedAt a timestamp actual

lib/features/worker_profile/presentation/screens/worker_home_screen.dart:

Scaffold con BottomNavigationBar (4 tabs: Mi Perfil, Actividad, Chats, Estadísticas)
Tab 1 (Mi Perfil): Card de vista previa del perfil
Toggle grande "DISPONIBLE AHORA" (prominente, naranja cuando activo)
Barra de progreso de completitud
Lista de ítems faltantes
Banner de "¡Tu perfil fue aprobado!" si es primera vez

Lógica del Toggle "Disponible ahora":
dartFuture<void> toggleAvailability(String uid, bool value) async {
await FirebaseFirestore.instance
.doc('worker_profiles/$uid')
.update({'availableNow': value, 'lastSeenAt': FieldValue.serverTimestamp()});
}

// Auto-apagado a las 8 horas (client-side con Timer)
void scheduleAutoOff(String uid) {
Timer(const Duration(hours: 8), () async {
await toggleAvailability(uid, false);
});
}
Verificación del día:

El trabajador aprobado ve su home con el toggle
El toggle actualiza Firestore en tiempo real
Commit: "feat: home del trabajador con toggle disponibilidad"

DÍA 17 — Edición de Perfil del Trabajador (Datos básicos)
lib/features/worker_profile/presentation/screens/worker_edit_profile_screen.dart:

Foto de perfil (editable)
Nombre completo
Bio (máx 300 caracteres, contador visible)
Años de experiencia (dropdown: 1–20+)
Radio de trabajo en km (slider: 1–20 km)
Ciudad
Número de WhatsApp (opcional, validación formato colombiano)
Botón "Guardar cambios"

Cálculo de completitud (lib/core/utils/profile_completeness.dart):
dartint calculateCompleteness(WorkerProfileModel profile, List<PriceModel> prices, List<GalleryPhotoModel> gallery) {
int score = 0;
if (profile.photoUrl != null) score += 15; // Foto
if (profile.bio?.isNotEmpty == true) score += 15; // Bio
if (profile.experienceYears > 0) score += 10; // Experiencia
if (prices.isNotEmpty) score += 20; // Al menos 1 precio
if (gallery.length >= 3) score += 20; // Al menos 3 fotos
if (profile.availableSchedule != null) score += 10; // Horario
if (profile.whatsappNumber != null) score += 10; // WhatsApp
return score;
}
Verificación del día:

El trabajador puede editar y guardar todos sus datos básicos
La completitud se actualiza en tiempo real
Commit: "feat: edición de perfil básico del trabajador"

DÍA 18 — Sistema de Precios (CRUD completo)
lib/features/worker_profile/presentation/screens/worker_prices_screen.dart:

Lista de precios activos con StreamBuilder
Cada ítem: nombre del servicio, rango de precio, unidad, ícono de editar y eliminar
FAB "Agregar precio"

lib/features/worker_profile/presentation/screens/add_edit_price_screen.dart:

Campo: Tipo de servicio (texto libre o seleccionar de sugeridos)
Categoría (dropdown de sus categorías)
Precio mínimo (formato COP con intl)
Precio máximo
Unidad (dropdown: por servicio, por m², por hora, por punto)
Notas (opcional)
Precios sugeridos: al seleccionar categoría, mostrar rangos del plan maestro como ayuda

Formateo de precios colombianos:
dartString formatCOP(int amount) {
final formatter = NumberFormat.currency(
locale: 'es_CO',
symbol: '\$',
decimalDigits: 0,
);
return formatter.format(amount);
}
// Output: $150.000
Verificación del día:

CRUD completo de precios funciona
Los precios se muestran formateados en COP
Los precios sugeridos aparecen como ayuda
Commit: "feat: sistema de precios CRUD completo"

DÍA 19 — Galería de Trabajos
lib/features/worker_profile/presentation/screens/worker_gallery_screen.dart:

Grid 3 columnas con thumbnails
Botón "Agregar foto" (si < 12 fotos)
Al tocar foto: viewer full-screen
Cada foto: toque largo → menú (Editar caption, Eliminar)
Reordenamiento: drag-and-drop con ReorderableGridView

Subida de fotos:
dartFuture<void> uploadGalleryPhoto(String uid, File file, String? caption) async {
// 1. Comprimir imagen
final compressed = await compressImage(file);

// 2. Generar ID único
final photoId = const Uuid().v4();

// 3. Subir imagen original
final ref = FirebaseStorage.instance.ref('gallery/$uid/$photoId.jpg');
await ref.putData(compressed);
final url = await ref.getDownloadURL();

// 4. Generar thumbnail (comprimir más)
final thumb = await FlutterImageCompress.compressWithList(
compressed, quality: 50, minWidth: 150, minHeight: 150
);
final thumbRef = FirebaseStorage.instance.ref('gallery/$uid/thumb_$photoId.jpg');
await thumbRef.putData(thumb);
final thumbUrl = await thumbRef.getDownloadURL();

// 5. Guardar en Firestore
final order = await getNextOrder(uid);
await FirebaseFirestore.instance
.collection('worker_profiles/$uid/gallery')
.doc(photoId)
.set({
'photoId': photoId, 'url': url, 'thumbnailUrl': thumbUrl,
'caption': caption, 'order': order,
'uploadedAt': FieldValue.serverTimestamp()
});

// 6. Actualizar completitud
await updateProfileCompleteness(uid);
}
Gallery Viewer full-screen: PageView con zoom usando InteractiveViewer, flechas de navegación, contador, caption.
Verificación del día:

Subida de fotos funciona con thumbnail automático
Viewer funciona con zoom y deslizamiento
Reordenamiento funciona
Commit: "feat: galería de trabajos completa"

DÍA 20 — Horario de Disponibilidad Semanal
lib/features/worker_profile/presentation/screens/worker_schedule_screen.dart:

Lista de 7 días de la semana
Cada día: toggle para activar/desactivar
Si activo: campos de hora inicio y fin (TimePicker)
Vista previa del horario resultante
Guardar → actualiza availableSchedule en Firestore

Widget de horario para el perfil del cliente:
dartclass ScheduleSummaryWidget extends StatelessWidget {
// Muestra: "Lun–Vie 7am–6pm · Sáb 8am–2pm"
// O cada día con su horario si son diferentes
}
Lógica de "fuera de horario":
dartbool isCurrentlyInSchedule(Map<String, dynamic>? schedule) {
if (schedule == null) return true; // sin horario = siempre disponible
final now = DateTime.now();
final dayKey = ['dom','lun','mar','mie','jue','vie','sab'][now.weekday % 7];
final daySchedule = schedule[dayKey];
if (daySchedule == null) return false;
// Comparar hora actual con from/to
}
Verificación del día:

El trabajador puede configurar su horario semanal
El widget de resumen muestra el horario de forma legible
El aviso de fuera de horario funciona
Commit: "feat: horario de disponibilidad semanal"

SEMANA 5 — PERFIL PÚBLICO + HOME DEL CLIENTE
DÍA 21 — Pantalla de Perfil Público del Trabajador
lib/features/worker_profile/presentation/screens/worker_profile_detail_screen.dart:
Esta es la pantalla más importante del cliente. Construirla en capas:
Capa 1 — Header (ScrollView con SliverAppBar):

SliverAppBar con foto de perfil expandida
Al hacer scroll: se colapsa mostrando nombre en la barra
Nombre, badges, ciudad, calificación, tiempo de respuesta

Capa 2 — Galería horizontal:

ListView.builder horizontal con las fotos
Cada foto: 100x100 dp con borde redondeado
Al tocar: abre viewer

Capa 3 — Disponibilidad:

Toggle visual (no editable)
Horario semanal en mini-tabla
Radio de trabajo

Capa 4 — Sobre mí:

Bio, experiencia, categorías como chips

Capa 5 — Precios:

Lista clara con formato COP
Botón "¿Tienes dudas? Escríbeme"

Capa 6 — Reseñas:

Resumen con barras de distribución (fl_chart)
Primeras 3 reseñas visibles
Botón "Ver todas (47)"

Barra inferior fija:

Chat (primario, azul)
Llamar (si tiene teléfono)
WhatsApp (si tiene número)
Favorito (corazón)

lib/data/services/analytics_service.dart: Registrar vista de perfil + incrementar totalProfileViews en Firestore.
Verificación del día:

El perfil completo del trabajador se ve como en el diseño de Figma
La barra inferior de acciones funciona
Commit: "feat: pantalla de perfil completo del trabajador"

DÍA 22 — Home del Cliente
lib/features/home/presentation/screens/client_home_screen.dart:
Sección superior:
dart// Saludo dinámico
String getGreeting() {
final hour = DateTime.now().hour;
if (hour < 12) return 'Buenos días';
if (hour < 18) return 'Buenas tardes';
return 'Buenas noches';
}
Grid de categorías:

GridView.count(crossAxisCount: 4) → 2 filas × 4 columnas = 8 categorías
Cada tarjeta: ícono grande (56dp), nombre, color de fondo suave
Al tocar: navega a Explorar con esa categoría pre-filtrada

Carrusel "Disponibles ahora":
dartStreamBuilder<List<WorkerProfileModel>>(
stream: workerRepository.watchAvailableNow(city: userCity),
builder: (context, snapshot) {
// Mostrar skeleton loader mientras carga
// Lista horizontal de cards compactas
}
)
Sección "Mejor calificados":

Query: rating >= 4.5 AND verified = true → ordenar por rating desc, limit 5

Banner "Completa tu perfil": Solo si el cliente no tiene foto de perfil.
Verificación del día:

El home del cliente carga con datos reales del emulador
El carrusel de disponibles se actualiza en tiempo real
Commit: "feat: home del cliente con categorías y carruseles"

DÍA 23 — Pantalla Explorar + Filtros
lib/features/explore/presentation/screens/explore_screen.dart:
Barra de búsqueda:

TextField con debounce de 300ms
Busca en nombre del trabajador y categorías

Chips de filtros activos: Fila horizontal scrolleable mostrando filtros aplicados con "×" para eliminarlos individualmente.
Bottom Sheet de Filtros:
dartshowModalBottomSheet(
isScrollControlled: true,
builder: (ctx) => FilterBottomSheet(...)
)

Dropdown de categoría
Toggle "Solo disponibles ahora"
Toggle "Solo verificados"
RangeSlider de distancia (1–20 km)
Slider de precio máximo
Row de estrellas para rating mínimo
Botones: "Aplicar" + "Limpiar todo"

Lista infinita con paginación:
dart// Usar pagination con Firestore startAfterDocument
Future<void> loadMore() async {
if (\_isLoading || !\_hasMore) return;
setState(() => \_isLoading = true);

final query = \_buildQuery()
.startAfterDocument(\_lastDocument!)
.limit(10);

final docs = await query.get();
// Agregar a la lista existente
}
Card del trabajador en lista:

Foto de perfil circular (60dp)
Mini-galería: 3 thumbnails horizontales
Nombre + chips de categorías
Estrellas + número de reseñas
Badge verificado (verde) o en revisión (gris)
Precio mínimo + distancia
Badge "AHORA" si está disponible

Algoritmo de ranking client-side:
dartdouble calculateRankingScore(WorkerProfileModel worker, double? distanceKm) {
double score = 0;
if (worker.availableNow) score += 10;
if (worker.verified) score += 8;
score += (worker.profileCompleteness / 100) _ 10;
score += worker.averageRating;
score += math.log(worker.totalReviews + 1) _ 3;
if (worker.responseTimeMinutes != null && worker.responseTimeMinutes! < 30) score += 2;
// Penalizar por distancia
if (distanceKm != null) score -= distanceKm \* 0.3;
return score;
}
Verificación del día:

La búsqueda y filtros funcionan correctamente
La paginación carga más resultados al hacer scroll
El ranking ordena los resultados según el algoritmo
Commit: "feat: pantalla explorar con búsqueda, filtros y ranking"

DÍA 24 — Favoritos + Perfil del Cliente
lib/features/favorites/ — implementación completa:
Toggle de favorito (en perfil del trabajador):
dartFuture<void> toggleFavorite(String clientUid, String workerUid, bool isFavorite) async {
final ref = FirebaseFirestore.instance
.doc('favorites/$clientUid/items/$workerUid');
if (isFavorite) {
await ref.set({
'workerId': workerUid,
'addedAt': FieldValue.serverTimestamp(),
});
} else {
await ref.delete();
}
}
lib/features/home/presentation/screens/client_profile_screen.dart:

Foto, nombre, ciudad, editar
Grid de favoritos guardados
Historial de chats (lista)
Direcciones guardadas (máx 3: Casa, Trabajo, Otra)
Configuración: notificaciones, tema oscuro, contraseña
Política de privacidad, Términos
Cerrar sesión
"Eliminar mi cuenta" (en configuración, con confirmación)

Verificación del día:

Los favoritos se guardan y eliminan correctamente
El perfil del cliente muestra los favoritos
Commit: "feat: favoritos y perfil del cliente completos"

DÍA 25 — Integración de distancia con Geolocator
lib/data/services/location_service.dart:
dartclass LocationService {
Future<Position?> getCurrentPosition() async {
final permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
final result = await Geolocator.requestPermission();
if (result == LocationPermission.denied) return null;
}
return await Geolocator.getCurrentPosition(
desiredAccuracy: LocationAccuracy.medium,
);
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
}

String formatDistance(double km) {
if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
}
}
Integrar distancia en:

Cards de trabajador en la lista de Explorar
Perfil completo del trabajador
Filtro de distancia máxima

Manejo de permisos: Si el usuario niega el permiso → mostrar distancias como "?" pero no bloquear la app.
Verificación del día:

Las distancias aparecen correctamente en las cards
El filtro de distancia funciona
Commit: "feat: integración de distancia con geolocator"

SEMANA 6 — CHAT EN TIEMPO REAL
DÍA 26 — Estructura del Chat + Lista de Conversaciones
lib/features/chat/data/repositories/chat_repository.dart:
dartabstract class ChatRepository {
String generateChatId(String clientUid, String workerUid);
Future<ChatModel?> getOrCreateChat(String clientUid, String workerUid, String category);
Stream<List<ChatModel>> watchChats(String uid);
Future<void> updateLastMessage(String chatId, String message, String senderUid);
Future<void> markAsRead(String chatId, String readerUid);
Future<void> archiveChat(String chatId);
}

// chatId = "${clientUid}_${workerUid}" (uid más pequeño primero, alfabéticamente)
String generateChatId(String uid1, String uid2) {
final sorted = [uid1, uid2]..sort();
return '${sorted[0]}_${sorted[1]}';
}
lib/features/chat/presentation/screens/chats_list_screen.dart:

StreamBuilder con watchChats(currentUser.uid)
Cada ítem: foto del interlocutor, nombre, preview del último mensaje, hora, badge de no leídos (número en círculo naranja)
Swipe left: opciones "Archivar" y "Reportar"
Estado vacío: "Aún no tienes conversaciones. Encuentra un trabajador y escríbele."

Verificación del día:

La lista de chats se actualiza en tiempo real
Los badges de no leídos aparecen y desaparecen correctamente
Commit: "feat: lista de chats en tiempo real"

DÍA 27 — Chat en Tiempo Real (Texto)
Usar flutter_chat_ui como base y personalizar:
lib/features/chat/presentation/screens/chat_detail_screen.dart:
dartclass ChatDetailScreen extends ConsumerStatefulWidget {
final String chatId;
// ...
}

// Configurar flutter_chat_ui:
Chat(
messages: messages,
onSendPressed: \_handleSend,
user: currentUser,
theme: DefaultChatTheme(
primaryColor: AppColors.primary,
// Personalización según diseño
),
customMessageBuilder: \_buildCustomMessage, // para pagos
)
Repositorio de mensajes:
dartStream<List<types.Message>> watchMessages(String chatId) {
return FirebaseFirestore.instance
.collection('chats/$chatId/messages')
.orderBy('sentAt', descending: true)
.limit(50)
.snapshots()
.map((snap) => snap.docs.map(\_messageFromDoc).toList());
}

Future<void> sendMessage(String chatId, String senderUid, String text) async {
final msgId = const Uuid().v4();
await FirebaseFirestore.instance
.doc('chats/$chatId/messages/$msgId')
.set({
'messageId': msgId,
'senderUid': senderUid,
'type': 'text',
'text': text,
'sentAt': FieldValue.serverTimestamp(),
'readAt': null,
});
// Actualizar lastMessage en el chat padre
await updateLastMessage(chatId, text, senderUid);
}
Header personalizado: Foto del interlocutor + nombre + "última vez activo hace X"
Burbuja de contexto (primera vez que se abre el chat):

Mini-card del trabajador: foto + nombre + categoría
Solo se muestra si es la primera vez (mensaje de sistema en Firestore)

Verificación del día:

El chat de texto funciona en tiempo real entre dos usuarios
Probar con dos ventanas del emulador
Commit: "feat: chat de texto en tiempo real"

DÍA 28 — Chat: Envío de Imágenes y Ubicación
Envío de imágenes:
dartFuture<void> sendImage(String chatId, String senderUid, File imageFile) async {
// 1. Comprimir
final compressed = await compressImage(imageFile);

// 2. Subir a Storage
final photoId = const Uuid().v4();
final ref = FirebaseStorage.instance.ref('chat_images/$chatId/$photoId.jpg');
await ref.putData(compressed);
final url = await ref.getDownloadURL();

// 3. Guardar mensaje de tipo 'image'
await sendMessageData(chatId, senderUid, {
'type': 'image',
'imageUrl': url,
'sentAt': FieldValue.serverTimestamp(),
});
}
Envío de ubicación:
dartFuture<void> sendLocation(String chatId, String senderUid) async {
final position = await locationService.getCurrentPosition();
if (position == null) return;

// Geocodificar para obtener dirección
final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
final address = '${placemarks.first.street}, ${placemarks.first.locality}';

await sendMessageData(chatId, senderUid, {
'type': 'location',
'location': {
'lat': position.latitude,
'lng': position.longitude,
'address': address,
},
'sentAt': FieldValue.serverTimestamp(),
});
}
Renderizado de mensajes especiales:

Imagen: CachedNetworkImage con click para ver en full-screen
Ubicación: mini-mapa estático (Google Static Maps API) o simplemente el texto de la dirección con ícono de mapa

Verificación del día:

Las imágenes se envían y se muestran en el chat
Las ubicaciones se muestran con la dirección
Commit: "feat: chat - envío de imágenes y ubicaciones"

DÍA 29 — Notificaciones Push (FCM)
lib/data/services/notification_service.dart:
dartclass NotificationService {
final \_messaging = FirebaseMessaging.instance;

Future<void> initialize() async {
// Solicitar permisos
await \_messaging.requestPermission(
alert: true, badge: true, sound: true,
);

    // Obtener token y guardarlo en Firestore
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground: mostrar notificación manual
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background tap: navegar a la pantalla correcta
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

    // App terminada: revisar si hay mensaje inicial
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleOpenedApp(initial);

}

Future<void> \_saveToken(String token) async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
await FirebaseFirestore.instance.doc('users/$uid').update({
'fcmTokens': FieldValue.arrayUnion([token])
});
}

void \_handleForeground(RemoteMessage message) {
// Mostrar banner local usando flutter_local_notifications
}

void \_handleOpenedApp(RemoteMessage message) {
final data = message.data;
// Navegar según tipo: chat, profile, admin
if (data['type'] == 'chat') {
GoRouter.of(context).push('/chat/${data['chatId']}');
}
}
}
Enviar notificaciones desde la app (por ahora sin Cloud Functions):

Crear un servicio que llame a la API REST de FCM directamente
O: usar Firebase Cloud Functions (Blaze) pero para MVP en Spark, guardar notificaciones pendientes en Firestore y procesarlas en el cliente

Nota MVP (Spark sin Cloud Functions): Las notificaciones de nuevos mensajes se envían desde el dispositivo del remitente llamando directamente a la API de FCM. En producción esto es inseguro (la clave FCM quedaría expuesta), pero para MVP es funcional.
Verificación del día:

Las notificaciones de chat llegan cuando la app está en background
Al tocar la notificación, navega al chat correcto
Commit: "feat: notificaciones push FCM completas"

DÍA 30 — Marcar mensajes como leídos + Badge
Lógica de "leído":
dart// Cuando el usuario abre un chat, marcar todos los mensajes como leídos
Future<void> markChatAsRead(String chatId, String uid) async {
// 1. Actualizar contador en el documento del chat
final isClient = chatId.startsWith(uid);
final field = isClient ? 'unreadByClient' : 'unreadByWorker';
await FirebaseFirestore.instance
.doc('chats/$chatId')
.update({field: 0});

// 2. Marcar mensajes individuales (solo los recientes)
final unread = await FirebaseFirestore.instance
.collection('chats/$chatId/messages')
.where('senderUid', isNotEqualTo: uid)
.where('readAt', isNull: true)
.get();

final batch = FirebaseFirestore.instance.batch();
for (final doc in unread.docs) {
batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
}
await batch.commit();
}
Badge en Bottom Navigation:
dartStreamBuilder<int>(
stream: watchTotalUnread(currentUserUid),
builder: (ctx, snapshot) {
final count = snapshot.data ?? 0;
return BottomNavigationBarItem(
icon: Badge(
isLabelVisible: count > 0,
label: Text(count > 99 ? '99+' : '$count'),
child: const Icon(Icons.chat_bubble_outline),
),
label: 'Chats',
);
}
)
Verificación del día:

Los badges desaparecen al leer los mensajes
El badge del tab de Chats muestra el total de no leídos
Commit: "feat: mensajes leídos y badges de notificación"

SEMANA 7 — RESEÑAS Y REPORTES
DÍA 31 — Sistema de Reseñas (Crear)
Trigger de la reseña: 24h después del último mensaje en un chat, si canReviewClient = true.
Implementación del recordatorio:
dart// Al abrir la app, verificar chats con reseña pendiente
Future<void> checkPendingReviews(String clientUid) async {
final chats = await FirebaseFirestore.instance
.collection('chats')
.where('clientUid', isEqualTo: clientUid)
.where('canReviewClient', isEqualTo: true)
.get();

for (final chat in chats.docs) {
final lastMessageAt = chat.data()['lastMessageAt'] as Timestamp?;
if (lastMessageAt == null) continue;

    final diff = DateTime.now().difference(lastMessageAt.toDate());
    if (diff.inHours >= 24) {
      // Mostrar bottom sheet de reseña para este chat
    }

}
}
lib/features/reviews/presentation/widgets/review_bottom_sheet.dart:

Foto del trabajador + nombre
5 estrellas grandes (tap)
Chips de categorías rápidas: Puntual, Buen trabajo, Precio justo, Limpio, Amable
Campo de texto libre (opcional, 200 chars)
Selector de fotos (opcional, máx 3)
Botón "Publicar reseña"
Animación Lottie de estrellas al publicar

Crear reseña en Firestore:
dartFuture<void> createReview(ReviewModel review) async {
final batch = FirebaseFirestore.instance.batch();

// 1. Crear la reseña
final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
batch.set(reviewRef, review.toJson());

// 2. Marcar chat como reseñado
final chatRef = FirebaseFirestore.instance.doc('chats/${review.chatId}');
batch.update(chatRef, {'canReviewClient': false});

// 3. Actualizar rating promedio del trabajador
// (recalcular con todos los ratings del trabajador)
await batch.commit();
await \_updateWorkerRating(review.workerUid);
}

Future<void> \_updateWorkerRating(String workerUid) async {
final reviews = await FirebaseFirestore.instance
.collection('reviews')
.where('workerUid', isEqualTo: workerUid)
.where('isVisible', isEqualTo: true)
.get();

if (reviews.docs.isEmpty) return;

final total = reviews.docs.fold<int>(0, (sum, doc) => sum + (doc.data()['rating'] as int));
final average = total / reviews.docs.length;

await FirebaseFirestore.instance.doc('worker_profiles/$workerUid').update({
'averageRating': average,
'totalReviews': reviews.docs.length,
});
}
Verificación del día:

El bottom sheet de reseña se abre correctamente
La reseña se crea y el rating del trabajador se actualiza
Commit: "feat: sistema de reseñas - crear reseña"

DÍA 32 — Reseñas: Mostrar + Respuesta del Trabajador
Mostrar reseñas en el perfil del trabajador:
Widget de distribución de estrellas (fl_chart):
dart// Barras horizontales mostrando: 5★ → 70%, 4★ → 20%, etc.
BarChart(
BarChartData(
barGroups: [
for (int i = 5; i >= 1; i--)
BarChartGroupData(x: i, barRods: [
BarChartRodData(
toY: percentages[i]!,
color: AppColors.primary,
width: 12, borderRadius: BorderRadius.circular(4),
)
])
],
// Sin grids, sin labels en los ejes
)
)
Pantalla de todas las reseñas (all_reviews_screen.dart):

StreamBuilder con paginación
Cada reseña: foto + nombre del cliente, fecha, estrellas, comentario, fotos (si hay), respuesta del trabajador (si hay)

Respuesta del trabajador:

Solo visible para el dueño del perfil en el modo trabajador
Botón "Responder" solo si workerReply == null
Campo de texto (máx 200 chars) + botón enviar
La respuesta aparece indentada bajo la reseña original

Verificación del día:

Las reseñas se muestran con la distribución de estrellas
El trabajador puede responder una vez por reseña
Commit: "feat: visualización y respuesta de reseñas"

DÍA 33 — Sistema de Reportes
lib/features/reports/presentation/screens/report_screen.dart:

Disponible desde: menú en perfil del trabajador + menú en chat
Selección de motivo (RadioButtons): Fraude, Comportamiento inapropiado, No cumplió lo acordado, Precios engañosos, Otro
Campo de descripción (texto libre, 500 chars)
Botón "Enviar reporte"
Mensaje de confirmación: "Gracias, revisaremos tu reporte en las próximas 24h"

Lógica de conteo de reportes:
dartFuture<void> createReport(ReportModel report) async {
await FirebaseFirestore.instance.collection('reports').add(report.toJson());

// Contar reportes recientes del trabajador
final recentReports = await FirebaseFirestore.instance
.collection('reports')
.where('reportedUid', isEqualTo: report.reportedUid)
.where('createdAt', isGreaterThan: Timestamp.fromDate(
DateTime.now().subtract(const Duration(days: 7))
))
.count()
.get();

if (recentReports.count >= 3) {
// Enviar alerta al admin (crear documento en alerts_queue o notificación directa)
await \_alertAdmin(report.reportedUid, recentReports.count!);
}
}
Verificación del día:

El flujo de reporte funciona desde perfil y chat
Los reportes aparecen en Firestore
La alerta al admin se genera con 3+ reportes
Commit: "feat: sistema de reportes completo"

DÍA 34 — Deep Links + Compartir Perfil
Configurar deep links en Flutter:
Android (AndroidManifest.xml):
xml<intent-filter android:autoVerify="true">
<action android:name="android.intent.action.VIEW" />
<category android:name="android.intent.category.DEFAULT" />
<category android:name="android.intent.category.BROWSABLE" />
<data android:scheme="https" android:host="solucionaya.app" android:pathPrefix="/p/" />
</intent-filter>
iOS (Info.plist): Configurar Associated Domains: applinks:solucionaya.app
Lógica en go_router:
dart// La ruta /p/:slug busca el trabajador por su slug
GoRoute(
path: '/p/:slug',
builder: (ctx, state) {
final slug = state.pathParameters['slug']!;
return WorkerProfileBySlugScreen(slug: slug);
}
)
Búsqueda por slug:
dartFuture<WorkerProfileModel?> getWorkerBySlug(String slug) async {
final query = await FirebaseFirestore.instance
.collection('worker_profiles')
.where('shareableSlug', isEqualTo: slug)
.limit(1)
.get();
if (query.docs.isEmpty) return null;
return WorkerProfileModel.fromJson(query.docs.first.data());
}
Generación del slug (al crear el perfil del trabajador):
dartString generateSlug(String name, String city) {
final normalized = name.toLowerCase()
.replaceAll(RegExp(r'[áàä]'), 'a')
.replaceAll(RegExp(r'[éèë]'), 'e')
.replaceAll(RegExp(r'[íìï]'), 'i')
.replaceAll(RegExp(r'[óòö]'), 'o')
.replaceAll(RegExp(r'[úùü]'), 'u')
.replaceAll(' ', '-')
.replaceAll(RegExp(r'[^a-z0-9-]'), '');
final cityShort = city == 'bucaramanga' ? 'bga' : 'bca';
return '$normalized-$cityShort';
}
Botón "Compartir perfil":
dartFuture<void> shareWorkerProfile(WorkerProfileModel worker) async {
final url = 'https://solucionaya.app/p/${worker.shareableSlug}';
await Share.share(
'¡Mira el perfil de ${worker.displayName} en SolucionaYa!\n$url',
subject: 'Trabajador verificado en SolucionaYa',
);
}
Verificación del día:

Los deep links abren el perfil correcto al recibir el link
El botón de compartir genera el link correcto
Commit: "feat: deep links y compartir perfil"

DÍA 35 — Tiempo de Respuesta + Modo Offline
Cálculo del tiempo de respuesta:
dartFuture<void> updateResponseTime(String workerUid, String chatId) async {
// Obtener los últimos 10 pares mensaje_cliente → respuesta_trabajador
final messages = await FirebaseFirestore.instance
.collection('chats/$chatId/messages')
.orderBy('sentAt', descending: true)
.limit(20)
.get();

// Calcular tiempo promedio de respuesta del trabajador
// Solo cuando el remitente NO es el trabajador y la respuesta SÍ es del trabajador

// Actualizar worker_profile con responseTimeMinutes
}
Modo Offline:
dart// En FirebaseFirestore.instance, habilitar persistencia
FirebaseFirestore.instance.settings = const Settings(
persistenceEnabled: true,
cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
Banner de offline:
dart// StreamBuilder que escucha la conectividad
ConnectivityResult result = await Connectivity().checkConnectivity();
if (result == ConnectivityResult.none) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Estás offline — mostrando resultados guardados'),
backgroundColor: AppColors.warning,
duration: Duration(days: 1), // permanente hasta que se reconecte
),
);
}
Verificación del día:

El tiempo de respuesta se muestra en el perfil
La app funciona con datos cacheados sin internet
Commit: "feat: tiempo de respuesta y modo offline"

SEMANA 8 — PAGOS WOMPI SANDBOX
DÍA 36 — Integración Wompi Sandbox (Parte 1)
Crear cuenta de prueba en Wompi:

Ir a wompi.com → Crear cuenta de desarrollo
Obtener public_key y private_key de sandbox
Guardar como constantes en app_constants.dart (NUNCA en git público)

Configuración WebView:
yaml# pubspec.yaml
webview_flutter: ^4.9.0
Generar el link de pago Wompi:
dartFuture<String> generateWompiCheckoutUrl({
required int amountInCents,
required String reference,
required String description,
}) async {
// Para sandbox, usar el link de checkout de Wompi
// https://checkout.wompi.co/p/?public-key=...&currency=COP&amount-in-cents=...&reference=...

final params = {
'public-key': WompiConstants.publicKeySandbox,
'currency': 'COP',
'amount-in-cents': amountInCents.toString(),
'reference': reference,
'redirect-url': 'solucionaya://payment-result',
};

final uri = Uri.https('checkout.wompi.co', '/p/', params);
return uri.toString();
}
Verificación del día:

Se puede generar una URL de pago de Wompi
La URL abre correctamente en el browser de prueba
Commit: "feat: integración Wompi sandbox - URL de pago"

DÍA 37 — Wompi: Flujo completo en el chat
Pantalla de solicitud de pago (trabajador):
dartclass RequestPaymentBottomSheet extends StatefulWidget {
// Campo de monto (COP)
// Descripción del servicio
// Botón "Enviar solicitud de pago"
}
Mensaje de tipo payment_request en el chat:
dart// Renderizado personalizado en flutter_chat_ui
Widget \_buildCustomMessage(types.CustomMessage message, ...) {
if (message.metadata?['type'] == 'payment_request') {
return PaymentRequestBubble(
amount: message.metadata!['amount'],
description: message.metadata!['description'],
status: message.metadata!['status'], // pending/completed/failed
onPay: () => \_handlePayment(message),
);
}
return const SizedBox.shrink();
}
PaymentRequestBubble:

Card con ícono de dinero
Monto formateado en COP
Descripción del servicio
Estado: "Pendiente de pago" (naranja) / "Pagado ✓" (verde) / "Rechazado" (rojo)
Botón "Pagar con Wompi" si status es pending y el usuario es el cliente

WebView de Wompi:
dartclass WompiWebViewScreen extends StatelessWidget {
final String checkoutUrl;

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Pago seguro')),
body: WebViewWidget(
controller: WebViewController()
..setJavaScriptMode(JavaScriptMode.unrestricted)
..setNavigationDelegate(NavigationDelegate(
onNavigationRequest: (request) {
if (request.url.startsWith('solucionaya://payment-result')) {
// Parsear el resultado y navegar a la pantalla de éxito/error
\_handlePaymentResult(context, request.url);
return NavigationDecision.prevent;
}
return NavigationDecision.navigate;
},
))
..loadRequest(Uri.parse(checkoutUrl)),
),
);
}
}
Verificación del día:

El trabajador puede solicitar un pago en el chat
El cliente ve el botón de pagar
El WebView de Wompi abre correctamente
Commit: "feat: flujo de pago en chat con Wompi WebView"

DÍA 38 — Wompi: Pantallas de resultado
lib/features/payments/presentation/screens/payment_success_screen.dart:

Lottie de confetti (descargarlo de lottiefiles.com, archivo .json en assets/)
"¡Pago confirmado!"
Monto pagado
Nombre del trabajador
Botón "Volver al chat"

lib/features/payments/presentation/screens/payment_error_screen.dart:

Ícono de X con animación
Título: "El pago no fue procesado"
Motivo del error (viene del resultado de Wompi)
Botón "Intentar de nuevo" → vuelve al WebView
Botón "Cancelar" → vuelve al chat

Actualizar Firestore al recibir resultado:
dartFuture<void> processPaymentResult(String chatId, String paymentMessageId, String status, int amount) async {
final batch = FirebaseFirestore.instance.batch();

// Actualizar el mensaje de pago
batch.update(
FirebaseFirestore.instance.doc('chats/$chatId/messages/$paymentMessageId'),
{'paymentData.status': status}
);

// Actualizar el chat
batch.update(
FirebaseFirestore.instance.doc('chats/$chatId'),
{'paymentStatus': status, 'paymentAmount': amount}
);

await batch.commit();

// Enviar notificación a ambos
if (status == 'completed') {
await notificationService.sendPaymentConfirmed(chatId, amount);
}
}
Verificación del día:

Las pantallas de éxito y error se muestran correctamente
El estado del pago se guarda en Firestore
Las notificaciones de pago llegan a ambos usuarios
Commit: "feat: pantallas de resultado de pago y actualización Firestore"

DÍA 39 — Estadísticas del Trabajador
lib/features/worker_profile/presentation/screens/worker_stats_screen.dart:
Usando fl_chart:
Gráfico de vistas de perfil (línea):
dartLineChart(
LineChartData(
lineBarsData: [
LineChartBarData(
spots: weeklyViews.asMap().entries
.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
.toList(),
color: AppColors.primary,
belowBarData: BarAreaData(
show: true,
color: AppColors.primary.withOpacity(0.1),
),
)
],
// Configurar títulos, grid, etc.
)
)
Cards de KPIs:

Vistas esta semana (con flecha de tendencia)
Chats iniciados este mes
Calificación promedio (número grande con estrellas)
Reseñas esta semana

Botón "Comparte tu perfil": Llama a shareWorkerProfile().
Datos de estadísticas:
dart// Colección analytics_events/{uid}/events/{date}
// O simplemente calcular desde los documentos existentes
// Para MVP: calcular client-side desde Firestore con queries específicas
Verificación del día:

Los gráficos muestran datos reales (o datos de prueba del emulador)
El botón de compartir funciona
Commit: "feat: dashboard de estadísticas del trabajador"

DÍA 40 — Actividad del Trabajador + Onboarding post-aprobación
lib/features/worker_profile/presentation/screens/worker_activity_screen.dart:

Sección "Vistas de mi perfil": número en las últimas 48h (sin revelar nombres, por privacidad)
Sección "Nuevos chats": lista de clientes que escribieron recientemente
Sección "Nuevas reseñas": reseñas recibidas esta semana
Sección "Estado de verificación": timeline visual (pendiente → aprobado o rechazado)

Onboarding del trabajador post-aprobación (si es su primera vez aprobado):

Modal o pantalla de bienvenida con pasos:

"¡Tu perfil está activo! Ahora apareces en las búsquedas."
"Completa tu perfil para aparecer primero." (con botón directo)
"Activa 'Disponible ahora' cuando puedas trabajar." (con demo del toggle)
"Comparte tu perfil y consigue tus primeros clientes." (con botón de compartir)

Guardar en SharedPreferences: workerOnboardingCompleted = true

Verificación del día:

La actividad del trabajador muestra datos correctos
El onboarding post-aprobación solo aparece una vez
Commit: "feat: actividad del trabajador y onboarding post-aprobación"

SEMANA 9 — ADMIN PANEL (Flutter Web)
DÍA 41 — Setup del Admin Panel (Flutter Web)
El Admin Panel es la misma app Flutter corriendo como Flutter Web.
Configurar rutas del Admin con acceso solo para admins:
dart// En el router, verificar el custom claim admin: true
FutureOr<String?> adminRedirect(BuildContext ctx, GoRouterState state) async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return '/login';

final idToken = await user.getIdTokenResult();
if (idToken.claims?['admin'] != true) return '/'; // redirect a home

return null; // Permitir acceso
}
Activar custom claim de admin (desde Firebase CLI o directamente en el emulador):
bash# En el emulador de Firebase Auth, puedes setear custom claims

# Para producción, usar Firebase Admin SDK en un script seguro

firebase auth:export users.json --project solucionaya-mvp

# Editar y re-importar, o usar la SDK

Layout del Admin Panel:

NavigationRail (lateral) con íconos para las secciones
AppBar con título de la sección actual
Área de contenido principal

Secciones de navegación:

Dashboard (home)
Trabajadores
Reportes
Categorías
Comunicaciones
Logs

Verificación del día:

El Admin Panel corre en Flutter Web (flutter run -d chrome)
Solo usuarios con claim admin: true pueden acceder
La navegación lateral funciona
Commit: "feat: admin panel - estructura y navegación"

DÍA 42 — Admin Dashboard con KPIs
lib/features/admin/presentation/screens/admin_dashboard_screen.dart:
6 Cards de KPIs (en un GridView.count(crossAxisCount: 3)):
dartclass KpiCard extends StatelessWidget {
final String title;
final String value;
final IconData icon;
final Color color;
// ...
}

Trabajadores activos (total verificados)
Clientes activos (activos en últimos 7 días)
Verificaciones pendientes (con badge rojo si > 0)
Chats hoy (count de chats creados hoy)
Reportes sin resolver
Calificación promedio de la plataforma

Gráfico de registros por semana (fl_chart, LineChart):

Línea azul: clientes
Línea naranja: trabajadores
Últimas 8 semanas

Gráfico de distribución por categoría (fl_chart, PieChart):

8 segmentos (uno por categoría)
Leyenda lateral

Feed en tiempo real (StreamBuilder):
dartStream<List<Map>> watchRecentActivity() {
return FirebaseFirestore.instance
.collection('admin_logs')
.orderBy('timestamp', descending: true)
.limit(10)
.snapshots()
.map(...);
}
Verificación del día:

El dashboard muestra datos reales del emulador
Los gráficos se renderizan correctamente en Flutter Web
Commit: "feat: admin dashboard con KPIs y gráficos"

DÍA 43 — Admin: Gestión de Trabajadores
lib/features/admin/presentation/screens/admin_workers_screen.dart:
Tabla de trabajadores (Flutter Web, pantalla ancha):
dart// Usar DataTable2 package para tablas eficientes
DataTable2(
columns: const [
DataColumn2(label: Text('Trabajador'), size: ColumnSize.L),
DataColumn2(label: Text('Categorías')),
DataColumn2(label: Text('Ciudad')),
DataColumn2(label: Text('Estado')),
DataColumn2(label: Text('Registro')),
DataColumn2(label: Text('Calificación')),
DataColumn2(label: Text('Acciones'), size: ColumnSize.S),
],
rows: workers.map((w) => DataRow2(
cells: [...],
onTap: () => showWorkerDetails(w),
)).toList(),
)
Filtros en la barra superior:

Dropdown: Todos / Pendientes / Verificados / Suspendidos
Dropdown: Todas las ciudades / Bucaramanga / Barrancabermeja
Buscador por nombre

Panel lateral de detalle (al tocar una fila):

Foto de cédula (con botón "Ver imagen")
Datos del perfil
Historial de acciones del admin sobre este trabajador
Botones de acción: Aprobar ✓ / Rechazar ✗ / Suspender ⛔

Modal de Aprobar:
dart// Simplemente confirmar y llamar:
Future<void> approveWorker(String workerUid, String adminUid) async {
final batch = FirebaseFirestore.instance.batch();

batch.update(
FirebaseFirestore.instance.doc('worker_profiles/$workerUid'),
{'verified': true, 'verifiedAt': FieldValue.serverTimestamp(), 'verifiedBy': adminUid}
);

batch.set(
FirebaseFirestore.instance.collection('admin_logs').doc(),
{'adminUid': adminUid, 'action': 'verify_worker', 'targetUid': workerUid, 'timestamp': FieldValue.serverTimestamp()}
);

await batch.commit();

// Enviar notificación al trabajador
await notificationService.sendWorkerApproved(workerUid);
}
Modal de Rechazar: Con campo de motivo obligatorio.
Modal de Suspender: Con campo de motivo + duración (opcional).
Verificación del día:

La tabla de trabajadores muestra todos con filtros funcionando
Aprobar/Rechazar/Suspender actualizan Firestore y envían notificaciones
Los logs se registran correctamente
Commit: "feat: admin - gestión completa de trabajadores"

DÍA 44 — Admin: Moderación + Categorías
lib/features/admin/presentation/screens/admin_reports_screen.dart:

Lista de reportes pendientes ordenados por urgencia (trabajadores con más reportes primero)
Cada reporte: quién reportó, quién fue reportado, motivo, descripción, fecha
Historial de reportes del trabajador reportado (¿cuántos tiene?)
Acciones: Resolver (sin acción sobre el trabajador) / Advertir / Suspender trabajador
Al tomar acción: cambiar status del reporte y crear log

lib/features/admin/presentation/screens/admin_categories_screen.dart:

Lista de las 8 categorías con toggle activo/inactivo
Al tocar categoría: abrir editor
Editor: nombre, ícono (texto del nombre del ícono en Material Icons), color, precios sugeridos (lista editable), orden en el home
CRUD de precios sugeridos dentro de cada categoría

Verificación del día:

El admin puede resolver reportes con historial
Las categorías son completamente editables
Commit: "feat: admin - moderación de reportes y gestión de categorías"

DÍA 45 — Admin: Comunicaciones + Logs
lib/features/admin/presentation/screens/admin_communications_screen.dart:
Enviar notificación masiva:
dart// Para MVP sin Cloud Functions, usar la API REST de FCM directamente
// Obtener todos los FCM tokens del segmento y enviar
Future<void> sendMassNotification({
required String title,
required String body,
required String segment, // 'all' | 'clients' | 'workers'
}) async {
// 1. Obtener todos los tokens del segmento
final users = await FirebaseFirestore.instance
.collection('users')
.where(segment == 'clients' ? 'role' : 'role', isEqualTo: segment == 'clients' ? 'client' : 'worker')
.get();

final tokens = users.docs
.expand((doc) => List<String>.from(doc.data()['fcmTokens'] ?? []))
.toList();

// 2. Enviar en batches de 500 (límite FCM)
await notificationService.sendToTokens(tokens, title, body);

// 3. Guardar en historial
await FirebaseFirestore.instance.collection('communications').add({
'title': title, 'body': body, 'segment': segment,
'sentAt': FieldValue.serverTimestamp(), 'recipientCount': tokens.length,
});
}
lib/features/admin/presentation/screens/admin_logs_screen.dart:

Tabla de todos los admin_logs
Filtros por: acción, adminUid, fecha desde/hasta
Exportar a CSV (para Flutter Web, usar dart:html para descargar)

Verificación del día:

El admin puede enviar notificaciones masivas
Los logs se pueden filtrar y exportar
Commit: "feat: admin - comunicaciones masivas y logs completos"

SEMANA 10 — CONFIGURACIÓN, SEGURIDAD Y POLISH
DÍA 46 — Pantalla de Configuración + Política de Privacidad
lib/features/settings/presentation/screens/settings_screen.dart:
Secciones:

Notificaciones (toggles por tipo)
Apariencia (tema: claro/oscuro/sistema)
Cuenta: cambiar contraseña, cambiar email
Legal: Política de privacidad, Términos de uso
Soporte: WhatsApp de soporte (abre WhatsApp con número predefinido)
"Eliminar mi cuenta" (rojo, al fondo)

Toggles de notificaciones:
dart// Guardar preferencias en SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('notify_chat', value);
await prefs.setBool('notify_review', value);
// etc.

// Al recibir notificación, verificar la preferencia antes de mostrarla
Flujo "Eliminar mi cuenta":

Confirmación: "Esta acción es irreversible"
Re-autenticación (pedir contraseña/OTP)
Borrar todos los datos del usuario:

users/{uid}
worker_profiles/{uid} y subcolecciones
favorites/{uid}
Fotos en Storage
Firebase Auth user

Navegar a pantalla de "Cuenta eliminada"

Verificación del día:

Los toggles de notificaciones funcionan y persisten
El flujo de eliminación de cuenta funciona completamente
Commit: "feat: pantalla de configuración completa"

DÍA 47 — Reglas de Seguridad de Firestore y Storage (Producción)
Reemplazar las reglas TEST por las reglas de producción del Plan Maestro (Sección 11).
Probar las reglas con el emulador:
bash# Instalar Firebase Emulator
firebase emulators:start --only firestore

# Escribir tests de reglas

# test/firestore_rules_test.dart

javascript// test/firestore.rules.test.js (usando @firebase/rules-unit-testing)
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

describe('Worker Profile Rules', () => {
it('allows owner to update their profile', async () => {
const db = getFirestoreWithAuth({ uid: 'worker_1' });
await assertSucceeds(
db.doc('worker_profiles/worker_1').update({ bio: 'Nueva bio' })
);
});

it('denies non-owner from updating', async () => {
const db = getFirestoreWithAuth({ uid: 'client_1' });
await assertFails(
db.doc('worker_profiles/worker_1').update({ bio: 'Intento hackeo' })
);
});
});
Probar al menos 15 casos de reglas:

Lectura pública de perfiles de trabajadores ✓
Escritura solo del dueño ✓
Chat solo entre participantes ✓
Admin puede leer todo ✓
Foto de cédula solo para admin ✓
Reseña solo si eres el cliente ✓
Config solo lectura pública ✓

Verificación del día:

Todas las reglas de seguridad están en producción
Los 15+ tests de reglas pasan
Commit: "security: reglas Firestore y Storage de producción con tests"

DÍA 48 — Firebase App Check
Activar App Check en Firebase Console:

Android: Play Integrity
iOS: DeviceCheck
Web (para Admin Panel): reCAPTCHA Enterprise

En el código:
dart// main.dart - después de Firebase.initializeApp()
if (!kDebugMode) { // Solo en producción
await FirebaseAppCheck.instance.activate(
androidProvider: AndroidProvider.playIntegrity,
appleProvider: AppleProvider.deviceCheck,
webProvider: ReCaptchaV3Provider('YOUR_SITE_KEY'),
);
}
Para el emulador de desarrollo:
dartif (kDebugMode) {
await FirebaseAppCheck.instance.activate(
androidProvider: AndroidProvider.debug,
appleProvider: AppleProvider.debug,
);
}
Verificación del día:

App Check activo en producción (verificar en Firebase Console → App Check)
En debug sigue funcionando con el debug provider
Commit: "security: Firebase App Check activado"

DÍA 49 — Polish: Animaciones, Transiciones y Empty States
Animaciones con flutter_animate:
dart// Entrada de cards con stagger
for (int i = 0; i < workers.length; i++)
WorkerCard(worker: workers[i])
.animate(delay: Duration(milliseconds: i \* 80))
.fadeIn()
.slideY(begin: 0.2, end: 0),

// Toggle de disponibilidad
AnimatedContainer(
duration: const Duration(milliseconds: 300),
color: isAvailable ? AppColors.secondary : Colors.grey,
// ...
)
Skeleton Loaders para todas las listas:
dartclass WorkerCardSkeleton extends StatelessWidget {
@override
Widget build(BuildContext context) {
return Shimmer.fromColors(
baseColor: Colors.grey[300]!,
highlightColor: Colors.grey[100]!,
child: Card(child: /_ Forma del skeleton _/),
);
}
}
Empty States con Lottie:
dartclass EmptyStateWidget extends StatelessWidget {
final String lottieAsset; // 'assets/lottie/empty*search.json'
final String title;
final String description;
final String? buttonLabel;
final VoidCallback? onButtonTap;
}
Transiciones de página personalizadas:
dart// En go_router, usar pageBuilder para transiciones
pageBuilder: (context, state) => CustomTransitionPage(
transitionsBuilder: (ctx, animation, *, child) {
return FadeTransition(opacity: animation, child: child);
},
child: WorkerProfileDetailScreen(workerId: state.pathParameters['workerId']!),
),
Verificación del día:

Las animaciones de entrada de listas funcionan
Los skeleton loaders aparecen mientras carga
Los empty states tienen ilustraciones Lottie
Commit: "feat: polish - animaciones, skeletons y empty states"

DÍA 50 — Dark Mode Completo + Accesibilidad
Dark Mode:

Verificar TODAS las pantallas en modo oscuro
Fijar colores que solo funcionan en claro: cambiar a Theme.of(context).colorScheme.surface
Los colores de categorías deben ajustarse (fondos más oscuros en dark mode)

lib/core/theme/dark_theme.dart: Crear el tema oscuro completo.
Accesibilidad:

Verificar que todos los botones tengan semanticLabel
Todos los íconos con significado tengan Semantics(label: '...')
Los campos de texto tengan labelText y hintText
Tamaño mínimo de área táctil: 48×48 dp (usar SizedBox si es necesario)

Test de accesibilidad manual:

Activar TalkBack (Android) y navegar por todas las pantallas
Verificar que el lector de pantalla anuncia todo correctamente

Verificación del día:

Todas las pantallas se ven correctamente en modo oscuro
TalkBack puede navegar las pantallas principales
Commit: "feat: dark mode completo y accesibilidad WCAG AA"

SEMANA 11 — TESTING AUTOMÁTICO
DÍA 51–52 — Unit Tests: Modelos y Utilidades
Tests para todos los modelos (test/data/models/):
dartvoid main() {
group('WorkerProfileModel', () {
test('fromJson crea el modelo correctamente', () {
final json = {
'uid': 'test_uid',
'categories': ['plomeria', 'electricidad'],
'availableNow': true,
// ...
};
final model = WorkerProfileModel.fromJson(json);
expect(model.uid, 'test_uid');
expect(model.categories, containsAll(['plomeria', 'electricidad']));
});

    test('toJson genera el JSON correcto', () {
      final model = WorkerProfileModel(uid: 'test_uid', ...);
      final json = model.toJson();
      expect(json['uid'], 'test_uid');
    });

    test('copyWith actualiza solo el campo especificado', () {
      final model = WorkerProfileModel(uid: 'test_uid', availableNow: false, ...);
      final updated = model.copyWith(availableNow: true);
      expect(updated.availableNow, true);
      expect(updated.uid, 'test_uid');
    });

});
}
Tests para utilities:
dart// formatters_test.dart
test('formatCOP formatea correctamente', () {
expect(formatCOP(150000), '\$150.000');
expect(formatCOP(1000000), '\$1.000.000');
});

// validators_test.dart
test('Colombian phone validator', () {
expect(isValidColombianPhone('3001234567'), true);
expect(isValidColombianPhone('123456789'), false);
expect(isValidColombianPhone('30012345678'), false); // 11 dígitos
});

// profile_completeness_test.dart
test('calculates completeness correctly', () {
final profile = WorkerProfileModel(photoUrl: 'url', bio: 'bio', experienceYears: 5, ...);
final prices = [PriceModel(...)];
final gallery = [GalleryPhotoModel(...), GalleryPhotoModel(...), GalleryPhotoModel(...)];
expect(calculateCompleteness(profile, prices, gallery), 90); // 7 de los 7 factores
});
Objetivo: 80%+ de cobertura en modelos y utilities.
Verificación de los 2 días:

Todos los tests pasan: flutter test test/data/ test/core/
Commit: "test: unit tests para modelos y utilities - cobertura 80%+"

DÍA 53–54 — Widget Tests: Componentes UI
Tests para widgets críticos (test/features/):
dart// worker_card_test.dart
testWidgets('WorkerCard muestra badge Verificado cuando verified=true', (tester) async {
await tester.pumpWidget(
ProviderScope(
child: MaterialApp(
home: WorkerCard(
worker: WorkerProfileModel(verified: true, displayName: 'Carlos', ...),
),
),
),
);

expect(find.text('Verificado'), findsOneWidget);
expect(find.text('Carlos'), findsOneWidget);
});

testWidgets('WorkerCard muestra badge AHORA cuando availableNow=true', (tester) async {
// ...
expect(find.text('AHORA'), findsOneWidget);
});

// chat_bubble_test.dart
testWidgets('PaymentRequestBubble muestra botón Pagar cuando status=pending', ...);
testWidgets('PaymentRequestBubble no muestra botón cuando status=completed', ...);

// filter_bottom_sheet_test.dart
testWidgets('FilterBottomSheet llama onApply con los filtros correctos', ...);
Verificación de los 2 días:

Tests de widgets principales pasan
Commit: "test: widget tests para componentes críticos"

DÍA 55 — Integration Tests Básicos
integration_test/registration_flow_test.dart:
dartvoid main() {
IntegrationTestWidgetsFlutterBinding.ensureInitialized();

testWidgets('Flujo de registro de cliente completo', (tester) async {
await tester.pumpWidget(const ProviderScope(child: MyApp()));
await tester.pumpAndSettle();

    // Saltar onboarding
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    // Seleccionar rol de cliente
    await tester.tap(find.text('Necesito un servicio'));
    await tester.pumpAndSettle();

    // Ingresar teléfono (con emulador de Firebase Auth)
    await tester.enterText(find.byType(TextField).first, '3001234567');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    // El código OTP en el emulador es siempre 123456
    for (int i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
    }
    await tester.pumpAndSettle();

    // Verificar que llegó al registro de perfil
    expect(find.text('Tu nombre'), findsOneWidget);

});
}
Ejecutar con el emulador activo:
bashfirebase emulators:start &
flutter test integration_test/ -d emulator-5554
Verificación del día:

Al menos el flujo de registro del cliente pasa el integration test
Commit: "test: integration test de flujo de registro"

SEMANA 12 — OPTIMIZACIÓN Y PREPARACIÓN PARA PRODUCCIÓN
DÍA 56 — Optimización de Performance
Optimizar consultas Firestore:
dart// MALO: Leer todos los workers y filtrar en el cliente
final all = await workerProfiles.get(); // puede ser miles de documentos

// BUENO: Filtrar en la query
final filtered = await workerProfiles
.where('city', isEqualTo: userCity)
.where('verified', isEqualTo: true)
.where('categories', arrayContains: selectedCategory)
.limit(20)
.get();
Crear índices compuestos en Firestore:
// firestore.indexes.json
{
"indexes": [
{
"collectionGroup": "worker_profiles",
"fields": [
{"fieldPath": "city", "order": "ASCENDING"},
{"fieldPath": "verified", "order": "ASCENDING"},
{"fieldPath": "averageRating", "order": "DESCENDING"}
]
},
{
"collectionGroup": "worker_profiles",
"fields": [
{"fieldPath": "city", "order": "ASCENDING"},
{"fieldPath": "availableNow", "order": "ASCENDING"},
{"fieldPath": "averageRating", "order": "DESCENDING"}
]
}
]
}
Optimizar imágenes:

cached_network_image con placeholder shimmer en todos los Image.network
ListView.builder (lazy) en lugar de ListView(children: [...])
const constructors donde sea posible

Verificación del día:

Las queries principales usan los índices creados
No hay setState en widgets que renderizan listas largas
Commit: "perf: optimización de queries Firestore e imágenes"

DÍA 57 — App Config + Force Update + Maintenance Mode
lib/data/services/app_config_service.dart:
dartclass AppConfigService {
Future<void> checkConfig() async {
final doc = await FirebaseFirestore.instance.doc('app_config/global').get();
final config = doc.data()!;

    // 1. Modo mantenimiento
    if (config['maintenanceMode'] == true) {
      // Navegar a pantalla de mantenimiento
      GoRouter.of(navigatorKey.currentContext!).go('/maintenance');
      return;
    }

    // 2. Actualización forzada
    final currentVersion = await PackageInfo.fromPlatform().then((p) => p.version);
    final minVersion = config['minimumAppVersion'] as String;
    if (_compareVersions(currentVersion, minVersion) < 0) {
      // Mostrar dialog de actualización obligatoria
      showUpdateDialog();
      return;
    }

}
}
Pantalla de mantenimiento: Simple con Lottie de herramientas y "Estamos mejorando la app para ti. Vuelve en unos minutos."
Dialog de actualización forzada: No se puede cerrar, solo botón "Actualizar" que abre la Play Store / App Store.
Verificación del día:

El modo mantenimiento redirige correctamente
El force update muestra el dialog
Commit: "feat: app config, mantenimiento y actualización forzada"

DÍA 58 — Manejo de Errores Global + Crashlytics
lib/core/utils/error*handler.dart:
dartclass ErrorHandler {
static String getErrorMessage(dynamic error) {
if (error is FirebaseAuthException) {
return switch (error.code) {
'invalid-phone-number' => 'El número de teléfono no es válido',
'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
'network-request-failed' => 'Sin conexión a internet',
* => 'Error de autenticación. Intenta de nuevo.',
};
}
if (error is FirebaseException) {
if (error.code == 'unavailable') return 'Sin conexión. Verifica tu internet.';
if (error.code == 'permission-denied') return 'No tienes permiso para esta acción.';
}
return 'Algo salió mal. Intenta de nuevo.';
}
}
Crashlytics:
dart// Capturar errores no manejados
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
return true;
};

// Errores manejados (para debugging)
try {
await riskyOperation();
} catch (e, stack) {
FirebaseCrashlytics.instance.recordError(e, stack);
ErrorHandler.showError(context, e);
}
Verificación del día:

Los errores de Firebase Auth muestran mensajes amigables en español
Los crashes se reportan en Crashlytics
Commit: "feat: manejo de errores global y Crashlytics configurado"

DÍA 59 — Configurar Play Store (Android)
Preparar para publicación:
android/app/build.gradle:
groovyandroid {
defaultConfig {
applicationId "com.solucionaya.app"
minSdk 21
targetSdk 34
versionCode 1
versionName "1.0.0"
}

signingConfigs {
release {
keyAlias keystoreProperties['keyAlias']
keyPassword keystoreProperties['keyPassword']
storeFile file(keystoreProperties['storeFile'])
storePassword keystoreProperties['storePassword']
}
}

buildTypes {
release {
signingConfig signingConfigs.release
minifyEnabled true
shrinkResources true
}
}
}
Generar keystore:
bashkeytool -genkey -v -keystore ~/solucionaya_keystore.jks \
 -keyalg RSA -keysize 2048 -validity 10000 \
 -alias solucionaya

# GUARDAR EL KEYSTORE EN LUGAR SEGURO (NO EN GIT)

Crear en Google Play Console:

Cuenta de desarrollador ($25 USD único pago)
Crear aplicación: "SolucionaYa - Servicios en casa"
Completar: descripción, categoría (Estilo de vida), calificación de contenido
Subir screenshots (mínimo 2)

Build de release:
bashflutter build appbundle --release

# Genera: build/app/outputs/bundle/release/app-release.aab

Verificación del día:

El .aab se genera sin errores
La cuenta de Play Console está creada
Commit: "build: configuración Android release + keystore"

DÍA 60 — Configurar App Store (iOS)
Requisitos:

Cuenta Apple Developer ($99 USD/año)
Mac con Xcode 15+
Certificados de distribución

ios/Runner/Info.plist: Agregar permisos:
xml<key>NSCameraUsageDescription</key>
<string>Para subir fotos de tus trabajos y perfil</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para subir fotos de tus trabajos y perfil</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para mostrarte trabajadores cerca de ti</string>
<key>NSMicrophoneUsageDescription</key>
<string>Para mensajes de voz en el chat (próximamente)</string>
Build de release:
bashflutter build ios --release

# Luego en Xcode: Product → Archive → Distribute App

En App Store Connect:

Crear nueva app
Bundle ID: com.solucionaya.app
Completar metadatos, screenshots

Verificación del día:

El build de iOS se genera sin errores
La app está creada en App Store Connect
Commit: "build: configuración iOS release"

SEMANA 13 — BETA CERRADA
DÍA 61 — Firebase App Distribution (Beta)
Configurar Firebase App Distribution:
bash# Instalar plugin
flutter pub add firebase_app_distribution
firebase.json:
json{
"app_distribution": {
"app": "YOUR_APP_ID",
"testers_file": "testers.txt",
"release_notes_file": "release_notes.txt"
}
}
testers.txt: Lista de emails de los 20 testers.
Distribuir build:
bashflutter build apk --release
firebase appdistribution:distribute build/app/outputs/apk/release/app-release.apk \
 --app YOUR_APP_ID \
 --release-notes "Beta 1.0 - Flujo completo de registro, búsqueda y chat" \
 --testers-file testers.txt
Verificación del día:

Los 20 testers reciben el email de invitación
Pueden instalar la app en sus dispositivos
Commit: "build: distribución beta cerrada via App Distribution"

DÍA 62–65 — QA Manual en Dispositivos Reales
Dispositivos de prueba mínimos:

Android: Samsung Galaxy A series (los más comunes en Colombia), Motorola Moto G
iOS: iPhone SE 2020 (pantalla pequeña), iPhone 13

Checklist de QA por dispositivo:
Flujos críticos:

Registro cliente completo (teléfono + OTP + perfil)
Registro trabajador completo (con foto de cédula)
Espera de aprobación → aprobación por admin
Búsqueda con todos los filtros
Abrir perfil de trabajador
Iniciar chat
Enviar texto, imagen y ubicación en chat
Solicitar pago (trabajador) → pagar (cliente)
Dejar reseña
Reportar usuario
Compartir perfil
Recibir notificaciones push (en background y en primer plano)
Funcionar sin internet (modo offline)
Cambiar a dark mode
Admin: aprobar trabajador
Admin: rechazar trabajador con motivo

Bugs encontrados → crear issues en GitHub y priorizar:

Crítico: rompe el flujo principal → corregir ese mismo día
Alto: afecta la experiencia pero hay workaround → corregir esta semana
Medio: cosmético o edge case → corregir antes del lanzamiento

SEMANAS 14-15 — CORRECCIONES Y FEEDBACK
DÍA 66–70 — Correcciones de Beta + Feedback de Testers
Recopilar feedback estructurado: Formulario de Google Forms con:

¿Pudiste completar el registro sin problemas? (1–5)
¿Fue fácil encontrar un trabajador? (1–5)
¿El chat funcionó correctamente? (1–5)
¿Qué fue lo más confuso?
¿Qué le cambiarías primero?
¿Lo usarías regularmente? ¿Por qué sí/no?

Priorizar correcciones por impacto:

Bugs críticos del QA manual
Confusiones de UX reportadas por 3+ testers
Performance (pantallas lentas)

Día 66–67: Corregir todos los bugs críticos y altos.
Día 68–69: Correcciones de UX basadas en feedback.
Día 70: Segunda ronda de QA en los flujos corregidos.

DÍA 71–73 — Seed de Datos para Lanzamiento
Esta semana, paralelamente al desarrollo, hacer:
Crear manualmente en producción (no en emulador):

Conectar la app a Firebase producción (cambiar kDebugMode o crear flavor)
Registrar a los 25–35 trabajadores que ya reclutaste
Para cada trabajador: subir sus fotos de trabajos, configurar precios, llenar bio
Aprobarlos todos desde el Admin Panel
Crear algunas reseñas iniciales (puedes pedirle a testers que las dejen)

Verificar que el Admin Panel de producción funciona:

Crear tu usuario admin con el claim admin: true
Probar aprobar un trabajador real

DÍA 74–75 — Preparación Final para Publicación
Checklist final técnico:

kDebugMode emuladores: OFF en builds de release
Keys de Wompi: cambiar de sandbox a producción (cuando estés listo) O mantener sandbox para el lanzamiento
Firebase App Check: verificar que esté activo en producción
Reglas de Firestore y Storage: verificar que NO estén en modo TEST
Analytics: verificar que los eventos se están registrando
Crashlytics: enviar un error de prueba y verificar que aparece
Probar los deep links en producción
Verificar que las notificaciones push llegan en producción
Verificar modo offline en producción

Screenshots y metadatos para las stores:

5 screenshots en resolución correcta (Play Store: 1080×1920 o 1080×2160)
Descripción corta (80 chars máx)
Descripción larga (4000 chars)
Ícono de app: 512×512 PNG sin transparencia

SEMANA 16 — LANZAMIENTO
DÍA 76–77 — Publicación en Play Store
Subir a Play Store:

Google Play Console → Tu app → Producción → Crear nueva versión
Subir el .aab
Notas de la versión: "Versión inicial de SolucionaYa - Conecta con trabajadores verificados en Bucaramanga y Barrancabermeja."
Revisión de la política de datos: completar el formulario de seguridad de datos
Enviar para revisión (puede tomar 3–7 días la primera vez)

Mientras espera la revisión:

Publicar en Play Store con distribución limitada por países (solo Colombia)
Preparar la campaña de lanzamiento

DÍA 78–79 — Publicación en App Store + Monitoreo
Subir a App Store Connect:

Xcode → Archive → Upload to App Store Connect
En App Store Connect: completar todos los metadatos
Revisión: puede tomar 1–3 días
Si hay rechazo: leer el motivo, corregir y reenviar

Monitoreo post-lanzamiento:

Firebase Analytics: revisar primeros usuarios reales
Crashlytics: verificar que no hay crashes críticos
Firestore: revisar que los datos se están creando correctamente
Responder los primeros reportes del Admin Panel

DÍA 80 — Día de Lanzamiento Oficial 🎉
Acciones del día:

Verificar que las apps están activas en Play Store y App Store
Publicar en Instagram: "¡SolucionaYa ya está disponible en Bucaramanga!"
Enviar mensaje a los grupos de WhatsApp de trabajadores y testers
Compartir con los grupos de Facebook locales
Invitar a los 25+ trabajadores a activar sus perfiles
Monitorear el Admin Panel durante las primeras horas

Métricas a revisar en los primeros 7 días:

Descargas totales
Registros completados
Primer chat iniciado
Primer trabajador aprobado
Primer pago de sandbox

RESUMEN DE ENTREGABLES POR SEMANA
SemanaEntregable Principal1Setup Firebase + Flutter + Figma (primeras pantallas)2Figma completo + modelos de datos + rutas3Autenticación completa (cliente y trabajador)4Perfil del trabajador (edición, precios, galería, horario)5Perfil público + Home del cliente + Explorar + Favoritos6Chat en tiempo real + notificaciones push7Reseñas + reportes + deep links + modo offline8Pagos Wompi sandbox + estadísticas del trabajador9Admin Panel completo (Flutter Web)10Seguridad + App Check + polish + dark mode11Tests unitarios + widget tests + integration tests12Optimización + Play Store/App Store setup + manejo de errores13Beta cerrada + QA manual en dispositivos reales14-15Correcciones + seed de datos reales + preparación stores16Publicación oficial + monitoreo

COMANDOS DE REFERENCIA RÁPIDA
bash# Correr en debug con emuladores
firebase emulators:start &
flutter run --debug

# Generar código Riverpod

dart run build_runner watch --delete-conflicting-outputs

# Correr tests

flutter test # todos
flutter test test/data/ # solo modelos
flutter test integration_test/ -d emulator # integration

# Build Android release

flutter build appbundle --release

# Build iOS release (requiere Mac + Xcode)

flutter build ios --release

# Análisis de código

flutter analyze
flutter dart format lib/

# Correr Admin Panel en web

flutter run -d chrome --web-port 8080

# Ver logs de Firebase en tiempo real

firebase functions:log --only notifications

# Deploy de reglas de Firestore

firebase deploy --only firestore:rules

# Deploy de índices Firestore

firebase deploy --only firestore:indexes

# Deploy del Admin Panel en Firebase Hosting

flutter build web --target lib/main_admin.dart
firebase deploy --only hosting

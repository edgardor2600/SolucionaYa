# Estado actual del plan SolucionaYa

## Resumen ejecutivo

- Avance real consolidado: base cerrada hasta `Día 10`.
- Los `Días 5` y `6` no se hicieron en Figma porque el diseño se decidió construir directamente en código desde el inicio.
- Hay UI adelantada de forma parcial para `Día 16`, `Día 21`, `Día 22` y `Día 23`, pero todavía apoyada en mocks, placeholders o lógica incompleta.

## Lectura general

| Día del plan                                      | Estado actual            | Evidencia en archivos                                                                                                                                                                             | Prioridad siguiente                                                                                |
|---------------------------------------------------|--------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| Día 1 - Firebase + Proyecto Flutter               | Completo                 | `lib/main.dart`, `lib/firebase_options.dart`, `android/`, `ios/`, `web/`                                                                                                                          | Mantener estable                                                                                   |
| Día 2 - Estructura de carpetas + pubspec          | Completo                 | `lib/app/`, `lib/core/`, `lib/data/`, `lib/features/`, `pubspec.yaml`                                                                                                                             | Mantener orden y consistencia                                                                      |
| Día 3 - Tema global, colores y componentes base   | Parcial alto             | `lib/core/theme/app_theme.dart`, `lib/core/constants/app_colors.dart`, `lib/core/widgets/`                                                                                                        | Unificar uso de widgets base en pantallas                                                          |
| Día 4 - Firebase Emulator Suite                   | Completo                 | `firebase.json`, `lib/main.dart`, `lib/core/config/app_environment.dart`                                                                                                                          | Validar siempre en dispositivo real conexión al emulador                                           |
| Día 5 - Figma primeras pantallas                  | Omitido intencionalmente | El diseño se construyó directo en código                                                                                                                                                          | No aplica                                                                                          |
| Día 6 - Figma pantallas restantes                 | Omitido intencionalmente | El diseño se construyó directo en código                                                                                                                                                          | No aplica                                                                                          |
| Día 7 - Modelos de datos Dart                     | Completo                 | `lib/data/models/user_model.dart`, `worker_profile_model.dart`, `service_models.dart`, `category_model.dart`, `chat_model.dart`, `message_model.dart`, `report_model.dart`                        | Mantener consistencia al agregar nuevos campos                                                     |
| Día 8 - Sistema de rutas con go_router            | Parcial alto             | `lib/app/router.dart`, `lib/core/constants/app_routes.dart`, `lib/features/shell/`                                                                                                                | Faltan onboarding real, deep links y pantallas definitivas de auth                                 |
| Día 9 - Repositorios base + Auth Provider         | Completo                 | `lib/data/repositories/auth_repository.dart`, `user_repository.dart`, `lib/app/providers/auth_provider.dart`, `test/app/providers/auth_notifier_test.dart`                                        | Consumir estas bases cuando se construyan pantallas de rol, OTP y perfil                           |
| Día 10 - Workers Repo + Categories Repo           | Completo                 | `lib/data/repositories/worker_repository.dart`, `categories_repository.dart`, `lib/app/providers/workers_provider.dart`, `categories_provider.dart`                                               | UI de cliente/explorar conectada exitosamente a categoriesProvider                                 |
| Día 11 - Splash Screen + Onboarding               | Completo                 | `lib/features/auth/screens/splash_screen.dart`, `onboarding_screen.dart`                                                                                                                          | Mantener código y estado `hasSeenOnboarding` persistente                           |
| Día 12 - Selección de rol + Registro teléfono     | Completo                 | `select_role_screen.dart`, `phone_auth_screen.dart`, provider para rol         | Mantener limpieza y escalabilidad en flujo de Auth                 |
| Día 13 - OTP + Registro con Email                 | Completo                 | `otp_verification_screen.dart`, redirección dinámica por profile               | La base está firme, el router maneja la seguridad automáticamente  |
| Día 14 - Registro de perfil básico cliente        | Completo                 | `complete_profile_screen.dart`, rol dinámico con provider                      | UI premium y creación del documento de usuario en Firestore        |
| Día 15 - Registro de trabajador con documentos    | Completo                 | `worker_docs_screen.dart`, redirección dinámica en `router.dart`               | El perfil WorkerProfileModel se crea como inactivo (aprobación)    |
| 📍 Día 16 - Home del trabajador aprobado        | En Progreso              | `lib/features/home/screens/worker_home_screen.dart`, `lib/features/shell/worker_shell.dart` | Reemplazar placeholder por dashboard real y toggle de disponibilidad |
| Día 17 - Edición de perfil del trabajador         | No iniciado              | No existe pantalla de edición de perfil de trabajador                                                                                                                                             | Crear edición básica y cálculo de completitud                                                      |
| Día 18 - Sistema de precios CRUD                  | Parcial medio            | `PriceModel`, `worker_repository.dart`, `workers_provider.dart`                                                                                                                                   | Falta UI CRUD y conexión con pantallas del trabajador                                              |
| Día 19 - Galería de trabajos                      | Parcial medio            | `GalleryPhotoModel`, `worker_repository.dart`, `workers_provider.dart`                                                                                                                            | Falta UI de subida, viewer real y persistencia visual                                              |
| Día 20 - Horario de disponibilidad semanal        | Parcial bajo             | `DaySchedule` existe en `worker_profile_model.dart`; UI mock de horario en `worker_profile_detail_screen.dart`                                                                                    | Crear pantalla de edición y resumen real reutilizable                                              |
| Día 21 - Perfil público del trabajador            | Parcial medio            | `lib/features/worker_profile/screens/worker_profile_detail_screen.dart`                                                                                                                           | Conectar a datos reales, acciones reales y analytics                                               |
| Día 22 - Home del cliente                         | Parcial medio            | `lib/features/home/screens/client_home_screen.dart`                                                                                                                                               | Reemplazar mocks por streams/repos reales y navegación por categoría                               |
| Día 23 - Explorar + filtros                       | Parcial medio            | `lib/features/explore/screens/explore_screen.dart`, `lib/app/providers/workers_provider.dart`                                                                                                     | Conectar filtros a Firestore, búsqueda, paginación y ranking real                                  |
| Día 24 - Favoritos + perfil del cliente           | No iniciado              | Solo hay placeholder de perfil cliente en router                                                                                                                                                  | Crear módulo favoritos y perfil cliente                                                            |
| Día 25 - Distancia con Geolocator                 | No iniciado              | Dependencia existe en `pubspec.yaml` pero no hay servicio implementado                                                                                                                            | Crear `location_service` e integrar distancia                                                      |

## Diagnóstico práctico

### Lo que sí está firme

- Base Flutter + Firebase inicial.
- Tema global y estructura de carpetas.
- Emuladores con host configurable y seed inicial de categorías.
- Navegación base con guards de sesión y rol.
- Repositorios base de auth, usuario, workers y categorías.
- Modelos principales del dominio con pruebas de serialización.

### Lo que hoy impide decir que vamos más adelante

- El registro real por rol todavía no existe en UI.
- El onboarding todavía no existe.
- Hay pantallas adelantadas pero varias usan datos mock o placeholders.
- La UI cliente/trabajador todavía no consume de forma real todos los repos ya cerrados.

## Validación ejecutada

- `flutter test` pasó en:
  - `test/models/model_serialization_test.dart`
  - `test/core/utils/validators_test.dart`
  - `test/app/providers/auth_notifier_test.dart`
  - `test/data/repositories/categories_repository_test.dart`
  - `test/data/repositories/worker_repository_test.dart`
- `dart analyze` quedó limpio sobre el bloque refactorizado de días `1` a `10`.

## Qué deberías tener al probar en el celular

- Splash funcional.
- Login con email visible.
- Registro cliente con email visible.
- Cierre de sesión funcionando.
- Conexión a emuladores en modo debug.
- Seed automático de categorías en Firestore Emulator.
- Guards básicos: si no hay sesión debe mandar a login; si hay sesión pero no perfil debe proteger el flujo.

## Qué deberías probar en el celular

1. Abrir la app en debug y confirmar que no se cae al iniciar.
2. Verificar que el splash entra y luego navega a login cuando no hay sesión.
3. Crear una cuenta cliente con email y confirmar que entra a la app sin errores.
4. Revisar en Firestore Emulator que se cree `users/{uid}` con los campos esperados.
5. Cerrar sesión desde la app y confirmar que vuelve a login.
6. Volver a iniciar sesión con la cuenta creada y confirmar que entra correctamente.
7. Confirmar que no hay errores visuales raros por fuentes o tema.
8. Revisar en Firestore Emulator que exista la colección `categories` con las 8 categorías sembradas.
9. Confirmar que la app no muestra errores de conexión al emulador en el dispositivo.

## Orden sugerido para continuar

1. Construir `Días 11` a `15` usando la base cerrada de `Días 9` y `10`.
2. Luego conectar la UI adelantada de `Días 16` a `23` a repositorios reales.

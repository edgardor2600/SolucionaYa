import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'app/providers/shared_prefs_provider.dart';
import 'core/config/app_environment.dart';
import 'data/repositories/categories_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Inicializar Firebase ─────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Conectar a emuladores en modo debug ──────────────────────
  if (kDebugMode) {
    final emulatorHost = AppEnvironment.firebaseEmulatorHost;
    try {
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      // Sembrar categorías en segundo plano para no bloquear el inicio de la app
      FirebaseCategoriesRepository().seedDefaultCategories().catchError((e) {
        // ignore: avoid_print
        print('⚠️ Error al sembrar categorías: $e');
      });
      // ignore: avoid_print
      print('✅ Conectado a Firebase Emulator Suite en $emulatorHost');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Emuladores ya conectados o error: $e');
    }
  }

  // ── Configurar Crashlytics (no disponible en Web) ─────────────
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ── Inicializar SharedPreferences ─────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();

  // ── Arrancar la app envuelta en ProviderScope (Riverpod) ─────
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SolucionaYaApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Inicializar Firebase ─────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Conectar a emuladores en modo debug ──────────────────────
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      print('✅ Conectado a Firebase Emulator Suite');
    } catch (e) {
      print('⚠️ Error conectando a emuladores (probablemente ya conectados): $e');
    }
  }

  // ── Configurar Crashlytics ────────────────────────────────────
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Captura errores asincrónicos fuera del árbol de widgets
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── Arrancar la app envuelta en ProviderScope (Riverpod) ─────
  runApp(
    const ProviderScope(
      child: SolucionaYaApp(),
    ),
  );
}

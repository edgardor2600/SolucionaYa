import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // generado por flutterfire configure
import 'app/app.dart';
import 'app/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar Crashlytics: captura errores de Flutter automáticamente
  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SolucionaYaApp(),
    ),
  );
}

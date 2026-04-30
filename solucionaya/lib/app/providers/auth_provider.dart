import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

// ─── Repositories Providers ──────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository();
});

// ─── Auth State Providers ────────────────────────────────────────────────────

/// Escucha los cambios del usuario autenticado (Firebase Auth)
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Escucha el perfil de usuario de Firestore basado en el usuario autenticado
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUser(user.uid);
});

// ─── Auth Controller (Notifier) ──────────────────────────────────────────────

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(
    authRepo: ref.watch(authRepositoryProvider),
    userRepo: ref.watch(userRepositoryProvider),
  );
});

/// Controlador que expone métodos para interactuar con la autenticación
/// y maneja estados de carga localmente.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    required AuthRepository authRepo,
    required UserRepository userRepo,
  })  : _authRepo = authRepo,
        _userRepo = userRepo;

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Iniciar sesión con email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepo.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error inesperado.');
      _setLoading(false);
      return false;
    }
  }

  /// Registro de usuario cliente con email
  Future<bool> registerClientWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required String city,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // 1. Crear usuario en Firebase Auth
      final credential = await _authRepo.registerWithEmail(email, password);
      
      if (credential.user != null) {
        // 2. Crear el documento del usuario en Firestore (perfil)
        final userModel = UserModel(
          uid: credential.user!.uid,
          role: UserRole.client, // Por defecto al registrarse normal es cliente
          displayName: displayName,
          phone: phone,
          email: email,
          city: city,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isActive: true,
          fcmTokens: [],
        );
        await _userRepo.createUser(userModel);
      }
      
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } on UserRepositoryException catch (e) {
      _setError('Error al guardar el perfil: ${e.message}');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error inesperado durante el registro.');
      _setLoading(false);
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _authRepo.signOut();
  }
}

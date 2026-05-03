import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/worker_profile_model.dart';
import '../../data/repositories/worker_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository();
});

/// Escucha los cambios del usuario autenticado en Firebase Auth.
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Escucha el perfil persistido del usuario autenticado.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUser(user.uid);
});

/// Escucha el perfil de trabajador si el usuario es trabajador.
final currentWorkerProfileProvider = StreamProvider<WorkerProfileModel?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null || profile.role != UserRole.worker) {
    return Stream.value(null);
  }
  
  // Usamos FirebaseWorkerRepository directamente para evitar dependencia circular
  return FirebaseWorkerRepository().watchWorkerProfile(profile.uid);
});

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(
    authRepo: ref.watch(authRepositoryProvider),
    userRepo: ref.watch(userRepositoryProvider),
  );
});

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    required AuthRepository authRepo,
    required UserRepository userRepo,
  }) : _authRepo = authRepo,
       _userRepo = userRepo;

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  bool _isLoading = false;
  String? _error;
  String? _phoneVerificationId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get phoneVerificationId => _phoneVerificationId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _setPhoneVerificationId(String? verificationId) {
    _phoneVerificationId = verificationId;
    notifyListeners();
  }

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
    } catch (e, st) {
      debugPrint('Error inesperado durante el login: $e\n$st');
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepo.registerWithEmail(email, password);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, st) {
      debugPrint('Error inesperado durante el registro: $e\n$st');
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendOtp({required String phone}) async {
    _setLoading(true);
    _setError(null);
    try {
      final verificationId = await _authRepo.signInWithPhone(phone);
      _setPhoneVerificationId(verificationId);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, st) {
      debugPrint('Error inesperado enviando OTP: $e\n$st');
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp({required String otp, String? verificationId}) async {
    final effectiveVerificationId = verificationId ?? _phoneVerificationId;
    if (effectiveVerificationId == null || effectiveVerificationId.isEmpty) {
      _setError('No existe una verificacion pendiente.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _authRepo.verifyOtp(effectiveVerificationId, otp);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, st) {
      debugPrint('Error inesperado verificando OTP: $e\n$st');
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset({required String email}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepo.sendPasswordReset(email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, st) {
      debugPrint('Error inesperado enviando reset password: $e\n$st');
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCurrentAccount() async {
    final currentUser = _authRepo.currentUser;
    if (currentUser == null) {
      _setError('No hay una sesion activa.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _userRepo.deleteUser(currentUser.uid);
      await _authRepo.deleteAccount();
      _setPhoneVerificationId(null);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } on UserRepositoryException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, st) {
      debugPrint('Error inesperado eliminando cuenta: $e\n$st');
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _setPhoneVerificationId(null);
  }

  void clearTransientState() {
    _setError(null);
    _setPhoneVerificationId(null);
  }
}

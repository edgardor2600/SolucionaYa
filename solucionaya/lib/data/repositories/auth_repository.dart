import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Interfaz abstracta para la autenticación.
/// Mantiene la UI agnóstica de la implementación (Firebase, Supabase, etc.)
abstract class AuthRepository {
  /// Retorna un stream con los cambios de estado de sesión.
  Stream<User?> get authStateChanges;

  /// Retorna el usuario actual o nulo si no hay sesión activa.
  User? get currentUser;

  /// Inicia sesión con correo y contraseña.
  Future<UserCredential> signInWithEmail(String email, String password);

  /// Registra un nuevo usuario con correo y contraseña.
  Future<UserCredential> registerWithEmail(String email, String password);

  /// Inicia el flujo de verificación por teléfono y retorna el verificationId.
  Future<String> signInWithPhone(String phone);

  /// Verifica el OTP y autentica al usuario con la credencial resultante.
  Future<UserCredential> verifyOtp(String verificationId, String otp);

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordReset(String email);

  /// Elimina la cuenta autenticada actualmente.
  Future<void> deleteAccount();

  /// Cierra la sesión activa.
  Future<void> signOut();
}

/// Excepción personalizada para errores de autenticación.
class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, [this.code]);

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

/// Implementación concreta de [AuthRepository] usando Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.code);
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  @override
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.code);
    } catch (e) {
      throw AuthException('Ocurrió un error al registrar la cuenta.');
    }
  }

  @override
  Future<String> signInWithPhone(String phone) async {
    if (kIsWeb) {
      throw AuthException(
        'La autenticación por teléfono aún no está habilitada en Web.',
        'unsupported-platform',
      );
    }

    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _normalizePhone(phone),
        verificationCompleted: (credential) {
          final verificationId = credential.verificationId;
          if (!completer.isCompleted && verificationId != null) {
            completer.complete(verificationId);
          }
        },
        verificationFailed: (exception) {
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(
                _mapFirebaseErrorCode(exception.code),
                exception.code,
              ),
            );
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );

      return completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout:
            () =>
                throw AuthException(
                  'No se recibió el código a tiempo. Intenta nuevamente.',
                  'otp-timeout',
                ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.code);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'No se pudo iniciar la verificación por teléfono.',
        'phone-auth-error',
      );
    }
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.code);
    } catch (_) {
      throw AuthException(
        'No se pudo verificar el código ingresado.',
        'otp-verification-error',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.code);
    } catch (e) {
      throw AuthException('No se pudo enviar el correo de recuperación.');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No hay una sesión activa para eliminar.');
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.code);
    } catch (_) {
      throw AuthException('No se pudo eliminar la cuenta actual.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Error al intentar cerrar sesión.');
    }
  }

  /// Mapea los códigos de error de Firebase a mensajes amigables para el usuario.
  String _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son incorrectas.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado en otra cuenta.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
      case 'invalid-phone-number':
        return 'El número de teléfono no es válido.';
      case 'missing-phone-number':
        return 'Debes ingresar un número de teléfono.';
      case 'invalid-verification-code':
        return 'El código ingresado es incorrecto.';
      case 'session-expired':
        return 'El código expiró. Solicita uno nuevo.';
      case 'credential-already-in-use':
        return 'Esta credencial ya está asociada a otra cuenta.';
      case 'requires-recent-login':
        return 'Por seguridad debes volver a iniciar sesión antes de eliminar la cuenta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada por el administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Por favor intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu internet e intenta de nuevo.';
      default:
        return 'Ha ocurrido un error de autenticación ($code).';
    }
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('57') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '+57$digits';
    }
    return phone.trim();
  }
}

import 'package:firebase_auth/firebase_auth.dart';

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

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordReset(String email);

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
  Future<UserCredential> registerWithEmail(String email, String password) async {
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
}

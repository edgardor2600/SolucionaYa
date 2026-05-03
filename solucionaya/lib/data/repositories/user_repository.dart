import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Interfaz abstracta para la gestión de usuarios (Perfil general).
abstract class UserRepository {
  /// Obtiene un usuario por su [uid]. Retorna nulo si no existe.
  Future<UserModel?> getUser(String uid);

  /// Crea un nuevo registro de usuario en la base de datos.
  Future<void> createUser(UserModel user);

  /// Actualiza datos parciales de un usuario existente.
  Future<void> updateUser(String uid, Map<String, dynamic> data);

  /// Actualiza o registra un token de notificaciones push (FCM).
  Future<void> updateFcmToken(String uid, String token);

  /// Elimina el perfil persistido del usuario.
  Future<void> deleteUser(String uid);

  /// Escucha los cambios en tiempo real de un usuario.
  Stream<UserModel?> watchUser(String uid);
}

/// Excepción personalizada para errores del repositorio de usuarios.
class UserRepositoryException implements Exception {
  final String message;
  UserRepositoryException(this.message);

  @override
  String toString() => 'UserRepositoryException: $message';
}

/// Implementación concreta de [UserRepository] usando Cloud Firestore.
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _usersRef => _firestore.collection('users');

  @override
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;
      // Agregamos el uid al mapa por seguridad si no viene en los datos
      data['uid'] = doc.id;
      return UserModel.fromJson(data);
    } catch (e) {
      throw UserRepositoryException('Error al obtener el usuario: $e');
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    try {
      // Usamos set en lugar de add porque el ID del documento será el uid del usuario
      await _usersRef.doc(user.uid).set(user.toJson());
    } catch (e) {
      throw UserRepositoryException('Error al crear el perfil de usuario: $e');
    }
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      // Actualizamos automáticamente el campo de última actividad
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['lastActiveAt'] = FieldValue.serverTimestamp();

      await _usersRef.doc(uid).update(updatedData);
    } catch (e) {
      throw UserRepositoryException('Error al actualizar el usuario: $e');
    }
  }

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _usersRef.doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      throw UserRepositoryException(
        'Error al actualizar el token de notificaciones: $e',
      );
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
    } catch (e) {
      throw UserRepositoryException(
        'Error al eliminar el perfil de usuario: $e',
      );
    }
  }

  @override
  Stream<UserModel?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return UserModel.fromJson(data);
    });
  }
}

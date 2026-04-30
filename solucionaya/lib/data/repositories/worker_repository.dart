import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_profile_model.dart';

/// Interfaz abstracta para la gestión de perfiles de trabajadores.
/// Esta capa aísla la UI de la base de datos (Firestore).
abstract class WorkerRepository {
  /// Obtiene el perfil público de un trabajador por su [uid].
  Future<WorkerProfileModel?> getWorkerProfile(String uid);

  /// Crea un nuevo perfil de trabajador.
  Future<void> createWorkerProfile(WorkerProfileModel profile);

  /// Actualiza datos parciales del perfil de un trabajador.
  Future<void> updateWorkerProfile(String uid, Map<String, dynamic> data);

  /// Cambia el estado de disponibilidad actual del trabajador.
  Future<void> toggleAvailability(String uid, bool isAvailable);

  /// Busca trabajadores filtrando por parámetros.
  /// Implementa paginación simple y filtros.
  Future<List<WorkerProfileModel>> getWorkers({
    String? category,
    bool? availableNow,
    bool? verifiedOnly,
    String? sortBy, // 'rating', 'price_asc', 'jobs'
    int limit = 20,
  });

  /// Escucha en tiempo real el perfil de un trabajador específico.
  Stream<WorkerProfileModel?> watchWorkerProfile(String uid);
}

/// Excepción personalizada para el repositorio de trabajadores.
class WorkerRepositoryException implements Exception {
  final String message;
  WorkerRepositoryException(this.message);

  @override
  String toString() => 'WorkerRepositoryException: $message';
}

/// Implementación concreta usando Cloud Firestore.
class FirebaseWorkerRepository implements WorkerRepository {
  FirebaseWorkerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _workersRef => _firestore.collection('workers');

  @override
  Future<WorkerProfileModel?> getWorkerProfile(String uid) async {
    try {
      final doc = await _workersRef.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return WorkerProfileModel.fromJson(data);
    } catch (e) {
      throw WorkerRepositoryException('Error al obtener perfil del trabajador: $e');
    }
  }

  @override
  Future<void> createWorkerProfile(WorkerProfileModel profile) async {
    try {
      await _workersRef.doc(profile.uid).set(profile.toJson());
    } catch (e) {
      throw WorkerRepositoryException('Error al crear perfil de trabajador: $e');
    }
  }

  @override
  Future<void> updateWorkerProfile(String uid, Map<String, dynamic> data) async {
    try {
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _workersRef.doc(uid).update(updatedData);
    } catch (e) {
      throw WorkerRepositoryException('Error al actualizar perfil: $e');
    }
  }

  @override
  Future<void> toggleAvailability(String uid, bool isAvailable) async {
    try {
      await _workersRef.doc(uid).update({
        'isAvailableNow': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw WorkerRepositoryException('Error al cambiar disponibilidad: $e');
    }
  }

  @override
  Future<List<WorkerProfileModel>> getWorkers({
    String? category,
    bool? availableNow,
    bool? verifiedOnly,
    String? sortBy,
    int limit = 20,
  }) async {
    try {
      Query query = _workersRef;

      // ─── Aplicación de Filtros ───
      // Solo traemos perfiles activos y aprobados por seguridad e integridad
      query = query.where('isActive', isEqualTo: true);
      query = query.where('isApproved', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('primaryCategory', isEqualTo: category);
      }
      
      if (availableNow == true) {
        query = query.where('isAvailableNow', isEqualTo: true);
      }
      
      if (verifiedOnly == true) {
        query = query.where('isVerified', isEqualTo: true);
      }

      // ─── Aplicación de Ordenamiento ───
      switch (sortBy) {
        case 'rating':
          query = query.orderBy('rating', descending: true);
          break;
        case 'price_asc':
          query = query.orderBy('hourlyRate', descending: false);
          break;
        case 'jobs':
          query = query.orderBy('totalJobs', descending: true);
          break;
        default:
          // Por defecto ordenamos por los mejores rankeados primero
          query = query.orderBy('rating', descending: true);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return WorkerProfileModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw WorkerRepositoryException('Error al obtener lista de trabajadores: $e');
    }
  }

  @override
  Stream<WorkerProfileModel?> watchWorkerProfile(String uid) {
    return _workersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return WorkerProfileModel.fromJson(data);
    });
  }
}

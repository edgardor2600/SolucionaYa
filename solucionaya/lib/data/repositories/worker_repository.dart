import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_models.dart';
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

  /// Incrementa el contador de vistas del perfil.
  Future<void> incrementProfileViews(String uid);

  /// CRUD de precios del trabajador.
  Future<List<PriceModel>> getPrices(String uid);
  Future<void> addPrice(String uid, PriceModel price);
  Future<void> updatePrice(String uid, PriceModel price);
  Future<void> deletePrice(String uid, String priceId);

  /// CRUD de galería del trabajador.
  Future<List<GalleryPhotoModel>> getGallery(String uid);
  Future<void> addPhoto(String uid, GalleryPhotoModel photo);
  Future<void> deletePhoto(String uid, String photoId);
  Future<void> reorderPhotos(String uid, List<String> orderedIds);
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

  CollectionReference<Map<String, dynamic>> get _workersRef =>
      _firestore.collection('workers');

  CollectionReference<Map<String, dynamic>> _pricesRef(String uid) =>
      _workersRef.doc(uid).collection('prices');

  CollectionReference<Map<String, dynamic>> _galleryRef(String uid) =>
      _workersRef.doc(uid).collection('gallery');

  @override
  Future<WorkerProfileModel?> getWorkerProfile(String uid) async {
    try {
      final doc = await _workersRef.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return WorkerProfileModel.fromJson(data);
    } catch (e) {
      throw WorkerRepositoryException(
        'Error al obtener perfil del trabajador: $e',
      );
    }
  }

  @override
  Future<void> createWorkerProfile(WorkerProfileModel profile) async {
    try {
      await _workersRef.doc(profile.uid).set(profile.toJson());
    } catch (e) {
      throw WorkerRepositoryException(
        'Error al crear perfil de trabajador: $e',
      );
    }
  }

  @override
  Future<void> updateWorkerProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
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
      Query<Map<String, dynamic>> query = _workersRef;

      // Solo perfiles activos y aprobados para los listados públicos.
      query = query.where('isActive', isEqualTo: true);
      query = query.where('isApproved', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (availableNow == true) {
        query = query.where('isAvailableNow', isEqualTo: true);
      }

      if (verifiedOnly == true) {
        query = query.where('isVerified', isEqualTo: true);
      }

      switch (sortBy) {
        case 'rating':
          query = query.orderBy('rating', descending: true);
          break;
        case 'price_asc':
          query = query.orderBy('startingPrice');
          break;
        case 'jobs':
          query = query.orderBy('totalJobsDone', descending: true);
          break;
        default:
          query = query.orderBy('rating', descending: true);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return WorkerProfileModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw WorkerRepositoryException(
        'Error al obtener lista de trabajadores: $e',
      );
    }
  }

  @override
  Stream<WorkerProfileModel?> watchWorkerProfile(String uid) {
    return _workersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['uid'] = doc.id;
      return WorkerProfileModel.fromJson(data);
    });
  }

  @override
  Future<void> incrementProfileViews(String uid) async {
    try {
      await _workersRef.doc(uid).update({
        'profileViews': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw WorkerRepositoryException('Error al incrementar vistas: $e');
    }
  }

  @override
  Future<List<PriceModel>> getPrices(String uid) async {
    try {
      final snapshot = await _pricesRef(uid).orderBy('serviceName').get();
      return snapshot.docs
          .map((doc) => PriceModel.fromJson(doc.data()))
          .where((price) => price.isActive)
          .toList();
    } catch (e) {
      throw WorkerRepositoryException('Error al obtener precios: $e');
    }
  }

  @override
  Future<void> addPrice(String uid, PriceModel price) async {
    try {
      await _pricesRef(uid).doc(price.priceId).set(price.toJson());
    } catch (e) {
      throw WorkerRepositoryException('Error al agregar precio: $e');
    }
  }

  @override
  Future<void> updatePrice(String uid, PriceModel price) async {
    try {
      await _pricesRef(uid).doc(price.priceId).update(price.toJson());
    } catch (e) {
      throw WorkerRepositoryException('Error al actualizar precio: $e');
    }
  }

  @override
  Future<void> deletePrice(String uid, String priceId) async {
    try {
      await _pricesRef(uid).doc(priceId).delete();
    } catch (e) {
      throw WorkerRepositoryException('Error al eliminar precio: $e');
    }
  }

  @override
  Future<List<GalleryPhotoModel>> getGallery(String uid) async {
    try {
      final snapshot = await _galleryRef(uid).orderBy('order').get();
      return snapshot.docs
          .map((doc) => GalleryPhotoModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw WorkerRepositoryException('Error al obtener galería: $e');
    }
  }

  @override
  Future<void> addPhoto(String uid, GalleryPhotoModel photo) async {
    try {
      await _galleryRef(uid).doc(photo.photoId).set(photo.toJson());
    } catch (e) {
      throw WorkerRepositoryException('Error al agregar foto: $e');
    }
  }

  @override
  Future<void> deletePhoto(String uid, String photoId) async {
    try {
      await _galleryRef(uid).doc(photoId).delete();
    } catch (e) {
      throw WorkerRepositoryException('Error al eliminar foto: $e');
    }
  }

  @override
  Future<void> reorderPhotos(String uid, List<String> orderedIds) async {
    try {
      final batch = _firestore.batch();
      for (var index = 0; index < orderedIds.length; index++) {
        batch.update(_galleryRef(uid).doc(orderedIds[index]), {'order': index});
      }
      await batch.commit();
    } catch (e) {
      throw WorkerRepositoryException('Error al reordenar fotos: $e');
    }
  }
}

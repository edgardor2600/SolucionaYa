import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/worker_profile_model.dart';
import '../../app/providers/auth_provider.dart';

/// Interfaz para la gestión de favoritos del cliente.
abstract class FavoritesRepository {
  /// Obtiene un stream con los IDs de los trabajadores favoritos de un cliente.
  Stream<List<String>> watchFavoriteIds(String clientUid);

  /// Obtiene un stream con los perfiles completos de los trabajadores favoritos.
  Stream<List<WorkerProfileModel>> watchFavorites(String clientUid);

  /// Agrega o elimina un trabajador de la lista de favoritos.
  Future<void> toggleFavorite(String clientUid, String workerUid, bool isFavorite);

  /// Verifica si un trabajador es favorito.
  Future<bool> isFavorite(String clientUid, String workerUid);
}

/// Implementación de Favoritos usando Cloud Firestore.
class FirebaseFavoritesRepository implements FavoritesRepository {
  FirebaseFavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _favoritesRef(String clientUid) =>
      _firestore.collection('favorites').doc(clientUid).collection('items');

  @override
  Stream<List<String>> watchFavoriteIds(String clientUid) {
    return _favoritesRef(clientUid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  Stream<List<WorkerProfileModel>> watchFavorites(String clientUid) {
    return _favoritesRef(clientUid).snapshots().asyncMap((snapshot) async {
      final workerIds = snapshot.docs.map((doc) => doc.id).toList();
      if (workerIds.isEmpty) return [];

      // Consultar perfiles de trabajadores correspondientes a los favoritos
      final List<WorkerProfileModel> workers = [];
      for (final id in workerIds) {
        final doc = await _firestore.collection('workers').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['uid'] = doc.id;
          workers.add(WorkerProfileModel.fromJson(data));
        }
      }
      return workers;
    });
  }

  @override
  Future<void> toggleFavorite(String clientUid, String workerUid, bool isFavorite) async {
    final docRef = _favoritesRef(clientUid).doc(workerUid);
    if (isFavorite) {
      await docRef.set({
        'workerId': workerUid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  @override
  Future<bool> isFavorite(String clientUid, String workerUid) async {
    final doc = await _favoritesRef(clientUid).doc(workerUid).get();
    return doc.exists;
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FirebaseFavoritesRepository();
});

/// StreamProvider que expone la lista de IDs de trabajadores favoritos del usuario autenticado.
final favoriteIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(favoritesRepositoryProvider).watchFavoriteIds(user.uid);
});

/// StreamProvider que expone los perfiles de los trabajadores favoritos en tiempo real.
final favoriteWorkersProvider = StreamProvider<List<WorkerProfileModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(favoritesRepositoryProvider).watchFavorites(user.uid);
});

/// Family provider para saber si un trabajador específico es favorito del usuario actual.
final isWorkerFavoriteProvider = StreamProvider.family<bool, String>((ref, workerId) {
  final favoriteIdsAsync = ref.watch(favoriteIdsProvider);
  return favoriteIdsAsync.when(
    data: (ids) => Stream.value(ids.contains(workerId)),
    loading: () => Stream.value(false),
    error: (_, __) => Stream.value(false),
  );
});

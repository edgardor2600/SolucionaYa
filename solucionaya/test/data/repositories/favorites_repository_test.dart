import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/data/models/worker_profile_model.dart';
import 'package:solucionaya/features/favorites/favorites_repository.dart';

void main() {
  group('FirebaseFavoritesRepository Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseFavoritesRepository repository;

    const clientUid = 'client-123';
    const workerUid = 'worker-456';

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseFavoritesRepository(firestore: firestore);

      // Sembrar un perfil de trabajador de prueba
      await firestore.collection('workers').doc(workerUid).set({
        'displayName': 'Mauricio Plomero',
        'category': 'plomeria',
        'city': 'Bucaramanga',
        'isActive': true,
        'isAvailableNow': true,
        'isVerified': true,
        'isApproved': true,
        'totalReviews': 10,
        'rating': 4.7,
        'totalJobsDone': 45,
        'profileCompleteness': 90,
      });
    });

    test('isFavorite retorna false si el trabajador no es favorito', () async {
      final result = await repository.isFavorite(clientUid, workerUid);
      expect(result, isFalse);
    });

    test('toggleFavorite agrega el trabajador a favoritos correctamente', () async {
      // 1. Agregar a favoritos
      await repository.toggleFavorite(clientUid, workerUid, true);

      // 2. Verificar existencia
      final result = await repository.isFavorite(clientUid, workerUid);
      expect(result, isTrue);

      // 3. Verificar estructura en base de datos
      final doc = await firestore
          .collection('favorites')
          .doc(clientUid)
          .collection('items')
          .doc(workerUid)
          .get();
      
      expect(doc.exists, isTrue);
      expect(doc.data()?['workerId'], workerUid);
    });

    test('toggleFavorite remueve el trabajador de favoritos correctamente', () async {
      // 1. Agregar
      await repository.toggleFavorite(clientUid, workerUid, true);
      expect(await repository.isFavorite(clientUid, workerUid), isTrue);

      // 2. Remover
      await repository.toggleFavorite(clientUid, workerUid, false);

      // 3. Verificar eliminación
      expect(await repository.isFavorite(clientUid, workerUid), isFalse);
      
      final doc = await firestore
          .collection('favorites')
          .doc(clientUid)
          .collection('items')
          .doc(workerUid)
          .get();
      expect(doc.exists, isFalse);
    });

    test('watchFavoriteIds expone los IDs en tiempo real', () async {
      final stream = repository.watchFavoriteIds(clientUid);

      // Emitir primero lista vacía
      expect(stream, emits(isEmpty));

      // Agregar uno y verificar que el stream reacciona
      await repository.toggleFavorite(clientUid, workerUid, true);
      expect(stream, emits([workerUid]));
    });

    test('watchFavorites expone los perfiles completos en tiempo real', () async {
      final stream = repository.watchFavorites(clientUid);

      // Emitir primero lista vacía
      expect(stream, emits(isEmpty));

      // Agregar favorito y verificar perfil emitido
      await repository.toggleFavorite(clientUid, workerUid, true);
      
      final emittedProfilesList = await stream.first;
      expect(emittedProfilesList, hasLength(1));
      expect(emittedProfilesList.single.displayName, 'Mauricio Plomero');
      expect(emittedProfilesList.single.category, ServiceCategory.plomeria);
    });
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/data/models/service_models.dart';
import 'package:solucionaya/data/models/worker_profile_model.dart';
import 'package:solucionaya/data/repositories/worker_repository.dart';

void main() {
  group('FirebaseWorkerRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseWorkerRepository repository;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseWorkerRepository(firestore: firestore);

      await repository.createWorkerProfile(
        WorkerProfileModel(
          uid: 'worker-1',
          displayName: 'Carlos',
          category: ServiceCategory.plomeria,
          city: 'Bucaramanga',
          createdAt: DateTime(2026, 4, 30),
          updatedAt: DateTime(2026, 4, 30),
          isActive: true,
          isAvailableNow: true,
          isVerified: true,
          isApproved: true,
          totalReviews: 20,
          rating: 4.9,
          totalJobsDone: 100,
          profileViews: 3,
          responseTimeMinutes: 10,
          profileCompleteness: 95,
          startingPrice: 50000,
        ),
      );

      await repository.createWorkerProfile(
        WorkerProfileModel(
          uid: 'worker-2',
          displayName: 'Luis',
          category: ServiceCategory.electricidad,
          city: 'Bucaramanga',
          createdAt: DateTime(2026, 4, 30),
          updatedAt: DateTime(2026, 4, 30),
          isActive: true,
          isAvailableNow: false,
          isVerified: false,
          isApproved: true,
          totalReviews: 5,
          rating: 4.2,
          totalJobsDone: 20,
          profileViews: 1,
          responseTimeMinutes: 30,
          profileCompleteness: 70,
          startingPrice: 65000,
        ),
      );
    });

    test('filtra workers por categoria y verificados', () async {
      final workers = await repository.getWorkers(
        category: 'plomeria',
        verifiedOnly: true,
      );

      expect(workers, hasLength(1));
      expect(workers.single.uid, 'worker-1');
    });

    test('toggleAvailability actualiza el perfil', () async {
      await repository.toggleAvailability('worker-2', true);
      final worker = await repository.getWorkerProfile('worker-2');

      expect(worker?.isAvailableNow, isTrue);
    });

    test('incrementProfileViews suma el contador', () async {
      await repository.incrementProfileViews('worker-1');
      final worker = await repository.getWorkerProfile('worker-1');

      expect(worker?.profileViews, 4);
    });

    test('CRUD de precios funciona', () async {
      const price = PriceModel(
        priceId: 'price-1',
        serviceName: 'Destape',
        category: 'plomeria',
        unit: PriceUnit.porVisita,
        priceMin: 50000,
        isActive: true,
      );

      await repository.addPrice('worker-1', price);
      final prices = await repository.getPrices('worker-1');

      expect(prices, hasLength(1));
      expect(prices.single.serviceName, 'Destape');
    });

    test('CRUD de galeria funciona', () async {
      final photo = GalleryPhotoModel(
        photoId: 'photo-1',
        url: 'https://example.com/photo.jpg',
        uploadedAt: DateTime(2026, 4, 30),
        order: 0,
      );

      await repository.addPhoto('worker-1', photo);
      final gallery = await repository.getGallery('worker-1');

      expect(gallery, hasLength(1));
      expect(gallery.single.photoId, 'photo-1');
    });
  });
}

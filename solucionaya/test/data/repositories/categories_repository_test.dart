import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/data/repositories/categories_repository.dart';

void main() {
  group('FirebaseCategoriesRepository', () {
    test('siembra y lee las categorias por defecto', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirebaseCategoriesRepository(firestore: firestore);

      await repository.seedDefaultCategories();
      final categories = await repository.getCategories();

      expect(categories, hasLength(8));
      expect(categories.first.categoryId, 'plomeria');
    });

    test('usa fallback local si firestore esta vacio', () async {
      final repository = FirebaseCategoriesRepository(
        firestore: FakeFirebaseFirestore(),
      );

      final categories = await repository.getCategories();

      expect(categories, hasLength(8));
    });
  });
}

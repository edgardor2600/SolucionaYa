import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/price_helpers.dart';
import '../models/category_model.dart';
import '../models/worker_profile_model.dart';

abstract class CategoriesRepository {
  Future<List<CategoryModel>> getCategories();
  Stream<List<CategoryModel>> watchCategories();
  Future<void> seedDefaultCategories();
}

class CategoriesRepositoryException implements Exception {
  CategoriesRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'CategoriesRepositoryException: $message';
}

class FirebaseCategoriesRepository implements CategoriesRepository {
  FirebaseCategoriesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  List<CategoryModel>? _memoryCache;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      return _memoryCache!;
    }

    try {
      final snapshot = await _categoriesRef.orderBy('sortOrder').get();
      if (snapshot.docs.isEmpty) {
        _memoryCache = _defaultCategories;
        return _memoryCache!;
      }

      _memoryCache =
          snapshot.docs
              .map((doc) => CategoryModel.fromJson(doc.data()))
              .where((category) => category.isActive)
              .toList();
      return _memoryCache!;
    } catch (e) {
      throw CategoriesRepositoryException('Error al obtener categorías: $e');
    }
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    return _categoriesRef.orderBy('sortOrder').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        _memoryCache = _defaultCategories;
        return _memoryCache!;
      }

      _memoryCache =
          snapshot.docs
              .map((doc) => CategoryModel.fromJson(doc.data()))
              .where((category) => category.isActive)
              .toList();
      return _memoryCache!;
    });
  }

  @override
  Future<void> seedDefaultCategories() async {
    try {
      final batch = _firestore.batch();
      for (final category in _defaultCategories) {
        batch.set(
          _categoriesRef.doc(category.categoryId),
          category.toJson(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      _memoryCache = _defaultCategories;
    } catch (e) {
      throw CategoriesRepositoryException('Error al sembrar categorías: $e');
    }
  }

  List<CategoryModel> get _defaultCategories {
    final categories = ServiceCategory.values.toList();
    return List<CategoryModel>.generate(categories.length, (index) {
      final category = categories[index];
      return CategoryModel(
        categoryId: category.name,
        name: category.label,
        iconKey: category.name,
        colorValue: category.color.toARGB32(),
        suggestedPriceMin: category.suggestedPriceMin,
        suggestedPriceMax: category.suggestedPriceMax,
        suggestedUnit: category.suggestedUnit,
        sortOrder: index,
      );
    });
  }
}

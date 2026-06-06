import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../data/models/worker_profile_model.dart';
import '../../../data/services/location_service.dart';
import '../domain/explore_filter_model.dart';

// Estado para almacenar los filtros activos
final exploreFilterProvider = StateProvider<ExploreFilterModel>((ref) {
  return const ExploreFilterModel();
});

// Estado que maneja la lógica de exploración (paginación, filtrado, ranking)
class ExploreState {
  ExploreState({
    this.workers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<WorkerProfileModel> workers;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  ExploreState copyWith({
    List<WorkerProfileModel>? workers,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return ExploreState(
      workers: workers ?? this.workers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  ExploreNotifier(this.ref) : super(ExploreState()) {
    // Al iniciar, cargamos los primeros resultados
    loadMore();
  }

  final Ref ref;
  DocumentSnapshot? _lastDocument;

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading || (!state.hasMore && !refresh)) return;

    if (refresh) {
      _lastDocument = null;
      state = ExploreState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final filters = ref.read(exploreFilterProvider);
      final clientProfile = ref.read(currentUserProfileProvider).value;

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('workers');
      
      // Filtros básicos en DB
      query = query.where('isActive', isEqualTo: true);
      query = query.where('isApproved', isEqualTo: true);
      
      if (filters.category != null && filters.category!.isNotEmpty) {
        query = query.where('category', isEqualTo: filters.category);
      }
      if (filters.availableNowOnly) {
        query = query.where('isAvailableNow', isEqualTo: true);
      }
      if (filters.verifiedOnly) {
        query = query.where('isVerified', isEqualTo: true);
      }
      
      // Paginación
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      query = query.limit(20); // Traemos lotes de 20 para tener buen margen al filtrar localmente

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      final newWorkers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return WorkerProfileModel.fromJson(data);
      }).toList();

      // FILTROS LOCALES (Opción A: Búsqueda de texto y distancia)
      List<WorkerProfileModel> filteredWorkers = newWorkers;

      // 1. Filtro de Texto (Buscador)
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final queryText = filters.searchQuery!.toLowerCase();
        filteredWorkers = filteredWorkers.where((w) {
          final matchName = w.displayName.toLowerCase().contains(queryText);
          final matchCategory = w.category.label.toLowerCase().contains(queryText);
          return matchName || matchCategory;
        }).toList();
      }

      // 2. Filtro de Distancia
      final currentPosition = ref.read(userLocationProvider).value;
      double? clientLat = currentPosition?.latitude ?? clientProfile?.latitude;
      double? clientLng = currentPosition?.longitude ?? clientProfile?.longitude;
      
      if (filters.maxDistanceKm != null && clientLat != null && clientLng != null) {
        filteredWorkers = filteredWorkers.where((w) {
          if (w.latitude == null || w.longitude == null) return false;
          final distKm = Geolocator.distanceBetween(clientLat, clientLng, w.latitude!, w.longitude!) / 1000;
          return distKm <= filters.maxDistanceKm!;
        }).toList();
      }

      // 3. Filtro de Rating Mínimo
      if (filters.minRating > 0) {
        filteredWorkers = filteredWorkers.where((w) => w.rating >= filters.minRating).toList();
      }

      // 4. Filtro de Precio Máximo
      if (filters.maxPrice != null) {
        filteredWorkers = filteredWorkers.where((w) {
          if (w.startingPrice == null) return false; // Podríamos decidir mostrarlos, pero si filtran por precio, esperan ver precios.
          return w.startingPrice! <= filters.maxPrice!;
        }).toList();
      }

      // ORDENAMIENTO LOCAL (Ranking Score)
      filteredWorkers.sort((a, b) {
        double distA = (clientLat != null && clientLng != null && a.latitude != null && a.longitude != null)
            ? Geolocator.distanceBetween(clientLat, clientLng, a.latitude!, a.longitude!) / 1000 : 0;
        double distB = (clientLat != null && clientLng != null && b.latitude != null && b.longitude != null)
            ? Geolocator.distanceBetween(clientLat, clientLng, b.latitude!, b.longitude!) / 1000 : 0;
        
        final scoreA = _calculateRankingScore(a, distA);
        final scoreB = _calculateRankingScore(b, distB);
        return scoreB.compareTo(scoreA); // Descendente
      });

      final allWorkers = refresh ? filteredWorkers : [...state.workers, ...filteredWorkers];

      state = state.copyWith(
        workers: allWorkers,
        isLoading: false,
        hasMore: snapshot.docs.length == 20, // Si vinieron menos de 20, ya no hay más
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  double _calculateRankingScore(WorkerProfileModel worker, double distanceKm) {
    double score = 0;
    if (worker.isAvailableNow) score += 10;
    if (worker.isVerified) score += 8;
    score += (worker.profileCompleteness / 100) * 10;
    score += worker.rating * 2; // Multiplicamos por 2 para darle más peso
    score += math.log(worker.totalReviews + 1) * 3;
    if (worker.responseTimeMinutes != null && worker.responseTimeMinutes! < 30) score += 2;
    
    // Penalizar por distancia (ej. 1 km resta 0.3 puntos)
    if (distanceKm > 0) {
      score -= distanceKm * 0.3;
    }
    return score;
  }
}

final exploreNotifierProvider = StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  return ExploreNotifier(ref);
});

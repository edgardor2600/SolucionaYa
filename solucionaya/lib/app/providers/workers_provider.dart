import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/service_models.dart';
import '../../data/models/worker_profile_model.dart';
import '../../data/repositories/worker_repository.dart';
import 'auth_provider.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return FirebaseWorkerRepository();
});

// ─── Parámetros de filtro encapsulados ────────────────────────────────────────

/// Agrupa los filtros activos para la búsqueda de trabajadores.
/// Se mantiene inmutable para compatibilidad con Riverpod.
class WorkerFilter {
  const WorkerFilter({
    this.category,
    this.availableNow = false,
    this.verifiedOnly = false,
    this.sortBy = 'rating',
    this.limit = 20,
  });

  final String? category;
  final bool availableNow;
  final bool verifiedOnly;
  final String sortBy;
  final int limit;

  WorkerFilter copyWith({
    String? category,
    bool? availableNow,
    bool? verifiedOnly,
    String? sortBy,
    int? limit,
    bool clearCategory = false,
  }) {
    return WorkerFilter(
      category: clearCategory ? null : (category ?? this.category),
      availableNow: availableNow ?? this.availableNow,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkerFilter &&
      other.category == category &&
      other.availableNow == availableNow &&
      other.verifiedOnly == verifiedOnly &&
      other.sortBy == sortBy &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(category, availableNow, verifiedOnly, sortBy, limit);
}

// ─── Filter State Notifier ───────────────────────────────────────────────────

/// Notifier que gestiona el estado del filtro activo.
class WorkerFilterNotifier extends Notifier<WorkerFilter> {
  @override
  WorkerFilter build() => const WorkerFilter();

  void setCategory(String? category) {
    state =
        category == null
            ? state.copyWith(clearCategory: true)
            : state.copyWith(category: category);
  }

  void toggleAvailableNow() {
    state = state.copyWith(availableNow: !state.availableNow);
  }

  void toggleVerifiedOnly() {
    state = state.copyWith(verifiedOnly: !state.verifiedOnly);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void reset() {
    state = const WorkerFilter();
  }
}

final workerFilterProvider =
    NotifierProvider<WorkerFilterNotifier, WorkerFilter>(
      WorkerFilterNotifier.new,
    );

// ─── Workers List Provider (FutureProvider) ───────────────────────────────────

/// Carga la lista de trabajadores según los filtros activos.
/// Se recalcula automáticamente cuando cambia [workerFilterProvider].
final workersProvider = FutureProvider.autoDispose<List<WorkerProfileModel>>((
  ref,
) async {
  final filter = ref.watch(workerFilterProvider);
  final repo = ref.watch(workerRepositoryProvider);

  return repo.getWorkers(
    category: filter.category,
    availableNow: filter.availableNow ? true : null,
    verifiedOnly: filter.verifiedOnly ? true : null,
    sortBy: filter.sortBy,
    limit: filter.limit,
  );
});

// ─── Home Screen Specialized Providers ──────────────────────────────────────────

/// Obtiene los trabajadores que están "Disponibles ahora" (límite 10).
final availableWorkersProvider = FutureProvider.autoDispose<List<WorkerProfileModel>>((ref) async {
  final repo = ref.watch(workerRepositoryProvider);
  return repo.getWorkers(
    availableNow: true,
    sortBy: 'rating',
    limit: 10,
  );
});

/// Obtiene los trabajadores ordenados por cercanía real.
final nearbyWorkersProvider = FutureProvider.autoDispose<List<WorkerProfileModel>>((ref) async {
  final repo = ref.watch(workerRepositoryProvider);
  final clientProfile = ref.watch(currentUserProfileProvider).value;
  
  // Obtenemos todos los trabajadores activos (o un límite grande)
  final allWorkers = await repo.getWorkers(limit: 50);

  if (clientProfile?.latitude == null || clientProfile?.longitude == null) {
    // Si el cliente no tiene ubicación, simplemente los devolvemos tal cual o vacíos
    return allWorkers.take(10).toList();
  }

  final clientLat = clientProfile!.latitude!;
  final clientLng = clientProfile.longitude!;

  // Calculamos la distancia para cada uno y los ordenamos
  final workersWithDistance = allWorkers.where((w) => w.latitude != null && w.longitude != null).toList();
  
  workersWithDistance.sort((a, b) {
    final distA = Geolocator.distanceBetween(clientLat, clientLng, a.latitude!, a.longitude!);
    final distB = Geolocator.distanceBetween(clientLat, clientLng, b.latitude!, b.longitude!);
    return distA.compareTo(distB);
  });

  return workersWithDistance.take(10).toList();
});

// ─── Single Worker Profile Provider ──────────────────────────────────────────

/// Stream en tiempo real del perfil de un trabajador específico.
final workerProfileProvider = StreamProvider.autoDispose
    .family<WorkerProfileModel?, String>((ref, uid) {
      final repo = ref.watch(workerRepositoryProvider);
      return repo.watchWorkerProfile(uid);
    });

/// Lectura de un solo trabajador (sin stream, para uso estático).
final workerProfileOnceProvider = FutureProvider.autoDispose
    .family<WorkerProfileModel?, String>((ref, uid) {
      final repo = ref.watch(workerRepositoryProvider);
      return repo.getWorkerProfile(uid);
    });

final workerPricesProvider = FutureProvider.autoDispose
    .family<List<PriceModel>, String>((ref, uid) {
      final repo = ref.watch(workerRepositoryProvider);
      return repo.getPrices(uid);
    });

final workerGalleryProvider = FutureProvider.autoDispose
    .family<List<GalleryPhotoModel>, String>((ref, uid) {
      final repo = ref.watch(workerRepositoryProvider);
      return repo.getGallery(uid);
    });

final workerScheduleProvider = FutureProvider.autoDispose
    .family<ScheduleModel, String>((ref, uid) {
      final repo = ref.watch(workerRepositoryProvider);
      return repo.getSchedule(uid);
    });

// ─── Public Profile Unified Provider ──────────────────────────────────────────

/// Agrupa todos los datos necesarios para mostrar el perfil público de un trabajador.
class WorkerPublicProfileData {
  const WorkerPublicProfileData({
    required this.profile,
    required this.prices,
    required this.gallery,
    required this.schedule,
  });

  final WorkerProfileModel profile;
  final List<PriceModel> prices;
  final List<GalleryPhotoModel> gallery;
  final ScheduleModel schedule;
}

/// Descarga el perfil completo, precios, galería y horario en paralelo.
final workerPublicProfileProvider = FutureProvider.autoDispose
    .family<WorkerPublicProfileData, String>((ref, uid) async {
  
  // Ejecutamos las 4 consultas en paralelo para mayor rapidez
  final results = await Future.wait([
    ref.watch(workerProfileOnceProvider(uid).future),
    ref.watch(workerPricesProvider(uid).future),
    ref.watch(workerGalleryProvider(uid).future),
    ref.watch(workerScheduleProvider(uid).future),
  ]);

  final profile = results[0] as WorkerProfileModel?;
  
  if (profile == null) {
    throw Exception('No se encontró el perfil del trabajador.');
  }

  return WorkerPublicProfileData(
    profile: profile,
    prices: results[1] as List<PriceModel>,
    gallery: results[2] as List<GalleryPhotoModel>,
    schedule: results[3] as ScheduleModel,
  );
});

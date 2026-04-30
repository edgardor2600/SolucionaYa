import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/worker_profile_model.dart';
import '../../data/repositories/worker_repository.dart';

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
  int get hashCode => Object.hash(
      category, availableNow, verifiedOnly, sortBy, limit);
}

// ─── Filter State Notifier ───────────────────────────────────────────────────

/// Notifier que gestiona el estado del filtro activo.
class WorkerFilterNotifier extends Notifier<WorkerFilter> {
  @override
  WorkerFilter build() => const WorkerFilter();

  void setCategory(String? category) {
    state = category == null
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
final workersProvider =
    FutureProvider.autoDispose<List<WorkerProfileModel>>((ref) async {
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

// ─── Single Worker Profile Provider ──────────────────────────────────────────

/// Stream en tiempo real del perfil de un trabajador específico.
final workerProfileProvider =
    StreamProvider.autoDispose.family<WorkerProfileModel?, String>(
  (ref, uid) {
    final repo = ref.watch(workerRepositoryProvider);
    return repo.watchWorkerProfile(uid);
  },
);

/// Lectura de un solo trabajador (sin stream, para uso estático).
final workerProfileOnceProvider =
    FutureProvider.autoDispose.family<WorkerProfileModel?, String>(
  (ref, uid) {
    final repo = ref.watch(workerRepositoryProvider);
    return repo.getWorkerProfile(uid);
  },
);

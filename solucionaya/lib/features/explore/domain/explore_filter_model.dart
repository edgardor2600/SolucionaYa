class ExploreFilterModel {
  const ExploreFilterModel({
    this.category,
    this.availableNowOnly = false,
    this.verifiedOnly = false,
    this.minRating = 0.0,
    this.maxPrice,
    this.maxDistanceKm,
    this.searchQuery,
  });

  final String? category;
  final bool availableNowOnly;
  final bool verifiedOnly;
  final double minRating;
  final double? maxPrice;
  final double? maxDistanceKm;
  final String? searchQuery;

  ExploreFilterModel copyWith({
    String? category,
    bool? availableNowOnly,
    bool? verifiedOnly,
    double? minRating,
    double? maxPrice,
    double? maxDistanceKm,
    String? searchQuery,
    bool clearCategory = false,
    bool clearMaxDistanceKm = false,
  }) {
    return ExploreFilterModel(
      category: clearCategory ? null : (category ?? this.category),
      availableNowOnly: availableNowOnly ?? this.availableNowOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistanceKm: clearMaxDistanceKm ? null : (maxDistanceKm ?? this.maxDistanceKm),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Comprueba si hay algún filtro activo además de la categoría
  bool get hasActiveFilters => 
    availableNowOnly || 
    verifiedOnly || 
    minRating > 0 || 
    maxPrice != null || 
    maxDistanceKm != null;
}

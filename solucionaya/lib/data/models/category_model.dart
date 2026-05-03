class CategoryModel {
  const CategoryModel({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.suggestedPriceMin,
    required this.suggestedPriceMax,
    required this.suggestedUnit,
    required this.sortOrder,
    this.isActive = true,
  });

  final String categoryId;
  final String name;
  final String iconKey;
  final int colorValue;
  final int suggestedPriceMin;
  final int suggestedPriceMax;
  final String suggestedUnit;
  final int sortOrder;
  final bool isActive;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] as String,
      name: json['name'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0,
      suggestedPriceMin: (json['suggestedPriceMin'] as num?)?.toInt() ?? 0,
      suggestedPriceMax: (json['suggestedPriceMax'] as num?)?.toInt() ?? 0,
      suggestedUnit: json['suggestedUnit'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'suggestedPriceMin': suggestedPriceMin,
      'suggestedPriceMax': suggestedPriceMax,
      'suggestedUnit': suggestedUnit,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  CategoryModel copyWith({
    String? categoryId,
    String? name,
    String? iconKey,
    int? colorValue,
    int? suggestedPriceMin,
    int? suggestedPriceMax,
    String? suggestedUnit,
    int? sortOrder,
    bool? isActive,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      suggestedPriceMin: suggestedPriceMin ?? this.suggestedPriceMin,
      suggestedPriceMax: suggestedPriceMax ?? this.suggestedPriceMax,
      suggestedUnit: suggestedUnit ?? this.suggestedUnit,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

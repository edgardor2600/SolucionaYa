import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categorías de servicio disponibles en la plataforma.
enum ServiceCategory {
  plomeria,
  electricidad,
  cerrajeria,
  aseo,
  pintura,
  camaras,
  computadores,
  enchape;

  String get label {
    const labels = {
      ServiceCategory.plomeria: 'Plomería',
      ServiceCategory.electricidad: 'Electricidad',
      ServiceCategory.cerrajeria: 'Cerrajería',
      ServiceCategory.aseo: 'Aseo',
      ServiceCategory.pintura: 'Pintura',
      ServiceCategory.camaras: 'Cámaras',
      ServiceCategory.computadores: 'Computadores',
      ServiceCategory.enchape: 'Enchape',
    };
    return labels[this]!;
  }

  IconData get icon {
    const icons = {
      ServiceCategory.plomeria: Icons.plumbing,
      ServiceCategory.electricidad: Icons.bolt,
      ServiceCategory.cerrajeria: Icons.lock,
      ServiceCategory.aseo: Icons.cleaning_services,
      ServiceCategory.pintura: Icons.format_paint,
      ServiceCategory.camaras: Icons.videocam,
      ServiceCategory.computadores: Icons.computer,
      ServiceCategory.enchape: Icons.grid_on,
    };
    return icons[this]!;
  }

  Color get color {
    const colors = {
      ServiceCategory.plomeria: Color(0xFF1565C0),
      ServiceCategory.electricidad: Color(0xFFF57F17),
      ServiceCategory.cerrajeria: Color(0xFF4E342E),
      ServiceCategory.aseo: Color(0xFF00897B),
      ServiceCategory.pintura: Color(0xFF6A1B9A),
      ServiceCategory.camaras: Color(0xFF1B5E20),
      ServiceCategory.computadores: Color(0xFF0277BD),
      ServiceCategory.enchape: Color(0xFF558B2F),
    };
    return colors[this]!;
  }

  static ServiceCategory fromString(String value) {
    return ServiceCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ServiceCategory.plomeria,
    );
  }
}

/// Esquema de disponibilidad por día de la semana.
class DaySchedule {
  const DaySchedule({required this.isAvailable, this.startTime, this.endTime});

  final bool isAvailable;
  final String? startTime; // formato "HH:mm"
  final String? endTime;

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isAvailable: json['isAvailable'] as bool? ?? false,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'isAvailable': isAvailable,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
  };

  DaySchedule copyWith({
    bool? isAvailable,
    String? startTime,
    String? endTime,
  }) {
    return DaySchedule(
      isAvailable: isAvailable ?? this.isAvailable,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// Perfil completo de un trabajador.
/// Almacenado en Firestore bajo /workers/{uid}
class WorkerProfileModel {
  const WorkerProfileModel({
    required this.uid,
    required this.displayName,
    required this.category,
    required this.city,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isAvailableNow,
    required this.isVerified,
    required this.isApproved,
    required this.totalReviews,
    required this.rating,
    required this.totalJobsDone,
    required this.profileViews,
    required this.responseTimeMinutes,
    required this.profileCompleteness,
    this.photoUrl,
    this.bio,
    this.yearsExperience = 0,
    this.shareableSlug,
    this.startingPrice,
    this.availableSchedule = const {},
    this.tags = const [],
    this.pendingReason,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final ServiceCategory category;
  final String city;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isAvailableNow;
  final bool isVerified;
  final bool isApproved;
  final int totalReviews;
  final double rating;
  final int totalJobsDone;
  final int profileViews;
  final int responseTimeMinutes;
  final int profileCompleteness; // 0-100
  final int yearsExperience;
  final String? shareableSlug;
  final double? startingPrice; // valor desnormalizado para listados y orden
  final Map<String, DaySchedule> availableSchedule; // key: "monday", "tuesday"…
  final List<String> tags;
  final String? pendingReason; // por qué está pendiente de aprobación

  // ── Helpers de UI ────────────────────────────────────────────────
  String get ratingDisplay => rating.toStringAsFixed(1);
  bool get isFullyCompleted => profileCompleteness >= 100;
  String get responseTimeLabel {
    if (responseTimeMinutes < 60) return '< ${responseTimeMinutes}min';
    return '< ${(responseTimeMinutes / 60).ceil()}h';
  }

  // ── Serialización ────────────────────────────────────────────────
  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    final scheduleRaw =
        json['availableSchedule'] as Map<String, dynamic>? ?? {};
    return WorkerProfileModel(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      category: ServiceCategory.fromString(
        json['category'] as String? ?? 'plomeria',
      ),
      city: json['city'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isActive: json['isActive'] as bool? ?? true,
      isAvailableNow: json['isAvailableNow'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobsDone: (json['totalJobsDone'] as num?)?.toInt() ?? 0,
      profileViews: (json['profileViews'] as num?)?.toInt() ?? 0,
      responseTimeMinutes: (json['responseTimeMinutes'] as num?)?.toInt() ?? 30,
      profileCompleteness: (json['profileCompleteness'] as num?)?.toInt() ?? 0,
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      shareableSlug: json['shareableSlug'] as String?,
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      availableSchedule: scheduleRaw.map(
        (k, v) => MapEntry(k, DaySchedule.fromJson(v as Map<String, dynamic>)),
      ),
      tags: List<String>.from(json['tags'] as List? ?? []),
      pendingReason: json['pendingReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (bio != null) 'bio': bio,
      'category': category.name,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isAvailableNow': isAvailableNow,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'totalReviews': totalReviews,
      'rating': rating,
      'totalJobsDone': totalJobsDone,
      'profileViews': profileViews,
      'responseTimeMinutes': responseTimeMinutes,
      'profileCompleteness': profileCompleteness,
      'yearsExperience': yearsExperience,
      if (shareableSlug != null) 'shareableSlug': shareableSlug,
      if (startingPrice != null) 'startingPrice': startingPrice,
      'availableSchedule': availableSchedule.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'tags': tags,
      if (pendingReason != null) 'pendingReason': pendingReason,
    };
  }

  WorkerProfileModel copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    String? bio,
    ServiceCategory? category,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isAvailableNow,
    bool? isVerified,
    bool? isApproved,
    int? totalReviews,
    double? rating,
    int? totalJobsDone,
    int? profileViews,
    int? responseTimeMinutes,
    int? profileCompleteness,
    int? yearsExperience,
    String? shareableSlug,
    double? startingPrice,
    Map<String, DaySchedule>? availableSchedule,
    List<String>? tags,
    String? pendingReason,
  }) {
    return WorkerProfileModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      category: category ?? this.category,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isAvailableNow: isAvailableNow ?? this.isAvailableNow,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      totalReviews: totalReviews ?? this.totalReviews,
      rating: rating ?? this.rating,
      totalJobsDone: totalJobsDone ?? this.totalJobsDone,
      profileViews: profileViews ?? this.profileViews,
      responseTimeMinutes: responseTimeMinutes ?? this.responseTimeMinutes,
      profileCompleteness: profileCompleteness ?? this.profileCompleteness,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      shareableSlug: shareableSlug ?? this.shareableSlug,
      startingPrice: startingPrice ?? this.startingPrice,
      availableSchedule: availableSchedule ?? this.availableSchedule,
      tags: tags ?? this.tags,
      pendingReason: pendingReason ?? this.pendingReason,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkerProfileModel && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;
}

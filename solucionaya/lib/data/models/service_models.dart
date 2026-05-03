import 'package:cloud_firestore/cloud_firestore.dart';

/// Unidad de cobro de un servicio.
enum PriceUnit {
  porHora,
  porVisita,
  porMetro,
  porUnidad,
  porDia,
  aTratar;

  String get label {
    const labels = {
      PriceUnit.porHora: 'por hora',
      PriceUnit.porVisita: 'por visita',
      PriceUnit.porMetro: 'por metro',
      PriceUnit.porUnidad: 'por unidad',
      PriceUnit.porDia: 'por día',
      PriceUnit.aTratar: 'a tratar',
    };
    return labels[this]!;
  }

  static PriceUnit fromString(String value) {
    return PriceUnit.values.firstWhere(
      (u) => u.name == value,
      orElse: () => PriceUnit.porHora,
    );
  }
}

/// Servicio con precio ofrecido por un trabajador.
class PriceModel {
  const PriceModel({
    required this.priceId,
    required this.serviceName,
    required this.category,
    required this.unit,
    required this.priceMin,
    required this.isActive,
    this.priceMax,
    this.notes,
    this.currency = 'COP',
  });

  final String priceId;
  final String serviceName;
  final String category;
  final PriceUnit unit;
  final double priceMin;
  final double? priceMax;
  final String currency;
  final String? notes;
  final bool isActive;

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      priceId: json['priceId'] as String,
      serviceName: json['serviceName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      unit: PriceUnit.fromString(json['unit'] as String? ?? 'porHora'),
      priceMin: (json['priceMin'] as num?)?.toDouble() ?? 0.0,
      priceMax: (json['priceMax'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'COP',
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'priceId': priceId,
    'serviceName': serviceName,
    'category': category,
    'unit': unit.name,
    'priceMin': priceMin,
    if (priceMax != null) 'priceMax': priceMax,
    'currency': currency,
    if (notes != null) 'notes': notes,
    'isActive': isActive,
  };

  PriceModel copyWith({
    String? priceId,
    String? serviceName,
    String? category,
    PriceUnit? unit,
    double? priceMin,
    double? priceMax,
    String? currency,
    String? notes,
    bool? isActive,
  }) {
    return PriceModel(
      priceId: priceId ?? this.priceId,
      serviceName: serviceName ?? this.serviceName,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Foto de la galería del trabajador.
class GalleryPhotoModel {
  const GalleryPhotoModel({
    required this.photoId,
    required this.url,
    required this.uploadedAt,
    required this.order,
    this.thumbnailUrl,
    this.caption,
    this.category,
  });

  final String photoId;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final String? category;
  final DateTime uploadedAt;
  final int order;

  factory GalleryPhotoModel.fromJson(Map<String, dynamic> json) {
    return GalleryPhotoModel(
      photoId: json['photoId'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: json['caption'] as String?,
      category: json['category'] as String?,
      uploadedAt:
          json['uploadedAt'] is Timestamp
              ? (json['uploadedAt'] as Timestamp).toDate()
              : DateTime.now(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'photoId': photoId,
    'url': url,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (caption != null) 'caption': caption,
    if (category != null) 'category': category,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'order': order,
  };

  GalleryPhotoModel copyWith({
    String? photoId,
    String? url,
    String? thumbnailUrl,
    String? caption,
    String? category,
    DateTime? uploadedAt,
    int? order,
  }) {
    return GalleryPhotoModel(
      photoId: photoId ?? this.photoId,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      category: category ?? this.category,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      order: order ?? this.order,
    );
  }
}

/// Reseña de un cliente sobre un trabajador.
class ReviewModel {
  const ReviewModel({
    required this.reviewId,
    required this.workerId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.clientPhotoUrl,
    this.workerReply,
    this.workerReplyAt,
  });

  final String reviewId;
  final String workerId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? workerReply;
  final DateTime? workerReplyAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] as String,
      workerId: json['workerId'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String? ?? '',
      clientPhotoUrl: json['clientPhotoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String? ?? '',
      createdAt:
          json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      workerReply: json['workerReply'] as String?,
      workerReplyAt:
          json['workerReplyAt'] != null
              ? (json['workerReplyAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'reviewId': reviewId,
    'workerId': workerId,
    'clientId': clientId,
    'clientName': clientName,
    if (clientPhotoUrl != null) 'clientPhotoUrl': clientPhotoUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
    if (workerReply != null) 'workerReply': workerReply,
    if (workerReplyAt != null)
      'workerReplyAt': Timestamp.fromDate(workerReplyAt!),
  };

  ReviewModel copyWith({
    String? reviewId,
    String? workerId,
    String? clientId,
    String? clientName,
    String? clientPhotoUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? workerReply,
    DateTime? workerReplyAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      workerId: workerId ?? this.workerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhotoUrl: clientPhotoUrl ?? this.clientPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      workerReply: workerReply ?? this.workerReply,
      workerReplyAt: workerReplyAt ?? this.workerReplyAt,
    );
  }
}

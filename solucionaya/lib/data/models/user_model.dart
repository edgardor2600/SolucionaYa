import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum de roles de usuario en el sistema.
enum UserRole {
  client,
  worker,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.client,
    );
  }
}

/// Modelo principal de usuario, compartido por clientes, trabajadores y admins.
/// Los trabajadores también tienen un [WorkerProfileModel] separado en Firestore.
class UserModel {
  const UserModel({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.phone,
    required this.city,
    required this.createdAt,
    required this.lastActiveAt,
    required this.isActive,
    required this.fcmTokens,
    this.photoUrl,
    this.email,
    this.isSuspended = false,
    this.suspendedReason,
    this.acceptedTermsAt,
  });

  final String uid;
  final UserRole role;
  final String displayName;
  final String? photoUrl;
  final String phone;
  final String? email;
  final String city;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isActive;
  final bool isSuspended;
  final String? suspendedReason;
  final List<String> fcmTokens;
  final DateTime? acceptedTermsAt;

  // ── Serialización ──────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'client'),
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      city: json['city'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      lastActiveAt: _parseDate(json['lastActiveAt']),
      isActive: json['isActive'] as bool? ?? true,
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspendedReason: json['suspendedReason'] as String?,
      fcmTokens: List<String>.from(json['fcmTokens'] as List? ?? []),
      acceptedTermsAt: json['acceptedTermsAt'] != null
          ? _parseDate(json['acceptedTermsAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role.name,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'phone': phone,
      if (email != null) 'email': email,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'isActive': isActive,
      'isSuspended': isSuspended,
      if (suspendedReason != null) 'suspendedReason': suspendedReason,
      'fcmTokens': fcmTokens,
      if (acceptedTermsAt != null)
        'acceptedTermsAt': Timestamp.fromDate(acceptedTermsAt!),
    };
  }

  UserModel copyWith({
    String? uid,
    UserRole? role,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? email,
    String? city,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isActive,
    bool? isSuspended,
    String? suspendedReason,
    List<String>? fcmTokens,
    DateTime? acceptedTermsAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      acceptedTermsAt: acceptedTermsAt ?? this.acceptedTermsAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;
}

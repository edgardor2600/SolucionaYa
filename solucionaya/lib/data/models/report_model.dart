import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  pending,
  reviewed,
  resolved,
  rejected;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

class ReportModel {
  const ReportModel({
    required this.reportId,
    required this.reporterUid,
    required this.targetUid,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.status,
    this.chatId,
    this.reviewerUid,
    this.resolutionNotes,
  });

  final String reportId;
  final String reporterUid;
  final String targetUid;
  final String reason;
  final String description;
  final DateTime createdAt;
  final ReportStatus status;
  final String? chatId;
  final String? reviewerUid;
  final String? resolutionNotes;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'] as String,
      reporterUid: json['reporterUid'] as String? ?? '',
      targetUid: json['targetUid'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      status: ReportStatus.fromString(json['status'] as String? ?? 'pending'),
      chatId: json['chatId'] as String?,
      reviewerUid: json['reviewerUid'] as String?,
      resolutionNotes: json['resolutionNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reporterUid': reporterUid,
      'targetUid': targetUid,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      if (chatId != null) 'chatId': chatId,
      if (reviewerUid != null) 'reviewerUid': reviewerUid,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
    };
  }

  ReportModel copyWith({
    String? reportId,
    String? reporterUid,
    String? targetUid,
    String? reason,
    String? description,
    DateTime? createdAt,
    ReportStatus? status,
    String? chatId,
    String? reviewerUid,
    String? resolutionNotes,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      reporterUid: reporterUid ?? this.reporterUid,
      targetUid: targetUid ?? this.targetUid,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      chatId: chatId ?? this.chatId,
      reviewerUid: reviewerUid ?? this.reviewerUid,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

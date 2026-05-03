import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  none,
  pending,
  paid,
  rejected;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.none,
    );
  }
}

class ChatModel {
  const ChatModel({
    required this.chatId,
    required this.clientUid,
    required this.workerUid,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCountClient,
    required this.unreadCountWorker,
    required this.paymentStatus,
    required this.canReview,
    this.lastMessageText,
    this.lastMessageSenderUid,
    this.lastMessageAt,
  });

  final String chatId;
  final String clientUid;
  final String workerUid;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCountClient;
  final int unreadCountWorker;
  final PaymentStatus paymentStatus;
  final bool canReview;
  final String? lastMessageText;
  final String? lastMessageSenderUid;
  final DateTime? lastMessageAt;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'] as String,
      clientUid: json['clientUid'] as String? ?? '',
      workerUid: json['workerUid'] as String? ?? '',
      category: json['category'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      unreadCountClient: (json['unreadCountClient'] as num?)?.toInt() ?? 0,
      unreadCountWorker: (json['unreadCountWorker'] as num?)?.toInt() ?? 0,
      paymentStatus: PaymentStatus.fromString(
        json['paymentStatus'] as String? ?? 'none',
      ),
      canReview: json['canReview'] as bool? ?? false,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageSenderUid: json['lastMessageSenderUid'] as String?,
      lastMessageAt:
          json['lastMessageAt'] != null
              ? _parseDate(json['lastMessageAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'clientUid': clientUid,
      'workerUid': workerUid,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCountClient': unreadCountClient,
      'unreadCountWorker': unreadCountWorker,
      'paymentStatus': paymentStatus.name,
      'canReview': canReview,
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageSenderUid != null)
        'lastMessageSenderUid': lastMessageSenderUid,
      if (lastMessageAt != null)
        'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
    };
  }

  ChatModel copyWith({
    String? chatId,
    String? clientUid,
    String? workerUid,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCountClient,
    int? unreadCountWorker,
    PaymentStatus? paymentStatus,
    bool? canReview,
    String? lastMessageText,
    String? lastMessageSenderUid,
    DateTime? lastMessageAt,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      clientUid: clientUid ?? this.clientUid,
      workerUid: workerUid ?? this.workerUid,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCountClient: unreadCountClient ?? this.unreadCountClient,
      unreadCountWorker: unreadCountWorker ?? this.unreadCountWorker,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      canReview: canReview ?? this.canReview,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderUid: lastMessageSenderUid ?? this.lastMessageSenderUid,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

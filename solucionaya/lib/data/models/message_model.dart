import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  location,
  payment;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageModel {
  const MessageModel({
    required this.messageId,
    required this.senderUid,
    required this.type,
    required this.sentAt,
    this.text,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.paymentData,
    this.readAt,
  });

  final String messageId;
  final String senderUid;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? paymentData;
  final DateTime sentAt;
  final DateTime? readAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] as String,
      senderUid: json['senderUid'] as String? ?? '',
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      paymentData:
          json['paymentData'] != null
              ? Map<String, dynamic>.from(json['paymentData'] as Map)
              : null,
      sentAt: _parseDate(json['sentAt']),
      readAt: json['readAt'] != null ? _parseDate(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderUid': senderUid,
      'type': type.name,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (paymentData != null) 'paymentData': paymentData,
      'sentAt': Timestamp.fromDate(sentAt),
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? senderUid,
    MessageType? type,
    String? text,
    String? imageUrl,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? paymentData,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderUid: senderUid ?? this.senderUid,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      paymentData: paymentData ?? this.paymentData,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

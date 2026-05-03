import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/data/models/category_model.dart';
import 'package:solucionaya/data/models/chat_model.dart';
import 'package:solucionaya/data/models/message_model.dart';
import 'package:solucionaya/data/models/report_model.dart';
import 'package:solucionaya/data/models/service_models.dart';
import 'package:solucionaya/data/models/user_model.dart';
import 'package:solucionaya/data/models/worker_profile_model.dart';

void main() {
  group('UserModel', () {
    test('serializa y deserializa correctamente', () {
      final now = DateTime(2026, 4, 30, 8, 0);
      final model = UserModel(
        uid: 'user-1',
        role: UserRole.client,
        displayName: 'Maria Gomez',
        phone: '3001234567',
        email: 'maria@test.com',
        city: 'Bucaramanga',
        createdAt: now,
        lastActiveAt: now,
        isActive: true,
        fcmTokens: const ['token-1'],
      );

      final json = model.toJson();
      final parsed = UserModel.fromJson(json);

      expect(parsed.uid, model.uid);
      expect(parsed.role, model.role);
      expect(parsed.displayName, model.displayName);
      expect(parsed.fcmTokens, model.fcmTokens);
    });
  });

  group('WorkerProfileModel', () {
    test('mantiene campos clave al serializar', () {
      final now = DateTime(2026, 4, 30, 9, 30);
      final model = WorkerProfileModel(
        uid: 'worker-1',
        displayName: 'Carlos Medina',
        category: ServiceCategory.plomeria,
        city: 'Bucaramanga',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        isAvailableNow: true,
        isVerified: true,
        isApproved: true,
        totalReviews: 10,
        rating: 4.8,
        totalJobsDone: 25,
        profileViews: 100,
        responseTimeMinutes: 15,
        profileCompleteness: 90,
        yearsExperience: 8,
        startingPrice: 50000,
        availableSchedule: const {
          'monday': DaySchedule(
            isAvailable: true,
            startTime: '08:00',
            endTime: '18:00',
          ),
        },
        tags: const ['Destapes'],
      );

      final parsed = WorkerProfileModel.fromJson(model.toJson());

      expect(parsed.uid, model.uid);
      expect(parsed.category, model.category);
      expect(parsed.isActive, isTrue);
      expect(parsed.startingPrice, 50000);
      expect(parsed.availableSchedule['monday']?.startTime, '08:00');
    });
  });

  group('Service models', () {
    test('PriceModel copyWith conserva y sobreescribe campos', () {
      const model = PriceModel(
        priceId: 'price-1',
        serviceName: 'Destape',
        category: 'plomeria',
        unit: PriceUnit.porVisita,
        priceMin: 50000,
        isActive: true,
      );

      final updated = model.copyWith(priceMax: 70000);

      expect(updated.priceId, model.priceId);
      expect(updated.priceMax, 70000);
    });

    test('GalleryPhotoModel serializa correctamente', () {
      final now = DateTime(2026, 4, 30, 10, 0);
      final model = GalleryPhotoModel(
        photoId: 'photo-1',
        url: 'https://example.com/photo.jpg',
        uploadedAt: now,
        order: 1,
        caption: 'Trabajo terminado',
      );

      final parsed = GalleryPhotoModel.fromJson(model.toJson());

      expect(parsed.photoId, model.photoId);
      expect(parsed.caption, model.caption);
      expect(parsed.order, 1);
    });

    test('ReviewModel serializa y conserva respuesta del trabajador', () {
      final now = DateTime(2026, 4, 30, 10, 30);
      final model = ReviewModel(
        reviewId: 'review-1',
        workerId: 'worker-1',
        clientId: 'client-1',
        clientName: 'Ana',
        rating: 5,
        comment: 'Excelente',
        createdAt: now,
        workerReply: 'Gracias',
        workerReplyAt: now,
      );

      final parsed = ReviewModel.fromJson(model.toJson());

      expect(parsed.reviewId, model.reviewId);
      expect(parsed.workerReply, 'Gracias');
    });
  });

  group('Additional models', () {
    test('CategoryModel serializa correctamente', () {
      const model = CategoryModel(
        categoryId: 'plomeria',
        name: 'Plomeria',
        iconKey: 'plomeria',
        colorValue: 0xFF1565C0,
        suggestedPriceMin: 50000,
        suggestedPriceMax: 300000,
        suggestedUnit: 'por servicio',
        sortOrder: 0,
      );

      final parsed = CategoryModel.fromJson(model.toJson());

      expect(parsed.categoryId, model.categoryId);
      expect(parsed.suggestedPriceMax, 300000);
    });

    test('ChatModel serializa timestamps y enum', () {
      final now = DateTime(2026, 4, 30, 11, 0);
      final model = ChatModel(
        chatId: 'chat-1',
        clientUid: 'client-1',
        workerUid: 'worker-1',
        category: 'plomeria',
        createdAt: now,
        updatedAt: now,
        unreadCountClient: 0,
        unreadCountWorker: 1,
        paymentStatus: PaymentStatus.pending,
        canReview: false,
        lastMessageAt: now,
      );

      final parsed = ChatModel.fromJson(model.toJson());

      expect(parsed.chatId, model.chatId);
      expect(parsed.paymentStatus, PaymentStatus.pending);
      expect(parsed.lastMessageAt, isNotNull);
    });

    test('MessageModel serializa ubicación y pago', () {
      final now = DateTime(2026, 4, 30, 11, 30);
      final model = MessageModel(
        messageId: 'msg-1',
        senderUid: 'client-1',
        type: MessageType.location,
        latitude: 7.125,
        longitude: -73.119,
        paymentData: const {'amount': 50000},
        sentAt: now,
      );

      final parsed = MessageModel.fromJson(model.toJson());

      expect(parsed.messageId, model.messageId);
      expect(parsed.latitude, closeTo(7.125, 0.0001));
      expect(parsed.paymentData?['amount'], 50000);
    });

    test('ReportModel serializa estado y metadata', () {
      final now = DateTime(2026, 4, 30, 12, 0);
      final model = ReportModel(
        reportId: 'report-1',
        reporterUid: 'client-1',
        targetUid: 'worker-1',
        reason: 'spam',
        description: 'Contenido engañoso',
        createdAt: now,
        status: ReportStatus.pending,
      );

      final parsed = ReportModel.fromJson(model.toJson());

      expect(parsed.reportId, model.reportId);
      expect(parsed.status, ReportStatus.pending);
    });
  });

  group('Timestamp compatibility', () {
    test('fromJson acepta Timestamp explícito', () {
      final parsed = UserModel.fromJson({
        'uid': 'user-2',
        'role': 'client',
        'displayName': 'Pedro Ruiz',
        'phone': '3000000000',
        'city': 'Giron',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'lastActiveAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'isActive': true,
        'fcmTokens': const [],
      });

      expect(parsed.createdAt.year, 2026);
      expect(parsed.lastActiveAt.day, 2);
    });
  });
}

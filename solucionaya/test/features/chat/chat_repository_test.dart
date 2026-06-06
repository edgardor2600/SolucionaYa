import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/data/models/chat_model.dart';
import 'package:solucionaya/data/models/message_model.dart';
import 'package:solucionaya/data/models/user_model.dart';
import 'package:solucionaya/features/chat/data/repositories/chat_repository.dart';

void main() {
  group('FirebaseChatRepository Unit Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseChatRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseChatRepository(firestore: firestore);
    });

    test('createOrGetChat crea un chat nuevo si no existe', () async {
      final chat = await repository.createOrGetChat(
        clientUid: 'client-123',
        workerUid: 'worker-456',
        category: 'plomeria',
      );

      expect(chat.chatId, isNotEmpty);
      expect(chat.clientUid, 'client-123');
      expect(chat.workerUid, 'worker-456');
      expect(chat.category, 'plomeria');
      expect(chat.paymentStatus, PaymentStatus.none);

      // Verificar que se haya guardado en la base de datos
      final doc = await firestore.collection('chats').doc(chat.chatId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['category'], 'plomeria');
    });

    test('createOrGetChat devuelve el chat existente si ya existe', () async {
      final chat1 = await repository.createOrGetChat(
        clientUid: 'client-123',
        workerUid: 'worker-456',
        category: 'plomeria',
      );

      final chat2 = await repository.createOrGetChat(
        clientUid: 'client-123',
        workerUid: 'worker-456',
        category: 'plomeria',
      );

      expect(chat1.chatId, chat2.chatId);
    });

    test('watchChats filtra correctamente por clientUid y workerUid según el rol', () async {
      await repository.createOrGetChat(
        clientUid: 'client-1',
        workerUid: 'worker-1',
        category: 'plomeria',
      );

      await repository.createOrGetChat(
        clientUid: 'client-1',
        workerUid: 'worker-2',
        category: 'aseo',
      );

      await repository.createOrGetChat(
        clientUid: 'client-2',
        workerUid: 'worker-1',
        category: 'electricidad',
      );

      // Para cliente-1
      final clientChats = await repository.watchChats('client-1', UserRole.client).first;
      expect(clientChats, hasLength(2));

      // Para worker-1
      final workerChats = await repository.watchChats('worker-1', UserRole.worker).first;
      expect(workerChats, hasLength(2));
    });

    test('sendMessage agrega mensaje y actualiza metadatos del chat principal de forma atómica', () async {
      final chat = await repository.createOrGetChat(
        clientUid: 'client-1',
        workerUid: 'worker-1',
        category: 'plomeria',
      );

      final message = MessageModel(
        messageId: '',
        senderUid: 'client-1',
        type: MessageType.text,
        text: 'Hola Carlos, ¿cómo estás?',
        sentAt: DateTime.now(),
      );

      await repository.sendMessage(chat.chatId, message, UserRole.client);

      // Verificar que el mensaje se guardó en la subcolección
      final messagesSnapshot = await firestore
          .collection('chats')
          .doc(chat.chatId)
          .collection('messages')
          .get();
      
      expect(messagesSnapshot.docs, hasLength(1));
      expect(messagesSnapshot.docs.first.data()['text'], 'Hola Carlos, ¿cómo estás?');

      // Verificar que el chat padre tiene actualizados los campos de lastMessage
      final chatDoc = await firestore.collection('chats').doc(chat.chatId).get();
      expect(chatDoc.data()?['lastMessageText'], 'Hola Carlos, ¿cómo estás?');
      expect(chatDoc.data()?['lastMessageSenderUid'], 'client-1');
      expect(chatDoc.data()?['unreadCountWorker'], 1); // Incrementado para el trabajador
      expect(chatDoc.data()?['unreadCountClient'], 0); // Cliente no debe incrementarse
    });

    test('markAsRead resetea el contador del rol correspondiente', () async {
      final chat = await repository.createOrGetChat(
        clientUid: 'client-1',
        workerUid: 'worker-1',
        category: 'plomeria',
      );

      // Simular que el cliente envía un mensaje
      final message = MessageModel(
        messageId: '',
        senderUid: 'client-1',
        type: MessageType.text,
        text: 'Hola',
        sentAt: DateTime.now(),
      );

      await repository.sendMessage(chat.chatId, message, UserRole.client);

      // Verificar que el worker tiene 1 mensaje no leído
      var doc = await firestore.collection('chats').doc(chat.chatId).get();
      expect(doc.data()?['unreadCountWorker'], 1);

      // Marcar como leído para el worker
      await repository.markAsRead(chat.chatId, UserRole.worker);

      // Verificar que el contador se reseteó a 0
      doc = await firestore.collection('chats').doc(chat.chatId).get();
      expect(doc.data()?['unreadCountWorker'], 0);
    });

    test('updatePaymentProposalStatus actualiza el estado del mensaje y habilita reseñas en el chat principal al ser pagado', () async {
      final chat = await repository.createOrGetChat(
        clientUid: 'client-1',
        workerUid: 'worker-1',
        category: 'plomeria',
      );

      // Enviar propuesta de pago
      final message = MessageModel(
        messageId: 'msg-payment-1',
        senderUid: 'worker-1',
        type: MessageType.payment,
        paymentData: {
          'title': 'Reparación de grifería',
          'amount': 85000.0,
          'notes': 'Incluye materiales',
          'status': 'pending',
        },
        sentAt: DateTime.now(),
      );

      // Enviar el mensaje. Note que sendMessage genera un nuevo ID en Firestore.
      await repository.sendMessage(chat.chatId, message, UserRole.worker);

      // Recuperar el ID del mensaje autogenerado
      final messagesSnapshot = await firestore
          .collection('chats')
          .doc(chat.chatId)
          .collection('messages')
          .get();
      final generatedMsgId = messagesSnapshot.docs.first.id;

      // Actualizar a pagado
      await repository.updatePaymentProposalStatus(
        chat.chatId,
        generatedMsgId,
        PaymentStatus.paid,
      );

      // Verificar actualización en la subcolección de mensajes
      final updatedMsgDoc = await firestore
          .collection('chats')
          .doc(chat.chatId)
          .collection('messages')
          .doc(generatedMsgId)
          .get();
      
      final paymentMap = Map<String, dynamic>.from(updatedMsgDoc.data()?['paymentData'] as Map);
      expect(paymentMap['status'], 'paid');

      // Verificar actualización en el documento padre de chat
      final updatedChatDoc = await firestore.collection('chats').doc(chat.chatId).get();
      expect(updatedChatDoc.data()?['paymentStatus'], 'paid');
      expect(updatedChatDoc.data()?['canReview'], isTrue);
    });
  });
}

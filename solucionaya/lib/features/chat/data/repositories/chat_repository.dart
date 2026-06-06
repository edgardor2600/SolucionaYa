import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/chat_model.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';

abstract class ChatRepository {
  /// Obtiene o crea una conversación entre un cliente y un trabajador para una categoría de servicio.
  Future<ChatModel> createOrGetChat({
    required String clientUid,
    required String workerUid,
    required String category,
  });

  /// Escucha en tiempo real la lista de conversaciones de un usuario (filtrando por rol).
  Stream<List<ChatModel>> watchChats(String userUid, UserRole role);

  /// Escucha en tiempo real los mensajes de una conversación, ordenados de forma descendente por fecha.
  Stream<List<MessageModel>> watchMessages(String chatId);

  /// Envía un mensaje en una conversación y actualiza el último mensaje del chat de manera atómica.
  Future<void> sendMessage(String chatId, MessageModel message, UserRole senderRole);

  /// Marca una conversación como leída, reseteando el contador de mensajes no leídos del rol correspondiente.
  Future<void> markAsRead(String chatId, UserRole role);

  /// Actualiza el estado de una propuesta de pago dentro de la conversación.
  Future<void> updatePaymentProposalStatus(String chatId, String messageId, PaymentStatus status);
}

class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chatsRef => _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection('messages');

  @override
  Future<ChatModel> createOrGetChat({
    required String clientUid,
    required String workerUid,
    required String category,
  }) async {
    // Buscar si ya existe una conversación activa entre ambos para esa categoría
    final query = await _chatsRef
        .where('clientUid', isEqualTo: clientUid)
        .where('workerUid', isEqualTo: workerUid)
        .where('category', isEqualTo: category)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      data['chatId'] = doc.id;
      return ChatModel.fromJson(data);
    }

    // Si no existe, crear una nueva conversación
    final docRef = _chatsRef.doc();
    final newChat = ChatModel(
      chatId: docRef.id,
      clientUid: clientUid,
      workerUid: workerUid,
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      unreadCountClient: 0,
      unreadCountWorker: 0,
      paymentStatus: PaymentStatus.none,
      canReview: false,
    );

    await docRef.set(newChat.toJson());
    return newChat;
  }

  @override
  Stream<List<ChatModel>> watchChats(String userUid, UserRole role) {
    Query<Map<String, dynamic>> query = _chatsRef;
    if (role == UserRole.client) {
      query = query.where('clientUid', isEqualTo: userUid);
    } else {
      query = query.where('workerUid', isEqualTo: userUid);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;
        return ChatModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['messageId'] = doc.id;
        return MessageModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(
    String chatId,
    MessageModel message,
    UserRole senderRole,
  ) async {
    final batch = _firestore.batch();
    
    // Crear ID y guardar mensaje en subcolección
    final msgDocRef = _messagesRef(chatId).doc();
    final messageWithId = message.copyWith(messageId: msgDocRef.id);
    batch.set(msgDocRef, messageWithId.toJson());

    // Actualizar el documento padre de chat
    final chatDocRef = _chatsRef.doc(chatId);
    
    final updateData = <String, dynamic>{
      'lastMessageText': message.type == MessageType.text
          ? message.text
          : message.type == MessageType.image
              ? '📷 Foto'
              : message.type == MessageType.location
                  ? '📍 Ubicación compartida'
                  : '💳 Propuesta de pago',
      'lastMessageSenderUid': message.senderUid,
      'lastMessageAt': Timestamp.fromDate(message.sentAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    // Incrementar el unreadCount correspondiente
    if (senderRole == UserRole.client) {
      updateData['unreadCountWorker'] = FieldValue.increment(1);
    } else {
      updateData['unreadCountClient'] = FieldValue.increment(1);
    }

    batch.update(chatDocRef, updateData);
    await batch.commit();
  }

  @override
  Future<void> markAsRead(String chatId, UserRole role) async {
    final chatDocRef = _chatsRef.doc(chatId);
    final fieldName = role == UserRole.client ? 'unreadCountClient' : 'unreadCountWorker';
    
    await chatDocRef.update({
      fieldName: 0,
    });
  }

  @override
  Future<void> updatePaymentProposalStatus(String chatId, String messageId, PaymentStatus status) async {
    final batch = _firestore.batch();
    
    // Obtener el documento del mensaje
    final msgDocRef = _messagesRef(chatId).doc(messageId);
    final msgSnapshot = await msgDocRef.get();
    
    if (msgSnapshot.exists && msgSnapshot.data() != null) {
      final currentData = msgSnapshot.data()!;
      if (currentData['paymentData'] != null) {
        final paymentMap = Map<String, dynamic>.from(currentData['paymentData'] as Map);
        paymentMap['status'] = status.name;
        
        batch.update(msgDocRef, {
          'paymentData': paymentMap,
        });
      }
    }

    // Actualizar el estado de pago y habilitar reseña si fue pagado
    final chatDocRef = _chatsRef.doc(chatId);
    final chatUpdate = <String, dynamic>{
      'paymentStatus': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    
    if (status == PaymentStatus.paid) {
      chatUpdate['canReview'] = true;
    }
    
    batch.update(chatDocRef, chatUpdate);
    await batch.commit();
  }
}

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../app/providers/auth_provider.dart';
import '../../../../data/models/chat_model.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';

/// Proveedor para la instancia de ChatRepository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirebaseChatRepository();
});

/// StreamProvider que expone la lista de chats del usuario actual (filtrado por su rol).
final chatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final userProfileAsync = ref.watch(currentUserProfileProvider);
  return userProfileAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final chatRepo = ref.watch(chatRepositoryProvider);
      return chatRepo.watchChats(user.uid, user.role);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// StreamProvider con paso de parámetros (family) para escuchar los mensajes de un chat específico.
final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchMessages(chatId);
});

/// Estado para el envío de mensajes (por ejemplo, para spinner de carga al subir imágenes).
class ChatSendingState {
  ChatSendingState({
    this.isUploadingFile = false,
    this.error,
  });

  final bool isUploadingFile;
  final String? error;

  ChatSendingState copyWith({
    bool? isUploadingFile,
    String? error,
  }) {
    return ChatSendingState(
      isUploadingFile: isUploadingFile ?? this.isUploadingFile,
      error: error,
    );
  }
}

/// Notificador que maneja el envío de mensajes e imágenes para un chat específico.
class ChatNotifier extends StateNotifier<ChatSendingState> {
  ChatNotifier({
    required ChatRepository chatRepo,
    required String chatId,
    required Ref ref,
  })  : _chatRepo = chatRepo,
        _chatId = chatId,
        _ref = ref,
        super(ChatSendingState());

  final ChatRepository _chatRepo;
  final String _chatId;
  final Ref _ref;

  /// Envía un mensaje de texto plano.
  Future<bool> sendTextMessage(String text) async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    final message = MessageModel(
      messageId: '', // Se autogenera en el repositorio
      senderUid: user.uid,
      type: MessageType.text,
      text: text,
      sentAt: DateTime.now(),
    );

    try {
      await _chatRepo.sendMessage(_chatId, message, user.role);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Envía una imagen local (subiéndola previamente a Firebase Storage).
  Future<bool> sendImageMessage(File file) async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    state = state.copyWith(isUploadingFile: true, error: null);

    try {
      // Ruta de almacenamiento: chats/{chatId}/{timestamp}_{filename}
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chats')
          .child(_chatId)
          .child(fileName);

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final message = MessageModel(
        messageId: '',
        senderUid: user.uid,
        type: MessageType.image,
        imageUrl: downloadUrl,
        sentAt: DateTime.now(),
      );

      await _chatRepo.sendMessage(_chatId, message, user.role);
      state = state.copyWith(isUploadingFile: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUploadingFile: false, error: e.toString());
      return false;
    }
  }

  /// Comparte la ubicación geográfica actual en el chat.
  Future<bool> sendLocationMessage(double latitude, double longitude) async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    final message = MessageModel(
      messageId: '',
      senderUid: user.uid,
      type: MessageType.location,
      latitude: latitude,
      longitude: longitude,
      sentAt: DateTime.now(),
    );

    try {
      await _chatRepo.sendMessage(_chatId, message, user.role);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Crea una propuesta de cobro/pago para este chat.
  Future<bool> sendPaymentProposal({
    required String title,
    required double amount,
    required String notes,
  }) async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    final message = MessageModel(
      messageId: '',
      senderUid: user.uid,
      type: MessageType.payment,
      paymentData: {
        'title': title,
        'amount': amount,
        'notes': notes,
        'status': 'pending', // pending, paid, rejected
      },
      sentAt: DateTime.now(),
    );

    try {
      await _chatRepo.sendMessage(_chatId, message, user.role);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Marca la conversación actual como leída.
  Future<void> markAsRead() async {
    final user = _ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    try {
      await _chatRepo.markAsRead(_chatId, user.role);
    } catch (_) {}
  }

  /// Actualiza el estado de una propuesta de pago.
  Future<bool> updatePaymentProposalStatus(String messageId, PaymentStatus status) async {
    try {
      await _chatRepo.updatePaymentProposalStatus(_chatId, messageId, status);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Provider family que expone la instancia de ChatNotifier vinculada a un chatId.
final chatNotifierProvider = StateNotifierProvider.family<ChatNotifier, ChatSendingState, String>((ref, chatId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return ChatNotifier(chatRepo: chatRepo, chatId: chatId, ref: ref);
});

/// StreamProvider family que expone la información pública de un usuario por su UID.
final otherUserProfileProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUser(uid);
});


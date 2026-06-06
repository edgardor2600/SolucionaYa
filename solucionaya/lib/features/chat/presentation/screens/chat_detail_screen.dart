import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../app/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/chat_model.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/location_service.dart';
import '../providers/chat_providers.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  late InMemoryChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = InMemoryChatController();
    // Marcar como leído al entrar
    Future.microtask(() {
      ref.read(chatNotifierProvider(widget.chatId).notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Sincroniza los mensajes de Firestore en el InMemoryChatController
  void _syncMessages(
    List<MessageModel> messages,
    UserModel currentUser,
    UserModel? otherUser,
  ) {
    final mapped = _mapToChatMessages(messages, currentUser, otherUser);
    _chatController.setMessages(mapped, animated: false);
  }

  /// Abre el selector de adjuntos
  void _showAttachmentMenu(BuildContext context, UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Elegir de Galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              title: const Text('Compartir Ubicación GPS'),
              onTap: () {
                Navigator.pop(ctx);
                _sendCurrentLocation();
              },
            ),
            if (currentUser.role == UserRole.worker)
              ListTile(
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.success),
                title: const Text('Crear Propuesta de Pago'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPaymentProposalDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (image != null) {
        final file = File(image.path);
        await ref.read(chatNotifierProvider(widget.chatId).notifier).sendImageMessage(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al adjuntar imagen: $e')),
        );
      }
    }
  }

  Future<void> _sendCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocationAndCity();
      await ref
          .read(chatNotifierProvider(widget.chatId).notifier)
          .sendLocationMessage(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir ubicación: $e')),
        );
      }
    }
  }

  void _showPaymentProposalDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.credit_card_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Propuesta de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Concepto (Ej: Cambio de grifo)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto (COP)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              final notes = notesController.text.trim();
              if (title.isNotEmpty && amount > 0) {
                Navigator.pop(ctx);
                await ref
                    .read(chatNotifierProvider(widget.chatId).notifier)
                    .sendPaymentProposal(title: title, amount: amount, notes: notes);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enviar Propuesta'),
          ),
        ],
      ),
    );
  }

  /// Transforma MessageModel de Firestore al tipo Message de flutter_chat_core v2
  List<Message> _mapToChatMessages(
    List<MessageModel> messages,
    UserModel currentUser,
    UserModel? otherUser,
  ) {
    return messages.map((msg) {
      final authorId = msg.senderUid;
      final createdAt = msg.sentAt;

      if (msg.type == MessageType.image && msg.imageUrl != null) {
        return Message.image(
          id: msg.messageId.isEmpty ? UniqueKey().toString() : msg.messageId,
          authorId: authorId,
          createdAt: createdAt,
          source: msg.imageUrl!,
        );
      } else if (msg.type == MessageType.location &&
          msg.latitude != null &&
          msg.longitude != null) {
        return Message.custom(
          id: msg.messageId.isEmpty ? UniqueKey().toString() : msg.messageId,
          authorId: authorId,
          createdAt: createdAt,
          metadata: {
            'type': 'location',
            'latitude': msg.latitude,
            'longitude': msg.longitude,
          },
        );
      } else if (msg.type == MessageType.payment && msg.paymentData != null) {
        return Message.custom(
          id: msg.messageId.isEmpty ? UniqueKey().toString() : msg.messageId,
          authorId: authorId,
          createdAt: createdAt,
          metadata: {
            'type': 'payment',
            ...msg.paymentData!,
          },
        );
      } else {
        return Message.text(
          id: msg.messageId.isEmpty ? UniqueKey().toString() : msg.messageId,
          authorId: authorId,
          createdAt: createdAt,
          text: msg.text ?? '',
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProfileProvider);
    final chatsAsync = ref.watch(chatsStreamProvider);
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));

    // Marcar como leído cuando lleguen nuevos mensajes
    ref.listen(messagesStreamProvider(widget.chatId), (_, __) {
      ref.read(chatNotifierProvider(widget.chatId).notifier).markAsRead();
    });

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(body: Center(child: Text('Usuario no autenticado.')));
        }

        return chatsAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (chats) {
            final activeChat = chats.firstWhere(
              (c) => c.chatId == widget.chatId,
              orElse: () => ChatModel(
                chatId: widget.chatId,
                clientUid: currentUser.role == UserRole.client ? currentUser.uid : '',
                workerUid: currentUser.role == UserRole.worker ? currentUser.uid : '',
                category: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                unreadCountClient: 0,
                unreadCountWorker: 0,
                paymentStatus: PaymentStatus.none,
                canReview: false,
              ),
            );

            final otherUid = activeChat.clientUid == currentUser.uid
                ? activeChat.workerUid
                : activeChat.clientUid;

            final otherUserAsync = ref.watch(otherUserProfileProvider(otherUid));

            return otherUserAsync.when(
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
              data: (otherUser) {
                return Scaffold(
                  appBar: AppBar(
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: otherUser?.photoUrl != null
                              ? NetworkImage(otherUser!.photoUrl!)
                              : null,
                          child: otherUser?.photoUrl == null
                              ? Text(
                                  (otherUser?.displayName ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUser?.displayName ?? 'Cargando...',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (activeChat.category.isNotEmpty)
                                Text(
                                  activeChat.category.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    centerTitle: false,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    elevation: 0.5,
                  ),
                  body: messagesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error al cargar mensajes: $e')),
                    data: (messages) {
                      // Sincronizar mensajes de Firestore en el controller local
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _syncMessages(messages, currentUser, otherUser);
                      });

                      final isDark = theme.brightness == Brightness.dark;

                      return chat_ui.Chat(
                        currentUserId: currentUser.uid,
                        chatController: _chatController,
                        resolveUser: (userId) async {
                          if (userId == currentUser.uid) {
                            return User(
                              id: currentUser.uid,
                              name: currentUser.displayName,
                              imageSource: currentUser.photoUrl,
                            );
                          }
                          return User(
                            id: otherUser?.uid ?? userId,
                            name: otherUser?.displayName ?? 'Usuario',
                            imageSource: otherUser?.photoUrl,
                          );
                        },
                        onMessageSend: (String text) {
                          ref
                              .read(chatNotifierProvider(widget.chatId).notifier)
                              .sendTextMessage(text);
                        },
                        onAttachmentTap: () => _showAttachmentMenu(context, currentUser),
                        theme: isDark ? ChatTheme.dark() : ChatTheme.light(),
                        builders: Builders(
                          customMessageBuilder: (context, message, index, {required isSentByMe, groupStatus}) {
                            final metadata = message.metadata;
                            if (metadata == null) return const SizedBox.shrink();

                            if (metadata['type'] == 'location') {
                              final lat = metadata['latitude'] as double;
                              final lng = metadata['longitude'] as double;
                              return _buildLocationBubble(theme, lat, lng);
                            } else if (metadata['type'] == 'payment') {
                              return _buildPaymentBubble(
                                context,
                                theme,
                                message.id,
                                metadata,
                                currentUser.role,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Burbuja de Ubicación GPS ───────────────────────────────────────────────

  Widget _buildLocationBubble(ThemeData theme, double latitude, double longitude) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Ubicación GPS',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${latitude.toStringAsFixed(5)}\nLng: ${longitude.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Abrir Mapa', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ─── Burbuja de Propuesta de Pago ──────────────────────────────────────────

  Widget _buildPaymentBubble(
    BuildContext context,
    ThemeData theme,
    String messageId,
    Map<String, dynamic> data,
    UserRole role,
  ) {
    final title = data['title'] as String? ?? 'Servicio';
    final amount = (data['amount'] as num? ?? 0).toDouble();
    final notes = data['notes'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';

    final formatter = NumberFormat.simpleCurrency(locale: 'es_CO', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Propuesta de Pago',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            formatter.format(amount),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'paid'
                  ? AppColors.success.withValues(alpha: 0.15)
                  : status == 'rejected'
                      ? AppColors.error.withValues(alpha: 0.15)
                      : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status == 'paid'
                  ? '✓ PAGADO'
                  : status == 'rejected'
                      ? '✗ RECHAZADO'
                      : '⏳ PENDIENTE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: status == 'paid'
                    ? AppColors.success
                    : status == 'rejected'
                        ? AppColors.error
                        : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (status == 'pending' && role == UserRole.client) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(chatNotifierProvider(widget.chatId).notifier)
                          .updatePaymentProposalStatus(messageId, PaymentStatus.rejected);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Rechazar', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showPaymentGateway(context, messageId, amount, title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Pagar', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Pasarela de Pago Simulada ─────────────────────────────────────────────

  void _showPaymentGateway(
    BuildContext context,
    String messageId,
    double amount,
    String concept,
  ) {
    final formatter = NumberFormat.simpleCurrency(locale: 'es_CO', decimalDigits: 0);
    bool isProcessing = false;
    bool isSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> processPayment() async {
            setState(() => isProcessing = true);
            await Future.delayed(const Duration(seconds: 2));
            final success = await ref
                .read(chatNotifierProvider(widget.chatId).notifier)
                .updatePaymentProposalStatus(messageId, PaymentStatus.paid);
            if (success) {
              setState(() {
                isProcessing = false;
                isSuccess = true;
              });
            } else {
              setState(() => isProcessing = false);
            }
          }

          if (isSuccess) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Pago Exitoso!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El pago por ${formatter.format(amount)} ha sido transferido al profesional.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Pasarela de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Concepto:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(concept, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  formatter.format(amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona método de pago:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPaymentMethod(
                  icon: Icons.credit_card_rounded,
                  label: 'Tarjeta de Crédito / Débito',
                  onTap: isProcessing ? null : processPayment,
                ),
                const SizedBox(height: 8),
                _buildPaymentMethod(
                  icon: Icons.account_balance_rounded,
                  label: 'PSE - Transferencia',
                  onTap: isProcessing ? null : processPayment,
                ),
                if (isProcessing) ...[
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text('Procesando pago seguro...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              if (!isProcessing)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethod({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

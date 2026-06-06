import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/chat_model.dart';
import '../providers/chat_providers.dart';

class ChatListTile extends ConsumerWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserUid,
    required this.onTap,
  });

  final ChatModel chat;
  final String currentUserUid;
  final VoidCallback onTap;

  String _formatMessageTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'es_CO').format(date); // Día de la semana
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Determinar quién es el destinatario ("el otro")
    final otherUid = chat.clientUid == currentUserUid ? chat.workerUid : chat.clientUid;
    final otherUserAsync = ref.watch(otherUserProfileProvider(otherUid));

    // Determinar si hay mensajes no leídos para el usuario actual
    final isClient = chat.clientUid == currentUserUid;
    final unreadCount = isClient ? chat.unreadCountClient : chat.unreadCountWorker;
    final hasUnread = unreadCount > 0;

    return otherUserAsync.when(
      loading: () => _buildShimmerLoader(theme),
      error: (_, __) => const SizedBox.shrink(), // Ocultar si hay error crítico
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();

        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar del Destinatario con indicador online (opcional)
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer,
                        border: Border.all(
                          color: hasUnread ? theme.colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: otherUser.photoUrl != null
                            ? Image.network(otherUser.photoUrl!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  otherUser.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (DateTime.now().difference(otherUser.lastActiveAt).inMinutes < 5)
                      Positioned(
                        bottom: 0,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.surface, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Nombre, Categoría y Último mensaje
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherUser.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatMessageTime(chat.lastMessageAt ?? chat.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessageText ?? 'Inicia una conversación...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: hasUnread
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoader(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHigh,
      highlightColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(radius: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

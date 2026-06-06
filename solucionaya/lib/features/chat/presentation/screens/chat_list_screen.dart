import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers/auth_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_list_tile.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProfileProvider);
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mensajes',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        scrolledUnderElevation: 1,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar perfil: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Inicia sesión para ver tus mensajes.'));
          }

          return chatsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error al cargar conversaciones: $e')),
            data: (chats) {
              if (chats.isEmpty) {
                return _buildEmptyState(context, theme, user.role.name);
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: chats.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 88,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return ChatListTile(
                    chat: chat,
                    currentUserUid: user.uid,
                    onTap: () {
                      context.push(AppRoutes.chat(chat.chatId));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, String role) {
    final isClient = role == 'client';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no hay mensajes',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isClient
                  ? 'Aquí verás las conversaciones con los profesionales que contactes.'
                  : 'Aquí verás los mensajes de tus futuros clientes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isClient) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.go(AppRoutes.clientExplore);
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buscar expertos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

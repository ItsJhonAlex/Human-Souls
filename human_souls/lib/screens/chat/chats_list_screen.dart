import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../main.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    ref.watch(inboxRealtimeProvider);

    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: inbox.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (items) => items.isEmpty
                    ? _Empty()
                    : RefreshIndicator(
                        color: SoulColors.turquoise,
                        backgroundColor: SoulColors.midnight,
                        onRefresh: () async => ref.invalidate(inboxProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) =>
                              _InboxTile(item: items[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mensajes',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const Text(
                'Conversaciones 1:1',
                style: TextStyle(color: SoulColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: SoulColors.turquoise,
              ),
              const SizedBox(height: 12),
              Text(
                'Todavía no iniciaste ninguna conversación',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tocá el avatar de un Soul en el feed para empezar a hablar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SoulColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final InboxItem item;
  const _InboxTile({required this.item});

  String _timeLabel() {
    final now = DateTime.now();
    final t = item.lastMessageAt;
    if (now.difference(t).inDays == 0) {
      return DateFormat.Hm().format(t);
    }
    if (now.difference(t).inDays < 7) {
      return DateFormat.E('es').format(t);
    }
    return DateFormat('d/M').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final meId = supabase.auth.currentUser?.id;
    final lastIsMine = item.lastMessageSenderId == meId;
    final initial = (item.otherUserName ?? 'S').substring(0, 1).toUpperCase();

    return GlassCard(
      onTap: () =>
          context.push('/chat/${item.chatId}?userId=${item.otherUserId}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: item.otherIsFounder
                  ? const LinearGradient(
                      colors: [SoulColors.gold, SoulColors.pink],
                    )
                  : SoulColors.ctaGradient,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: SoulColors.deepBlue,
              backgroundImage: item.otherUserAvatar != null
                  ? NetworkImage(item.otherUserAvatar!)
                  : null,
              child: item.otherUserAvatar == null
                  ? Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.otherUserName ?? 'Soul',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      _timeLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: SoulColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastIsMine && item.lastMessageContent != null
                            ? 'Vos: ${item.lastMessageContent}'
                            : (item.lastMessageContent ?? 'Sin mensajes aún'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: item.unreadCount > 0 && !lastIsMine
                              ? SoulColors.textPrimary
                              : SoulColors.textSecondary,
                          fontWeight: item.unreadCount > 0 && !lastIsMine
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (item.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: SoulColors.ctaGradient,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

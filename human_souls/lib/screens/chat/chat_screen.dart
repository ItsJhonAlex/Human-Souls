import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../core/current_user.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/common/gradient_background.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Marcar leídos al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await markChatAsRead(widget.chatId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      markChatAsRead(widget.chatId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await sendMessage(chatId: widget.chatId, content: text);
      // Esperar al tick del stream y scrollear.
      await Future.delayed(const Duration(milliseconds: 150));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // Restaurar si falló
      _ctrl.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar. Probá de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final otherProfile = ref.watch(
      otherUserProfileProvider(widget.otherUserId),
    );
    final meId = currentUserId();

    // Marcar leídos cuando llega un mensaje nuevo ajeno.
    ref.listen(messagesProvider(widget.chatId), (_, next) {
      next.whenData((list) {
        if (list.any((m) => m.senderId != meId && !m.read)) {
          markChatAsRead(widget.chatId);
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(profileAsync: otherProfile),
              Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (msgs) {
                  if (msgs.isEmpty) return _EmptyConversation();
                  // Scroll automático al fondo al montar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtrl.hasClients &&
                        _scrollCtrl.position.pixels <
                            _scrollCtrl.position.maxScrollExtent - 100) {
                      // no auto-scroll si el usuario scrolleó hacia arriba
                      return;
                    }
                    if (_scrollCtrl.hasClients) {
                      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                    }
                  });
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final prev = i > 0 ? msgs[i - 1] : null;
                      final nextMsg = i < msgs.length - 1 ? msgs[i + 1] : null;
                      final showDateHeader =
                          prev == null ||
                          !_sameDay(prev.createdAt, m.createdAt);
                      // Ocultar timestamp si el siguiente mensaje es del mismo
                      // remitente dentro de 2 minutos.
                      final hideTs =
                          nextMsg != null &&
                          nextMsg.senderId == m.senderId &&
                          nextMsg.createdAt.difference(m.createdAt).inMinutes <
                              2;

                      return Column(
                        children: [
                          if (showDateHeader) _DateHeader(date: m.createdAt),
                          MessageBubble(
                            message: m,
                            isMine: m.senderId == meId,
                            showTimestamp: !hideTs,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
              _ComposeBar(controller: _ctrl, sending: _sending, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final AsyncValue profileAsync;
  const _Header({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SoulColors.glassBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          profileAsync.when(
            loading: () => const SizedBox(width: 36, height: 36),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (p) {
              final name = p['full_name'] as String? ?? 'Soul';
              final avatar = p['avatar_url'] as String?;
              final level = p['level_name'] as String?;
              final isFounder = (p['is_founder_buddy'] ?? false) as bool;
              final initial = name.substring(0, 1).toUpperCase();
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: isFounder
                            ? const LinearGradient(
                                colors: [SoulColors.gold, SoulColors.pink],
                              )
                            : SoulColors.ctaGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: SoulColors.deepBlue,
                        backgroundImage: avatar != null
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isFounder) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: SoulColors.gold,
                                ),
                              ],
                            ],
                          ),
                          if (level != null)
                            Text(
                              level,
                              style: const TextStyle(
                                fontSize: 11,
                                color: SoulColors.turquoise,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  String _label() {
    final now = DateTime.now();
    final d = date;
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Hoy';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Ayer';
    }
    return DateFormat("EEEE d 'de' MMMM", 'es').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            _label(),
            style: const TextStyle(
              fontSize: 11,
              color: SoulColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 44,
              color: SoulColors.pink,
            ),
            const SizedBox(height: 10),
            Text(
              'Que sea un encuentro bonito',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Decile hola para empezar la conversación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposeBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _ComposeBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: SoulColors.deepBlue.withValues(alpha: .85),
        border: const Border(top: BorderSide(color: SoulColors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SoulColors.glass,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: SoulColors.glassBorder),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14.5),
                  cursorColor: SoulColors.turquoise,
                  decoration: const InputDecoration(
                    hintText: 'Escribir mensaje…',
                    hintStyle: TextStyle(
                      color: SoulColors.textMuted,
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: SoulColors.ctaGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

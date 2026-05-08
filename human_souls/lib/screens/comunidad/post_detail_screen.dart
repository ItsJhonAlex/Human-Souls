import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/theme.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/community/comment_tile.dart';
import '../../widgets/community/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await addComment(ref: ref, postId: widget.postId, content: text);
      _commentCtrl.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      // Pequeño delay para que el comentario aparezca y haga scroll.
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final comments = ref.watch(postCommentsProvider(widget.postId));
    final likes = ref.watch(myReactionsProvider);
    // Activar realtime mientras esta pantalla esté montada
    ref.watch(postCommentsRealtimeProvider(widget.postId));
    ref.watch(feedRealtimeProvider);

    return GradientBackground(
      child: SafeArea(
        child: Column(children: [
          _Header(),
          Expanded(
            child: postAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (post) {
                final liked = likes.asData?.value.contains(post.id) ?? false;
                return ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    PostCard(
                      post: post,
                      isLiked: liked,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('${post.commentsCount} comentarios',
                          style: const TextStyle(
                            color: SoulColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                    ),
                    const SizedBox(height: 4),
                    comments.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('$e'),
                      data: (list) => Column(
                        children:
                            list.map((c) => CommentTile(comment: c)).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _ComposeBar(
            controller: _commentCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 4),
        Text('Publicación',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 20)),
      ]),
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
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: 10 + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      decoration: BoxDecoration(
        color: SoulColors.deepBlue.withValues(alpha: .85),
        border: const Border(top: BorderSide(color: SoulColors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: SoulColors.glass,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: SoulColors.glassBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14),
                cursorColor: SoulColors.turquoise,
                decoration: const InputDecoration(
                  hintText: 'Dejá tu comentario…',
                  hintStyle:
                      TextStyle(color: SoulColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
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
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: sending ? null : onSend,
            ),
          ),
        ]),
      ),
    );
  }
}

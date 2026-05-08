import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/config/theme.dart';
import '../../main.dart';
import '../../models/post.dart';
import '../../providers/chat_provider.dart';
import '../../providers/community_provider.dart';
import '../common/glass_card.dart';

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback? onTapComments;

  const PostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onTap,
    this.onTapComments,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _likeBusy = false;
  late bool _liked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _likesCount = widget.post.likesCount;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.likesCount != oldWidget.post.likesCount) {
      _likesCount = widget.post.likesCount;
    }
    if (widget.isLiked != oldWidget.isLiked) {
      _liked = widget.isLiked;
    }
  }

  Future<void> _toggle() async {
    if (_likeBusy) return;
    setState(() {
      _likeBusy = true;
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
      if (_likesCount < 0) _likesCount = 0;
    });
    try {
      await toggleLike(ref: ref, postId: widget.post.id, isLiked: !_liked);
    } catch (_) {
      // revert on error
      setState(() {
        _liked = !_liked;
        _likesCount += _liked ? 1 : -1;
      });
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return GlassCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(post: p),
          const SizedBox(height: 10),
          if (p.missionId != null) _MissionBadge(),
          if (p.missionId != null) const SizedBox(height: 8),
          Text(p.content, style: const TextStyle(fontSize: 14.5, height: 1.45)),
          if (p.mediaUrl != null && p.mediaType == 'image') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                p.mediaUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 180,
                        color: Colors.white12,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _LikeButton(liked: _liked, count: _likesCount, onTap: _toggle),
              const SizedBox(width: 10),
              _CommentButton(
                count: p.commentsCount,
                onTap: widget.onTapComments ?? widget.onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Post post;
  const _Header({required this.post});

  Future<void> _openChat(BuildContext context) async {
    final meId = supabase.auth.currentUser?.id;
    if (meId == null || meId == post.userId) return;
    try {
      final chatId = await findOrCreateChat(post.userId);
      if (context.mounted) {
        context.push('/chat/$chatId?userId=${post.userId}');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el chat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = (post.authorName ?? 'S').substring(0, 1).toUpperCase();
    final meId = supabase.auth.currentUser?.id;
    final canChat = meId != null && meId != post.userId;

    return Row(
      children: [
        GestureDetector(
          onTap: canChat ? () => _openChat(context) : null,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: post.authorIsFounder
                  ? const LinearGradient(
                      colors: [SoulColors.gold, SoulColors.pink],
                    )
                  : SoulColors.ctaGradient,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: SoulColors.deepBlue,
              backgroundImage: post.authorAvatar != null
                  ? NetworkImage(post.authorAvatar!)
                  : null,
              child: post.authorAvatar == null
                  ? Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
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
                      post.authorName ?? 'Soul',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (post.authorIsFounder) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: SoulColors.gold,
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (post.authorLevelName != null) ...[
                    Text(
                      post.authorLevelName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: SoulColors.turquoise.withValues(alpha: .9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '·',
                      style: TextStyle(
                        color: SoulColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    timeago.format(post.createdAt, locale: 'es'),
                    style: const TextStyle(
                      color: SoulColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (canChat)
          IconButton(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            color: SoulColors.turquoise,
            visualDensity: VisualDensity.compact,
            tooltip: 'Enviar mensaje',
          ),
      ],
    );
  }
}

class _MissionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SoulColors.turquoise.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: SoulColors.turquoise.withValues(alpha: .4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 11, color: SoulColors.turquoise),
          SizedBox(width: 3),
          Text(
            'Misión cumplida',
            style: TextStyle(
              fontSize: 10,
              color: SoulColors.turquoise,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback onTap;
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: liked
              ? SoulColors.pink.withValues(alpha: .18)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: liked
                ? SoulColors.pink.withValues(alpha: .5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: liked ? SoulColors.pink : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: liked ? SoulColors.pink : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CommentButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mode_comment_outlined,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

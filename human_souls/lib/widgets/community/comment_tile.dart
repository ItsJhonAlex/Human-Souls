import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/config/theme.dart';
import '../../models/post.dart';

class CommentTile extends StatelessWidget {
  final PostComment comment;
  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final initial = (comment.authorName ?? 'S').substring(0, 1).toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: SoulColors.violet,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!) : null,
            child: comment.authorAvatar == null
                ? Text(initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SoulColors.glass,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(comment.authorName ?? 'Soul',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                        )),
                    ),
                    const SizedBox(width: 6),
                    Text(timeago.format(comment.createdAt, locale: 'es'),
                      style: const TextStyle(fontSize: 11, color: SoulColors.textMuted)),
                  ]),
                  const SizedBox(height: 4),
                  Text(comment.content,
                    style: const TextStyle(fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

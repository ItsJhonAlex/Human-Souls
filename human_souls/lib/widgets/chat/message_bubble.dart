import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../models/chat.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    const radius = Radius.circular(20);
    const smallRadius = Radius.circular(6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine ? SoulColors.ctaGradient : null,
                color: isMine ? null : SoulColors.glass,
                border:
                    isMine ? null : Border.all(color: SoulColors.glassBorder),
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: isMine ? radius : smallRadius,
                  bottomRight: isMine ? smallRadius : radius,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: isMine ? Colors.white : SoulColors.textPrimary,
                ),
              ),
            ),
          ),
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat.Hm().format(message.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: SoulColors.textMuted,
                      )),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.read
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 12,
                      color: message.read
                          ? SoulColors.turquoise
                          : SoulColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

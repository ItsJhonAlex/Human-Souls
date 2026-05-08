class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final bool read;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.read,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        id: m['id'] as String,
        chatId: m['chat_id'] as String,
        senderId: m['sender_id'] as String,
        content: m['content'] as String,
        read: (m['read'] ?? false) as bool,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

/// Fila de la vista `chat_inbox` — una conversación con el último mensaje
/// y el contador de no leídos, más los datos del otro usuario.
class InboxItem {
  final String chatId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserLevel;
  final bool otherIsFounder;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final DateTime lastMessageAt;
  final int unreadCount;

  const InboxItem({
    required this.chatId,
    required this.otherUserId,
    required this.lastMessageAt,
    required this.unreadCount,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserLevel,
    this.otherIsFounder = false,
    this.lastMessageContent,
    this.lastMessageSenderId,
  });

  factory InboxItem.fromMap(Map<String, dynamic> m) => InboxItem(
        chatId: m['chat_id'] as String,
        otherUserId: m['other_user_id'] as String,
        otherUserName: m['other_user_name'] as String?,
        otherUserAvatar: m['other_user_avatar'] as String?,
        otherUserLevel: m['other_user_level'] as String?,
        otherIsFounder: (m['other_is_founder'] ?? false) as bool,
        lastMessageContent: m['last_message_content'] as String?,
        lastMessageSenderId: m['last_message_sender_id'] as String?,
        lastMessageAt: DateTime.parse(m['last_message_at'] as String),
        unreadCount: (m['unread_count'] ?? 0) as int,
      );
}

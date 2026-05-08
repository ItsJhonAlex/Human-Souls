import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/chat.dart';

/// Inbox ordenado por el último mensaje. Lee de la vista chat_inbox.
final inboxProvider = FutureProvider.autoDispose<List<InboxItem>>((ref) async {
  final rows = await supabase
      .from('chat_inbox')
      .select()
      .order('last_message_at', ascending: false);
  return (rows as List).map((r) => InboxItem.fromMap(r)).toList();
});

/// Placeholder para mantener la API de la UI sin usar realtime incompatible.
final inboxRealtimeProvider = Provider.autoDispose<Object?>((ref) {
  return null;
});

/// Stream de los mensajes de un chat (último 100), realtime vía `.stream()`.
final messagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, chatId) {
      return supabase
          .from('mensajes')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(200)
          .map((rows) => rows.map((r) => Message.fromMap(r)).toList());
    });

/// Encuentra o crea un chat con otro usuario y devuelve su id.
Future<String> findOrCreateChat(String otherUserId) async {
  final res = await supabase.rpc(
    'find_or_create_chat',
    params: {'p_other_user_id': otherUserId},
  );
  return res as String;
}

Future<void> sendMessage({
  required String chatId,
  required String content,
}) async {
  final user = supabase.auth.currentUser!;
  await supabase.from('mensajes').insert({
    'chat_id': chatId,
    'sender_id': user.id,
    'content': content,
  });
}

Future<void> markChatAsRead(String chatId) async {
  await supabase.rpc('mark_messages_read', params: {'p_chat_id': chatId});
}

/// Perfil público resumido del otro usuario (para el header del chat).
final otherUserProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
      final row = await supabase
          .from('profiles')
          .select(
            'id, full_name, avatar_url, level_name, is_founder_buddy, bio',
          )
          .eq('id', userId)
          .single();
      return row;
    });

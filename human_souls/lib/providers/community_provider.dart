import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../models/post.dart';

// Columnas seleccionadas + join con autor
const _postSelect = '''
*,
author:user_id (full_name, avatar_url, level_name, is_founder_buddy)
''';

const _commentSelect = '''
*,
author:user_id (full_name, avatar_url)
''';

/// Feed global — últimos 50 posts, ordenados por fecha desc.
final feedProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  final rows = await supabase
      .from('posts')
      .select(_postSelect)
      .order('created_at', ascending: false)
      .limit(50);
  return (rows as List).map((r) => Post.fromMap(r)).toList();
});

/// Placeholder para mantener la API de la UI sin usar realtime incompatible.
final feedRealtimeProvider = Provider.autoDispose<Object?>((ref) {
  return null;
});

/// Set de post_ids a los que el usuario actual reaccionó con like.
final myReactionsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final user = supabase.auth.currentUser;
  if (user == null) return {};
  final rows = await supabase
      .from('post_reacciones')
      .select('post_id')
      .eq('user_id', user.id);
  return {for (final r in (rows as List)) r['post_id'] as String};
});

/// Comentarios de un post específico.
final postCommentsProvider = FutureProvider.autoDispose
    .family<List<PostComment>, String>((ref, postId) async {
      final rows = await supabase
          .from('post_comentarios')
          .select(_commentSelect)
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return (rows as List).map((r) => PostComment.fromMap(r)).toList();
    });

final postCommentsRealtimeProvider = Provider.autoDispose
    .family<Object?, String>((ref, postId) {
      return null;
    });

/// Post detail por id (refrescado por realtime del feed).
final postDetailProvider = FutureProvider.autoDispose.family<Post, String>((
  ref,
  postId,
) async {
  final row = await supabase
      .from('posts')
      .select(_postSelect)
      .eq('id', postId)
      .single();
  return Post.fromMap(row);
});

// =====================================================================
// ACCIONES
// =====================================================================

Future<Post> createPost({
  required WidgetRef ref,
  required String content,
  Uint8List? imageBytes,
  String? imageExt,
}) async {
  final user = supabase.auth.currentUser!;
  String? mediaUrl;
  String? mediaType;

  if (imageBytes != null && imageExt != null) {
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$imageExt';
    await supabase.storage
        .from('posts')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(upsert: false),
        );
    mediaUrl = supabase.storage.from('posts').getPublicUrl(path);
    mediaType = 'image';
  }

  final inserted = await supabase
      .from('posts')
      .insert({
        'user_id': user.id,
        'content': content,
        'media_url': ?mediaUrl,
        'media_type': ?mediaType,
      })
      .select(_postSelect)
      .single();

  ref.invalidate(feedProvider);
  return Post.fromMap(inserted);
}

Future<void> toggleLike({
  required WidgetRef ref,
  required String postId,
  required bool isLiked,
}) async {
  final user = supabase.auth.currentUser!;
  if (isLiked) {
    await supabase
        .from('post_reacciones')
        .delete()
        .eq('user_id', user.id)
        .eq('post_id', postId);
  } else {
    await supabase.from('post_reacciones').insert({
      'user_id': user.id,
      'post_id': postId,
      'reaction_type': 'like',
    });
  }
  ref.invalidate(myReactionsProvider);
  // likes_count se actualiza por trigger; feed se invalidará por realtime.
}

Future<PostComment> addComment({
  required WidgetRef ref,
  required String postId,
  required String content,
}) async {
  final user = supabase.auth.currentUser!;
  final inserted = await supabase
      .from('post_comentarios')
      .insert({'user_id': user.id, 'post_id': postId, 'content': content})
      .select(_commentSelect)
      .single();
  ref.invalidate(postCommentsProvider(postId));
  return PostComment.fromMap(inserted);
}

Future<void> deletePost({
  required WidgetRef ref,
  required String postId,
}) async {
  await supabase.from('posts').delete().eq('id', postId);
  ref.invalidate(feedProvider);
}

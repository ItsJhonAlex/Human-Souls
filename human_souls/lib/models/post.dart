class Post {
  final String id;
  final String userId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final String? missionId;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  // Autor (join con profiles)
  final String? authorName;
  final String? authorAvatar;
  final String? authorLevelName;
  final bool authorIsFounder;

  const Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
    this.missionId,
    this.authorName,
    this.authorAvatar,
    this.authorLevelName,
    this.authorIsFounder = false,
  });

  factory Post.fromMap(Map<String, dynamic> m) {
    final author = m['author'] is Map ? m['author'] as Map : null;
    return Post(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      content: m['content'] as String,
      mediaUrl: m['media_url'] as String?,
      mediaType: m['media_type'] as String?,
      missionId: m['mission_id'] as String?,
      likesCount: (m['likes_count'] ?? 0) as int,
      commentsCount: (m['comments_count'] ?? 0) as int,
      createdAt: DateTime.parse(m['created_at'] as String),
      authorName: author?['full_name'] as String?,
      authorAvatar: author?['avatar_url'] as String?,
      authorLevelName: author?['level_name'] as String?,
      authorIsFounder: (author?['is_founder_buddy'] ?? false) as bool,
    );
  }

  Post copyWith({int? likesCount, int? commentsCount}) => Post(
        id: id,
        userId: userId,
        content: content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        missionId: missionId,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        createdAt: createdAt,
        authorName: authorName,
        authorAvatar: authorAvatar,
        authorLevelName: authorLevelName,
        authorIsFounder: authorIsFounder,
      );
}

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  factory PostComment.fromMap(Map<String, dynamic> m) {
    final a = m['author'] is Map ? m['author'] as Map : null;
    return PostComment(
      id: m['id'] as String,
      postId: m['post_id'] as String,
      userId: m['user_id'] as String,
      content: m['content'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      authorName: a?['full_name'] as String?,
      authorAvatar: a?['avatar_url'] as String?,
    );
  }
}

class SocialPost {
  final String id;
  final String username;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String? imageUrl;
  final int likesCount; 
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    required this.username,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'],
      username: json['username'],
      authorName: json['author_name'],
      authorAvatar: json['author_avatar'] ?? 'https://ui-avatars.com/api/?name=${json['author_name']}',
      content: json['content'],
      imageUrl: json['image_url'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
class Comment {
  final String id;
  final String postId;
  final String username;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.username,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      username: json['username'],
      authorName: json['author_name'],
      authorAvatar: json['author_avatar'] ?? 'https://ui-avatars.com/api/?name=${json['author_name']}',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'username': username,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
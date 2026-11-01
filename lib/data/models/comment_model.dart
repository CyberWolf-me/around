class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String body;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.body,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final authorMap = json['profiles'] is Map ? Map<String, dynamic>.from(json['profiles'] as Map) : null;
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorName: authorMap?['full_name'] as String? ?? authorMap?['username'] as String? ?? 'Friend',
      authorAvatar: authorMap?['avatar_initials'] as String?,
      body: json['body'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'body': body,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

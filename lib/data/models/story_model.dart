class StoryModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String placeId;
  final String placeName;
  final String mediaUrl;
  final String caption;
  final String audience;
  final DateTime createdAt;
  final DateTime expiresAt;

  const StoryModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.placeId,
    required this.placeName,
    required this.mediaUrl,
    this.caption = '',
    this.audience = 'friends',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final authorMap = json['profiles'] is Map ? Map<String, dynamic>.from(json['profiles'] as Map) : null;
    final placeMap = json['places'] is Map ? Map<String, dynamic>.from(json['places'] as Map) : null;

    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final expiresAt = json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'].toString()) ?? createdAt.add(const Duration(hours: 24))
        : createdAt.add(const Duration(hours: 24));

    return StoryModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: authorMap?['full_name'] as String? ?? authorMap?['username'] as String? ?? 'Friend',
      authorAvatar: authorMap?['avatar_initials'] as String?,
      placeId: placeMap?['slug'] as String? ?? json['place_id'] as String,
      placeName: placeMap?['name'] as String? ?? 'Tashkent Venue',
      mediaUrl: json['media_url'] as String,
      caption: json['caption'] as String? ?? '',
      audience: json['audience'] as String? ?? 'friends',
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'place_id': placeId,
      'media_url': mediaUrl,
      'caption': caption,
      'audience': audience,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

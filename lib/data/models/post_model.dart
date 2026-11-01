import 'package:flutter/material.dart';

enum PostAudience { friends, public }

enum PostSize { hero, half, wide, note }

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorAvatar;
  final String placeId;
  final String placeName;
  final String placeCategory;
  final String placeAddress;
  final String note;
  final int? rating;
  final PostAudience audience;
  final PostSize size;
  final List<String> tags;
  final String? mediaUrl;
  final int savesCount;
  final int reportsCount;
  final bool isQuarantined;
  final DateTime createdAt;
  final bool isSaved;
  final Color? tint;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorAvatar,
    required this.placeId,
    required this.placeName,
    required this.placeCategory,
    required this.placeAddress,
    required this.note,
    this.rating,
    required this.audience,
    this.size = PostSize.half,
    this.tags = const [],
    this.mediaUrl,
    this.savesCount = 0,
    this.reportsCount = 0,
    this.isQuarantined = false,
    required this.createdAt,
    this.isSaved = false,
    this.tint,
  });

  bool get isFriendsOnly => audience == PostAudience.friends;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    String? placeId,
    String? placeName,
    String? placeCategory,
    String? placeAddress,
    String? note,
    int? rating,
    PostAudience? audience,
    PostSize? size,
    List<String>? tags,
    String? mediaUrl,
    int? savesCount,
    int? reportsCount,
    bool? isQuarantined,
    DateTime? createdAt,
    bool? isSaved,
    Color? tint,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeCategory: placeCategory ?? this.placeCategory,
      placeAddress: placeAddress ?? this.placeAddress,
      note: note ?? this.note,
      rating: rating ?? this.rating,
      audience: audience ?? this.audience,
      size: size ?? this.size,
      tags: tags ?? this.tags,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      savesCount: savesCount ?? this.savesCount,
      reportsCount: reportsCount ?? this.reportsCount,
      isQuarantined: isQuarantined ?? this.isQuarantined,
      createdAt: createdAt ?? this.createdAt,
      isSaved: isSaved ?? this.isSaved,
      tint: tint ?? this.tint,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final audStr = json['audience'] as String? ?? 'friends';
    final aud = audStr == 'public' ? PostAudience.public : PostAudience.friends;

    final media = json['media_url'] as String?;
    final PostSize determinedSize = media == null
        ? PostSize.note
        : (json['size'] == 'hero'
            ? PostSize.hero
            : (json['size'] == 'wide' ? PostSize.wide : PostSize.half));

    return PostModel(
      id: (json['id'] ?? json['post_id']) as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String? ?? 'Friend',
      authorUsername: json['author_username'] as String? ?? 'user',
      authorAvatar: json['author_avatar'] as String?,
      placeId: (json['place_slug'] ?? json['place_id']) as String,
      placeName: json['place_name'] as String? ?? 'Venue',
      placeCategory: json['place_category'] as String? ?? 'Café',
      placeAddress: json['place_address'] as String? ?? '',
      note: json['note'] as String? ?? '',
      rating: json['rating'] as int?,
      audience: aud,
      size: determinedSize,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mediaUrl: media,
      savesCount: json['saves_count'] as int? ?? 0,
      reportsCount: json['reports_count'] as int? ?? 0,
      isQuarantined: json['is_quarantined'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_username': authorUsername,
      'author_avatar': authorAvatar,
      'place_id': placeId,
      'place_name': placeName,
      'place_category': placeCategory,
      'place_address': placeAddress,
      'note': note,
      'rating': rating,
      'audience': audience.name,
      'size': size.name,
      'tags': tags,
      'media_url': mediaUrl,
      'saves_count': savesCount,
      'reports_count': reportsCount,
      'is_quarantined': isQuarantined,
      'created_at': createdAt.toIso8601String(),
      'is_saved': isSaved,
    };
  }
}

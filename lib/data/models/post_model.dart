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
    required this.createdAt,
    this.isSaved = false,
    this.tint,
  });

  bool get isFriendsOnly => audience == PostAudience.friends;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
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
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String? ?? 'Friend',
      authorUsername: json['author_username'] as String? ?? 'user',
      authorAvatar: json['author_avatar'] as String?,
      placeId: json['place_id'] as String,
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
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }
}

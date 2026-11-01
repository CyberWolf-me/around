class NotificationModel {
  final String id;
  final String recipientId;
  final String actorId;
  final String actorName;
  final String actorUsername;
  final String actorInitials;
  final String kind;
  final String? placeId;
  final String? placeName;
  final String message;
  final bool unread;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    required this.actorUsername,
    required this.actorInitials,
    required this.kind,
    this.placeId,
    this.placeName,
    required this.message,
    this.unread = true,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? actorId,
    String? actorName,
    String? actorUsername,
    String? actorInitials,
    String? kind,
    String? placeId,
    String? placeName,
    String? message,
    bool? unread,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorUsername: actorUsername ?? this.actorUsername,
      actorInitials: actorInitials ?? this.actorInitials,
      kind: kind ?? this.kind,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      message: message ?? this.message,
      unread: unread ?? this.unread,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] is Map ? Map<String, dynamic>.from(json['profiles'] as Map) : null;
    final place = json['places'] is Map ? Map<String, dynamic>.from(json['places'] as Map) : null;

    final rawName = (profile?['full_name'] ?? json['actor_name'])?.toString() ?? 'Friend';
    final rawUsername = (profile?['username'] ?? json['actor_username'])?.toString() ?? 'friend';
    final initials = rawName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      actorId: json['actor_id']?.toString() ?? '',
      actorName: rawName,
      actorUsername: rawUsername,
      actorInitials: initials.isEmpty ? 'FR' : initials,
      kind: json['kind']?.toString() ?? 'drop',
      placeId: (place?['slug'] ?? json['place_id'])?.toString(),
      placeName: (place?['name'] ?? json['place_name'])?.toString(),
      message: json['message']?.toString() ?? '',
      unread: json['unread'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_username': actorUsername,
      'kind': kind,
      'place_id': placeId,
      'place_name': placeName,
      'message': message,
      'unread': unread,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

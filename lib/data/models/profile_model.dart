class ProfileModel {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String bio;
  final String neighborhood;
  final bool hideVisitsHistory;
  final String defaultAudience;
  final bool quietHours;
  final bool allowFriendRequests;
  final int dropsCount;
  final int friendsCount;
  final int savedCount;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.bio = '',
    this.neighborhood = 'Barlow Hill',
    this.hideVisitsHistory = true,
    this.defaultAudience = 'friends',
    this.quietHours = false,
    this.allowFriendRequests = true,
    this.dropsCount = 0,
    this.friendsCount = 0,
    this.savedCount = 0,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'YO';
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'user',
      fullName: json['full_name'] as String? ?? 'Anonymous',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? 'Barlow Hill',
      hideVisitsHistory: json['hide_visits_history'] as bool? ?? true,
      defaultAudience: json['default_audience'] as String? ?? 'friends',
      quietHours: json['quiet_hours'] as bool? ?? false,
      allowFriendRequests: json['allow_friend_requests'] as bool? ?? true,
      dropsCount: json['drops_count'] as int? ?? 0,
      friendsCount: json['friends_count'] as int? ?? 0,
      savedCount: json['saved_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'neighborhood': neighborhood,
      'hide_visits_history': hideVisitsHistory,
      'default_audience': defaultAudience,
      'quiet_hours': quietHours,
      'allow_friend_requests': allowFriendRequests,
    };
  }
}

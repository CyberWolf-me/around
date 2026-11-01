class ProfileModel {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String bio;
  final String neighborhood;
  final bool hideVisitsHistory;
  final String defaultAudience;
  final bool discoverableByFriends;
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
    this.neighborhood = 'Mirabad',
    this.hideVisitsHistory = true,
    this.defaultAudience = 'friends',
    this.discoverableByFriends = true,
    this.quietHours = false,
    this.allowFriendRequests = true,
    this.dropsCount = 0,
    this.friendsCount = 0,
    this.savedCount = 0,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'YO';
  }

  ProfileModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? neighborhood,
    bool? hideVisitsHistory,
    String? defaultAudience,
    bool? discoverableByFriends,
    bool? quietHours,
    bool? allowFriendRequests,
    int? dropsCount,
    int? friendsCount,
    int? savedCount,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      neighborhood: neighborhood ?? this.neighborhood,
      hideVisitsHistory: hideVisitsHistory ?? this.hideVisitsHistory,
      defaultAudience: defaultAudience ?? this.defaultAudience,
      discoverableByFriends: discoverableByFriends ?? this.discoverableByFriends,
      quietHours: quietHours ?? this.quietHours,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      dropsCount: dropsCount ?? this.dropsCount,
      friendsCount: friendsCount ?? this.friendsCount,
      savedCount: savedCount ?? this.savedCount,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'user',
      fullName: json['full_name'] as String? ?? 'Anonymous',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? 'Mirabad',
      hideVisitsHistory: json['hide_visits_history'] as bool? ?? true,
      defaultAudience: json['default_audience'] as String? ?? 'friends',
      discoverableByFriends: json['discoverable_by_friends'] as bool? ?? true,
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
      'discoverable_by_friends': discoverableByFriends,
      'quiet_hours': quietHours,
      'allow_friend_requests': allowFriendRequests,
      'drops_count': dropsCount,
      'friends_count': friendsCount,
      'saved_count': savedCount,
    };
  }
}

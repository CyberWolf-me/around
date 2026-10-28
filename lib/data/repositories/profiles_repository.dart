import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';

final currentProfileProvider = NotifierProvider<ProfileNotifier, ProfileModel>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileModel> {
  @override
  ProfileModel build() => const ProfileModel(
        id: 'you',
        username: 'yusuf',
        fullName: 'Yusuf Okonjo',
        bio: 'Looking for sourdough and quiet corners to read in Tashkent.',
        neighborhood: 'Barlow Hill',
        dropsCount: 24,
        friendsCount: 5,
        savedCount: 18,
        hideVisitsHistory: true,
        defaultAudience: 'friends',
        quietHours: false,
      );

  void updatePrivacySettings({
    bool? hideVisits,
    String? defaultAud,
    bool? quietHours,
  }) {
    state = ProfileModel(
      id: state.id,
      username: state.username,
      fullName: state.fullName,
      avatarUrl: state.avatarUrl,
      bio: state.bio,
      neighborhood: state.neighborhood,
      hideVisitsHistory: hideVisits ?? state.hideVisitsHistory,
      defaultAudience: defaultAud ?? state.defaultAudience,
      quietHours: quietHours ?? state.quietHours,
      allowFriendRequests: state.allowFriendRequests,
      dropsCount: state.dropsCount,
      friendsCount: state.friendsCount,
      savedCount: state.savedCount,
    );
  }
}

final followedFriendsProvider = NotifierProvider<FollowedFriendsNotifier, Set<String>>(FollowedFriendsNotifier.new);

class FollowedFriendsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'noor', 'teo', 'mina', 'ari', 'priya'};

  bool isFollowing(String userId) => state.contains(userId);

  void toggleFollow(String userId) {
    if (state.contains(userId)) {
      state = state.where((id) => id != userId).toSet();
    } else {
      state = {...state, userId};
    }
  }
}

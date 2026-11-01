import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/profile_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

enum FriendshipRelation {
  accepted,
  pendingOutgoing,
  pendingIncoming,
  none,
}

class CommunityMember {
  final String id;
  final String name;
  final String handle;
  final String initials;
  final String neighborhood;
  final String bio;
  final int dropsCount;
  final bool hideVisitsHistory;
  final bool allowFriendRequests;

  const CommunityMember({
    required this.id,
    required this.name,
    required this.handle,
    required this.initials,
    required this.neighborhood,
    required this.bio,
    required this.dropsCount,
    this.hideVisitsHistory = false,
    this.allowFriendRequests = true,
  });
}

const List<CommunityMember> kTashkentCommunityMembers = [
  CommunityMember(
    id: 'kamila',
    name: 'Kamila Rahimova',
    handle: 'kamilar',
    initials: 'KR',
    neighborhood: 'Mirabad',
    bio: 'Espresso & lavender matcha enthusiast. Always knows where the morning sun hits.',
    dropsCount: 18,
    hideVisitsHistory: false,
  ),
  CommunityMember(
    id: 'bekzod',
    name: 'Bekzod Alimov',
    handle: 'bekalimov',
    initials: 'BA',
    neighborhood: 'Yakkasaray',
    bio: 'Architect & remote worker. Fast Wi-Fi and power sockets required.',
    dropsCount: 14,
    hideVisitsHistory: false,
  ),
  CommunityMember(
    id: 'aziza',
    name: 'Aziza Tursunova',
    handle: 'azizatur',
    initials: 'AT',
    neighborhood: 'Yunusabad',
    bio: 'Pastry tracker & French viennoiserie devotee along Amir Timur Ave.',
    dropsCount: 29,
    hideVisitsHistory: false,
  ),
  CommunityMember(
    id: 'diyor',
    name: 'Diyor Usmanov',
    handle: 'diyor_u',
    initials: 'DU',
    neighborhood: 'Mirabad',
    bio: 'Third-wave V60 pour-over & Ethiopian single-origin collector.',
    dropsCount: 16,
    hideVisitsHistory: true,
  ),
  CommunityMember(
    id: 'madina',
    name: 'Madina Karimova',
    handle: 'madinakar',
    initials: 'MK',
    neighborhood: 'Mirzo Ulugbek',
    bio: 'Evening park walks, iced matcha kiosks, and golden hour photography.',
    dropsCount: 21,
    hideVisitsHistory: false,
  ),
  CommunityMember(
    id: 'jasur',
    name: 'Jasur Kadirov',
    handle: 'jasur_k',
    initials: 'JK',
    neighborhood: 'Shaykhontohur',
    bio: 'Chorsu plov connoisseur and traditional Uzbek culinary guide.',
    dropsCount: 33,
    hideVisitsHistory: false,
  ),
  CommunityMember(
    id: 'rustam',
    name: 'Rustam Mirzaev',
    handle: 'rustamm',
    initials: 'RM',
    neighborhood: 'Mirabad',
    bio: 'Analog vinyl digger and late-night craft cocktail explorer.',
    dropsCount: 11,
    hideVisitsHistory: false,
  ),
  CommunityMember(
    id: 'shakhlo',
    name: 'Shakhlo Nazarova',
    handle: 'shakhlo_n',
    initials: 'SN',
    neighborhood: 'Yunusabad',
    bio: 'Independent bookshops, world classics, and quiet reading nooks.',
    dropsCount: 19,
    hideVisitsHistory: true,
    allowFriendRequests: false,
  ),
];

CommunityMember? getCommunityMemberById(String id) {
  for (final m in kTashkentCommunityMembers) {
    if (m.id == id) return m;
  }
  return null;
}

/// Enforces the 'Keep my visits private' (hideVisitsHistory) invariant when viewing a profile.
bool canViewMemberVisitHistory({
  required String viewerId,
  required String targetUserId,
  required bool targetHideVisitsHistory,
  required bool areMutualFriends,
}) {
  if (viewerId == targetUserId) return true;
  if (targetHideVisitsHistory) return false;
  return areMutualFriends;
}

final currentProfileProvider = NotifierProvider<ProfileNotifier, ProfileModel>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileModel> {
  static const ProfileModel _defaultProfile = ProfileModel(
    id: 'you',
    username: 'yusuf',
    fullName: 'Yusuf Okonjo',
    bio: 'Looking for sourdough and quiet corners to read in Tashkent.',
    neighborhood: 'Mirabad',
    dropsCount: 24,
    friendsCount: 5,
    savedCount: 18,
    hideVisitsHistory: true,
    defaultAudience: 'friends',
    discoverableByFriends: true,
    quietHours: false,
    allowFriendRequests: true,
  );

  @override
  ProfileModel build() {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteProfile);
    }
    return StorageService.getStoredProfile() ?? _defaultProfile;
  }

  /// Hydrates the authenticated user's `public.profiles` row from Supabase (INT-01 fix).
  Future<void> syncRemoteProfile() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final uid = SupabaseService.currentUser!.id;
      final row = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row != null) {
        final remoteProfile = ProfileModel.fromJson(Map<String, dynamic>.from(row));
        state = remoteProfile;
        await StorageService.persistProfile(remoteProfile);
      }
    } catch (e) {
      AppLogger.warn('ProfileNotifier', 'Remote profile hydration skipped', e);
    }
  }

  Future<void> updateProfileDetails({
    required String fullName,
    required String username,
    required String bio,
    required String neighborhood,
  }) async {
    final sanitizedName = fullName.trim();
    final sanitizedHandle = username.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    final sanitizedBio = bio.trim();
    final sanitizedHood = neighborhood.trim();

    final effectiveId = (SupabaseService.isInitialized && SupabaseService.isAuthenticated)
        ? SupabaseService.currentUser!.id
        : state.id;

    final updated = state.copyWith(
      id: effectiveId,
      fullName: sanitizedName.isEmpty ? state.fullName : sanitizedName,
      username: sanitizedHandle.length >= 2 ? sanitizedHandle : state.username,
      bio: sanitizedBio.length <= 300 ? sanitizedBio : sanitizedBio.substring(0, 300),
      neighborhood: sanitizedHood.isEmpty ? state.neighborhood : sanitizedHood,
    );
    state = updated;
    await StorageService.persistProfile(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('profiles')
            .update({
              'full_name': updated.fullName,
              'username': updated.username,
              'bio': updated.bio,
              'neighborhood': updated.neighborhood,
            })
            .eq('id', SupabaseService.currentUser!.id);
      } catch (e) {
        AppLogger.warn('ProfileNotifier', 'Failed syncing profile update to Supabase', e);
      }
    }
  }

  Future<void> updatePrivacySettings({
    bool? hideVisits,
    String? defaultAud,
    bool? discoverableByFriends,
    bool? quietHours,
    bool? allowFriendRequests,
  }) async {
    final updated = state.copyWith(
      hideVisitsHistory: hideVisits ?? state.hideVisitsHistory,
      defaultAudience: defaultAud ?? state.defaultAudience,
      discoverableByFriends: discoverableByFriends ?? state.discoverableByFriends,
      quietHours: quietHours ?? state.quietHours,
      allowFriendRequests: allowFriendRequests ?? state.allowFriendRequests,
    );
    state = updated;
    await StorageService.persistProfile(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('profiles')
            .update({
              'hide_visits_history': updated.hideVisitsHistory,
              'default_audience': updated.defaultAudience,
              'discoverable_by_friends': updated.discoverableByFriends,
              'quiet_hours': updated.quietHours,
              'allow_friend_requests': updated.allowFriendRequests,
            })
            .eq('id', SupabaseService.currentUser!.id);
      } catch (e) {
        AppLogger.warn('ProfileNotifier', 'Failed syncing privacy settings to Supabase', e);
      }
    }
  }
}

/// Tracks full friendship state machine ('accepted', 'pending_outgoing', 'pending_incoming')
/// aligned with 00001_initial_schema.sql columns (user_id, friend_id) (STG-01 / MIG-01 fixed).
final friendshipStatusesProvider =
    NotifierProvider<FriendshipStatusesNotifier, Map<String, FriendshipRelation>>(FriendshipStatusesNotifier.new);

class FriendshipStatusesNotifier extends Notifier<Map<String, FriendshipRelation>> {
  static const Map<String, FriendshipRelation> _defaultRelations = {
    'kamila': FriendshipRelation.accepted,
    'bekzod': FriendshipRelation.accepted,
    'aziza': FriendshipRelation.accepted,
    'diyor': FriendshipRelation.accepted,
    'madina': FriendshipRelation.accepted,
    'jasur': FriendshipRelation.pendingIncoming,
  };

  @override
  Map<String, FriendshipRelation> build() {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteFriendships);
    }
    final stored = StorageService.getFriendshipStatuses();
    if (stored != null && stored.isNotEmpty) {
      return stored.map((k, v) {
        final rel = FriendshipRelation.values.where((e) => e.name == v).firstOrNull ?? FriendshipRelation.none;
        return MapEntry(k, rel);
      });
    }
    return Map<String, FriendshipRelation>.from(_defaultRelations);
  }

  /// Loads `public.friendships` rows (`user_id`, `friend_id`, `status`) from Supabase on startup (INT-01 / MIG-01).
  Future<void> syncRemoteFriendships() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final myUid = SupabaseService.currentUser!.id;
      final rows = await SupabaseService.client
          .from('friendships')
          .select('user_id, friend_id, status')
          .or('user_id.eq.$myUid,friend_id.eq.$myUid');
      if (rows.isNotEmpty) {
        final merged = Map<String, FriendshipRelation>.from(state);
        for (final raw in rows.whereType<Map<String, dynamic>>()) {
          final uid = raw['user_id']?.toString() ?? '';
          final fid = raw['friend_id']?.toString() ?? '';
          final st = raw['status']?.toString() ?? '';
          final otherId = uid == myUid ? fid : uid;
          if (otherId.isEmpty) continue;
          if (st == 'accepted') {
            merged[otherId] = FriendshipRelation.accepted;
          } else if (st == 'pending') {
            merged[otherId] = uid == myUid
                ? FriendshipRelation.pendingOutgoing
                : FriendshipRelation.pendingIncoming;
          }
        }
        state = merged;
        await _persist(merged);
        ref.read(followedFriendsProvider.notifier).syncFromRelations(merged);
      }
    } catch (e) {
      AppLogger.warn('FriendshipStatusesNotifier', 'Remote friendships hydration skipped', e);
    }
  }

  FriendshipRelation getRelation(String userId) => state[userId] ?? FriendshipRelation.none;

  Future<String?> requestOrToggleFriendship(String userId) async {
    final member = getCommunityMemberById(userId);
    final current = getRelation(userId);

    if (current == FriendshipRelation.accepted || current == FriendshipRelation.pendingOutgoing) {
      final updated = Map<String, FriendshipRelation>.from(state)..remove(userId);
      state = updated;
      await _persist(updated);
      ref.read(followedFriendsProvider.notifier).syncFromRelations(updated);
      await _syncFriendshipToSupabase(userId, 'removed');
      return 'Removed @$userId';
    }

    if (current == FriendshipRelation.pendingIncoming) {
      return acceptIncomingRequest(userId);
    }

    if (member != null && !member.allowFriendRequests) {
      return '@${member.handle} has disabled incoming friend requests.';
    }

    final updated = {...state, userId: FriendshipRelation.pendingOutgoing};
    state = updated;
    await _persist(updated);
    await _syncFriendshipToSupabase(userId, 'pending');
    return 'Friend request sent to @${member?.handle ?? userId} (pending acceptance)';
  }

  Future<String> acceptIncomingRequest(String userId) async {
    final updated = {...state, userId: FriendshipRelation.accepted};
    state = updated;
    await _persist(updated);
    ref.read(followedFriendsProvider.notifier).syncFromRelations(updated);
    await _syncFriendshipToSupabase(userId, 'accepted');
    return 'Accepted friend request from @$userId';
  }

  Future<String> declineIncomingRequest(String userId) async {
    final updated = Map<String, FriendshipRelation>.from(state)..remove(userId);
    state = updated;
    await _persist(updated);
    await _syncFriendshipToSupabase(userId, 'declined');
    return 'Declined request from @$userId';
  }

  /// Uses `user_id` (initiator) and `friend_id` (recipient) matching `00001_initial_schema.sql` (MIG-01 fixed).
  Future<void> _syncFriendshipToSupabase(String targetUserId, String status) async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final myUid = SupabaseService.currentUser!.id;
      if (status == 'removed' || status == 'declined') {
        await SupabaseService.client
            .from('friendships')
            .delete()
            .or('and(user_id.eq.$myUid,friend_id.eq.$targetUserId),and(user_id.eq.$targetUserId,friend_id.eq.$myUid)');
      } else if (status == 'pending') {
        await SupabaseService.client.from('friendships').insert({
          'user_id': myUid,
          'friend_id': targetUserId,
          'status': 'pending',
        });
      } else if (status == 'accepted') {
        await SupabaseService.client
            .from('friendships')
            .update({'status': 'accepted'})
            .eq('user_id', targetUserId)
            .eq('friend_id', myUid);
      }
    } catch (e) {
      AppLogger.warn('FriendshipStatusesNotifier', 'Supabase friendships sync skipped', e);
    }
  }

  Future<void> _persist(Map<String, FriendshipRelation> map) async {
    await StorageService.persistFriendshipStatuses(map.map((k, v) => MapEntry(k, v.name)));
  }
}

/// Exposes the set of mutually ACCEPTED friend IDs for feed and place drop queries.
final followedFriendsProvider = NotifierProvider<FollowedFriendsNotifier, Set<String>>(FollowedFriendsNotifier.new);

class FollowedFriendsNotifier extends Notifier<Set<String>> {
  static const Set<String> defaultTashkentFriends = {
    'kamila',
    'bekzod',
    'aziza',
    'diyor',
    'madina',
  };

  @override
  Set<String> build() {
    return StorageService.getFollowedFriends() ?? Set<String>.from(defaultTashkentFriends);
  }

  bool isFollowing(String userId) => state.contains(userId);

  void syncFromRelations(Map<String, FriendshipRelation> relations) {
    final acceptedIds = relations.entries
        .where((e) => e.value == FriendshipRelation.accepted)
        .map((e) => e.key)
        .toSet();
    state = acceptedIds;
    StorageService.persistFollowedFriends(acceptedIds);
  }

  void toggleFollow(String userId) {
    Set<String> updated;
    if (state.contains(userId)) {
      updated = state.where((id) => id != userId).toSet();
    } else {
      updated = {...state, userId};
    }
    state = updated;
    StorageService.persistFollowedFriends(updated);
  }
}

final blockedUsersProvider = NotifierProvider<BlockedUsersNotifier, Set<String>>(BlockedUsersNotifier.new);

class BlockedUsersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteBlocks);
    }
    return StorageService.getBlockedUsers();
  }

  Future<void> syncRemoteBlocks() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final myUid = SupabaseService.currentUser!.id;
      final rows = await SupabaseService.client
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', myUid);
      if (rows.isNotEmpty) {
        final remoteBlocked = rows
            .whereType<Map<String, dynamic>>()
            .map((r) => r['blocked_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        if (remoteBlocked.isNotEmpty) {
          final merged = {...state, ...remoteBlocked};
          state = merged;
          await StorageService.persistBlockedUsers(merged);
        }
      }
    } catch (e) {
      AppLogger.warn('BlockedUsersNotifier', 'Remote blocks hydration skipped', e);
    }
  }

  bool isBlocked(String userId) => state.contains(userId);

  Future<void> blockUser(String userId) async {
    if (userId == 'you' || userId == ref.read(currentProfileProvider).id) return;
    final updated = {...state, userId};
    state = updated;
    await StorageService.persistBlockedUsers(updated);
    if (ref.read(followedFriendsProvider).contains(userId)) {
      ref.read(followedFriendsProvider.notifier).toggleFollow(userId);
    }
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('blocks').insert({
          'blocker_id': SupabaseService.currentUser!.id,
          'blocked_id': userId,
        });
      } catch (e) {
        AppLogger.warn('BlockedUsersNotifier', 'Supabase block sync skipped', e);
      }
    }
  }

  Future<void> unblockUser(String userId) async {
    final updated = state.where((id) => id != userId).toSet();
    state = updated;
    await StorageService.persistBlockedUsers(updated);
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('blocks')
            .delete()
            .eq('blocker_id', SupabaseService.currentUser!.id)
            .eq('blocked_id', userId);
      } catch (e) {
        AppLogger.warn('BlockedUsersNotifier', 'Supabase unblock sync skipped', e);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = getCommunityMemberById(userId);
    final relations = ref.watch(friendshipStatusesProvider);
    final relationNotifier = ref.read(friendshipStatusesProvider.notifier);
    final blockedUsers = ref.watch(blockedUsersProvider);
    final allPosts = ref.watch(postsRepositoryProvider);

    if (member == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(),
        body: const Center(child: Text('User not found')),
      );
    }

    final relation = relations[userId] ?? FriendshipRelation.none;
    final isAcceptedFriend = relation == FriendshipRelation.accepted;
    final isBlocked = blockedUsers.contains(userId);

    final canSeeHistory = canViewMemberVisitHistory(
      viewerId: 'you',
      targetUserId: userId,
      targetHideVisitsHistory: member.hideVisitsHistory,
      areMutualFriends: isAcceptedFriend,
    );

    final visibleUserDrops = allPosts.where((p) {
      if (p.authorId != userId || p.isQuarantined) return false;
      if (p.isFriendsOnly && !isAcceptedFriend) return false;
      return true;
    }).toList();

    String buttonLabel;
    switch (relation) {
      case FriendshipRelation.accepted:
        buttonLabel = '✓ Mutual Friends';
        break;
      case FriendshipRelation.pendingOutgoing:
        buttonLabel = '⏳ Request Sent';
        break;
      case FriendshipRelation.pendingIncoming:
        buttonLabel = 'Accept Friend Request';
        break;
      case FriendshipRelation.none:
        buttonLabel = member.allowFriendRequests ? '+ Send Friend Request' : 'Requests Disabled';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('@${member.handle}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (action) async {
              if (action == 'block') {
                await ref.read(blockedUsersProvider.notifier).blockUser(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked @${member.handle}')),
                  );
                  context.pop();
                }
              } else if (action == 'report') {
                await StorageService.addReport({
                  'target_type': 'profile',
                  'target_id': userId,
                  'reason': 'Profile moderation report',
                  'created_at': DateTime.now().toIso8601String(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reported @${member.handle} to Trust & Safety')),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report Profile')),
              PopupMenuItem(
                value: 'block',
                child: Text('Block User', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
      body: isBlocked
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You have blocked this account.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(blockedUsersProvider.notifier).unblockUser(userId),
                    child: const Text('Unblock'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.butter,
                        border: Border.all(color: AppColors.ink, width: 2.5),
                        boxShadow: const [AppColors.shadowSm],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member.initials,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                          Text('@${member.handle} · ${member.neighborhood}', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(member.bio, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    HapticService.selection();
                    final msg = await relationNotifier.requestOrToggleFriendship(userId);
                    if (msg != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAcceptedFriend ? AppColors.paper2 : AppColors.orange,
                    foregroundColor: isAcceptedFriend ? AppColors.ink : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.ink, width: 1.8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Recent Drops',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (!canSeeHistory)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline, size: 28, color: AppColors.ink),
                        const SizedBox(height: 8),
                        Text(
                          member.hideVisitsHistory
                              ? '${member.name.split(' ').first} keeps their visit timeline private.'
                              : 'Connect as mutual friends to view ${member.name.split(' ').first}’s friends-only drops.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (visibleUserDrops.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No visible drops yet.')),
                  )
                else
                  ...visibleUserDrops.map((drop) => GestureDetector(
                        onTap: () => context.push('/places/${drop.placeId}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.ink, width: 1.8),
                            boxShadow: const [AppColors.shadowSm],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      drop.placeName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Text(drop.timeAgo, style: Theme.of(context).textTheme.labelSmall),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('“${drop.note}”', style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}

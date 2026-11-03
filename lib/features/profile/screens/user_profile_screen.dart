import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/services/curator_recommendation_engine.dart';
import '../../../core/services/locale_service.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../widgets/curator_taste_overlap_card.dart';
import '../widgets/curator_coffee_ping_sheet.dart';
import '../widgets/curator_trophy_cabinet.dart';
import '../../../core/services/curator_accolades_engine.dart';
import '../../../data/repositories/curator_accolades_repository.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late Future<CommunityMember?> _memberFuture;

  @override
  void initState() {
    super.initState();
    _memberFuture = fetchCommunityMember(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final relations = ref.watch(friendshipStatusesProvider);
    final relationNotifier = ref.read(friendshipStatusesProvider.notifier);
    final blockedUsers = ref.watch(blockedUsersProvider);
    final allPosts = ref.watch(postsRepositoryProvider);
    final currentUserId = SupabaseService.currentUser?.id ?? ref.watch(currentProfileProvider).id;

    return FutureBuilder<CommunityMember?>(
      future: _memberFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.paper,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: SizedBox(),
            ),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2.5),
            ),
          );
        }

        final member = snapshot.data;
        if (member == null) {
          return Scaffold(
            backgroundColor: AppColors.paper,
            appBar: AppBar(leading: const BackButton()),
            body: const Center(
              child: Text('User not found', style: TextStyle(color: AppColors.ink2)),
            ),
          );
        }

        final relation = relations[widget.userId] ?? FriendshipRelation.none;
        final isAcceptedFriend = relation == FriendshipRelation.accepted;
        final isBlocked = blockedUsers.contains(widget.userId);

        final canSeeHistory = canViewMemberVisitHistory(
          viewerId: currentUserId,
          targetUserId: member.id,
          targetHideVisitsHistory: member.hideVisitsHistory,
          areMutualFriends: isAcceptedFriend,
        );

        final visibleUserDrops = allPosts.where((p) {
          if (p.authorId != member.id || p.isQuarantined) return false;
          if (p.isFriendsOnly && !isAcceptedFriend) return false;
          return true;
        }).toList();

        final currentProfile = ref.watch(currentProfileProvider);
        final mySavedPlaces = ref.watch(savedPlacesProvider);
        final myDrops = allPosts.where((p) => p.authorId == currentUserId && !p.isQuarantined).toList();
        final currentLang = ref.watch(appLocaleProvider);

        final myTasteProfile = CuratorTasteProfile(
          userId: currentUserId,
          username: currentProfile.username,
          fullName: currentProfile.fullName,
          neighborhood: currentProfile.neighborhood,
          droppedPlaceIds: myDrops.map((d) => d.placeId).toSet(),
          savedPlaceIds: mySavedPlaces.toSet(),
          preferredTags: myDrops.expand((d) => d.tags).toSet(),
          activeDistricts: {currentProfile.neighborhood},
        );

        final candidateTasteProfile = CuratorTasteProfile(
          userId: member.id,
          username: member.handle,
          fullName: member.name,
          neighborhood: member.neighborhood,
          droppedPlaceIds: visibleUserDrops.map((d) => d.placeId).toSet(),
          savedPlaceIds: const {},
          preferredTags: visibleUserDrops.expand((d) => d.tags).toSet(),
          activeDistricts: {member.neighborhood},
        );

        final recEngine = ref.watch(curatorRecommendationEngineProvider);
        final tasteMatch = recEngine.evaluateOverlap(myTasteProfile, candidateTasteProfile);

        String buttonLabel;
        Color buttonBg;
        Color buttonFg;
        IconData buttonIcon;
        switch (relation) {
          case FriendshipRelation.accepted:
            buttonLabel = 'Mutual Friends';
            buttonBg = AppColors.butter;
            buttonFg = AppColors.ink;
            buttonIcon = Icons.check_circle_outline;
            break;
          case FriendshipRelation.pendingOutgoing:
            buttonLabel = 'Request Sent';
            buttonBg = AppColors.paper2;
            buttonFg = AppColors.ink2;
            buttonIcon = Icons.hourglass_empty;
            break;
          case FriendshipRelation.pendingIncoming:
            buttonLabel = 'Accept Friend Request';
            buttonBg = AppColors.cobalt;
            buttonFg = Colors.white;
            buttonIcon = Icons.person_add;
            break;
          case FriendshipRelation.none:
            buttonLabel = member.allowFriendRequests ? 'Add Friend' : 'Requests Disabled';
            buttonBg = member.allowFriendRequests ? AppColors.orange : AppColors.paper2;
            buttonFg = member.allowFriendRequests ? Colors.white : AppColors.ink3;
            buttonIcon = member.allowFriendRequests ? Icons.person_add_alt_1 : Icons.lock_outline;
            break;
        }

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              '@${member.handle}',
              style: GoogleFonts.bricolageGrotesque(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.ink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                color: AppColors.paper,
                onSelected: (action) async {
                  if (action == 'block') {
                    await ref.read(blockedUsersProvider.notifier).blockUser(widget.userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Blocked @${member.handle}')),
                      );
                      context.pop();
                    }
                  } else if (action == 'report') {
                    await StorageService.addReport({
                      'target_type': 'profile',
                      'target_id': widget.userId,
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
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 16, color: AppColors.ink2),
                        SizedBox(width: 8),
                        Text('Report Profile', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 16, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Block User', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: isBlocked
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.paper2,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.block, color: AppColors.ink3, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Account Blocked',
                          style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You have blocked this account. You won’t see their drops or activity.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.ink2),
                        ),
                        const SizedBox(height: 18),
                        BouncingWidget(
                          onTap: () => ref.read(blockedUsersProvider.notifier).unblockUser(widget.userId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                              boxShadow: const [AppColors.shadowTactile],
                            ),
                            child: const Text('Unblock Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                        boxShadow: const [AppColors.shadowCard],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.butter,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [AppColors.shadowSubtle],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  member.initials,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 24,
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
                                    Text(
                                      member.name,
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '@${member.handle}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink3),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.location_on, size: 12, color: AppColors.orange),
                                        const SizedBox(width: 2),
                                        Text(
                                          member.neighborhood,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                        ),
                                      ],
                                    ),
                                    if (member.bio.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        member.bio,
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.35),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          BouncingWidget(
                            onTap: () async {
                              HapticService.selection();
                              if (!SupabaseService.isAuthenticated) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.paper,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: const BorderSide(color: AppColors.borderSubtle),
                                    ),
                                    title: Text(
                                      'Account Required',
                                      style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800),
                                    ),
                                    content: const Text(
                                      'Sign in or create an account to connect with members of the Tashkent community.',
                                      style: TextStyle(fontSize: 13, color: AppColors.ink2),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
                                      ),
                                      BouncingWidget(
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          context.push('/auth');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              final msg = await relationNotifier.requestOrToggleFriendship(widget.userId);
                              if (msg != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: buttonBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderSubtle, width: 1),
                                boxShadow: const [AppColors.shadowTactile],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(buttonIcon, size: 16, color: buttonFg),
                                  const SizedBox(width: 8),
                                  Text(
                                    buttonLabel,
                                    style: TextStyle(
                                      color: buttonFg,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Builder(builder: (context) {
                      final accoladesEngine = ref.watch(curatorAccoladesEngineProvider);
                      final memberAccolades = ref.watch(curatorAccoladesProvider(widget.userId)).asData?.value ??
                          accoladesEngine.buildAccolades(
                            userId: widget.userId,
                            username: member.handle,
                            crownsCount: member.dropsCount >= 10 ? 1 : 0,
                            trophies: [],
                            laurels: [],
                            totalCuratorXp: member.dropsCount * 25,
                          );
                      return CuratorTrophyCabinet(
                        accolades: memberAccolades,
                        locale: currentLang,
                      );
                    }),
                    const SizedBox(height: 14),
                    CuratorTasteOverlapCard(
                      match: tasteMatch,
                      languageCode: currentLang,
                      onTap: () {
                        CuratorCoffeePingSheet.show(
                          context: context,
                          member: member,
                          match: tasteMatch,
                          languageCode: currentLang,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Recent Drops',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!canSeeHistory)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.paper2,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderHairline, width: 1),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_outline, size: 24, color: AppColors.ink),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              member.hideVisitsHistory
                                  ? '${member.name.split(' ').first} keeps their visit timeline private.'
                                  : 'Connect as mutual friends to view ${member.name.split(' ').first}’s friends-only drops.',
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.hideVisitsHistory
                                  ? 'Privacy is prioritized on Around.'
                                  : 'Once accepted, their curated recommendations will appear here.',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else if (visibleUserDrops.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle, width: 1),
                        ),
                        child: Text(
                          'No public drops published yet.',
                          style: GoogleFonts.instrumentSans(color: AppColors.ink2, fontSize: 13),
                        ),
                      )
                    else
                      ...visibleUserDrops.map((drop) => BouncingWidget(
                            onTap: () => context.push('/places/${drop.placeId}'),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderSubtle, width: 1),
                                boxShadow: const [AppColors.shadowCard],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          drop.placeName,
                                          style: GoogleFonts.bricolageGrotesque(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        drop.timeAgo,
                                        style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink3),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '“${drop.note}”',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.ink2,
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
        );
      },
    );
  }
}

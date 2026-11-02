import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/friend_presence_engine.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Horizontal presence rail displaying friends active around Tashkent (`P17-01`).
class FriendPresenceRail extends ConsumerWidget {
  final List<String>? overrideFriends;
  final List<PostModel>? overrideDrops;

  const FriendPresenceRail({
    super.key,
    this.overrideFriends,
    this.overrideDrops,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> friends = overrideFriends ?? ref.watch(followedFriendsProvider).toList();
    final List<PostModel> drops = overrideDrops ?? ref.watch(postsRepositoryProvider);
    final places = ref.watch(placesRepositoryProvider).getAllPlaces();
    final lang = ref.watch(appLocaleProvider);

    if (friends.isEmpty) {
      return const SizedBox.shrink();
    }

    final statuses = FriendPresenceEngine.computeAllStatuses(
      friendIds: friends,
      drops: drops,
      places: places,
    );

    // Sort: online first, then recent, then inactive
    final sortedFriendIds = List<String>.from(friends)
      ..sort((a, b) {
        final statusA = statuses[a];
        final statusB = statuses[b];
        if (statusA?.isOnline == true && statusB?.isOnline != true) return -1;
        if (statusB?.isOnline == true && statusA?.isOnline != true) return 1;
        if (statusA?.isRecent == true && statusB?.isRecent != true) return -1;
        if (statusB?.isRecent == true && statusA?.isRecent != true) return 1;
        return 0;
      });

    final onlineCount = statuses.values.where((s) => s.isOnline).length;
    final activeCount = statuses.values.where((s) => s.isRecent).length;

    if (activeCount == 0 && overrideFriends == null) {
      // If nobody has active drops in 24h, return minimal empty representation
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: onlineCount > 0 ? AppColors.mint : AppColors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (onlineCount > 0)
                            BoxShadow(
                              color: AppColors.mint.withValues(alpha: 0.6),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getHeaderTitle(lang).toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink2,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Text(
                    _getActiveSubtitle(activeCount, onlineCount, lang),
                    style: GoogleFonts.spaceMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: sortedFriendIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final friendId = sortedFriendIds[index];
                final status = statuses[friendId] ??
                    FriendPresenceStatus(
                      userId: friendId,
                      recency: FriendPresenceRecency.inactive,
                    );

                final member = _resolveMember(friendId);
                final displayName = member?.name.split(' ').first ?? friendId;
                final initials = member?.initials ??
                    (friendId.length >= 2 ? friendId.substring(0, 2).toUpperCase() : 'U');

                return BouncingWidget(
                  onTap: () {
                    HapticService.selection();
                    _showPresenceDetailSheet(context, member, status, lang, drops);
                  },
                  child: SizedBox(
                    width: 62,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring indicator
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: status.isOnline
                                      ? AppColors.mint
                                      : (status.isRecent
                                          ? AppColors.orange.withValues(alpha: 0.6)
                                          : AppColors.borderHairline),
                                  width: status.isOnline ? 2.5 : (status.isRecent ? 1.8 : 1),
                                ),
                                boxShadow: [
                                  if (status.isOnline)
                                    BoxShadow(
                                      color: AppColors.mint.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.paper2,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                            if (status.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.paper, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          displayName,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: status.isOnline
                                ? AppColors.mintSubtle
                                : (status.isRecent ? AppColors.butterSubtle : Colors.transparent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.district ?? (status.isRecent ? 'Active' : 'Resting'),
                            style: GoogleFonts.spaceMono(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              color: status.isOnline
                                  ? AppColors.ink
                                  : (status.isRecent ? AppColors.ink2 : AppColors.ink3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _getHeaderTitle(String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        return "Do'stlar Toshkentda";
      case 'ru':
        return 'Друзья в Ташкенте';
      case 'en':
      default:
        return 'Friends Around Tashkent';
    }
  }

  static String _getActiveSubtitle(int activeCount, int onlineCount, String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        return '$activeCount faol • $onlineCount onlayn';
      case 'ru':
        return '$activeCount активны • $onlineCount в сети';
      case 'en':
      default:
        return '$activeCount active • $onlineCount online';
    }
  }

  static CommunityMember? _resolveMember(String id) {
    try {
      return kTashkentCommunityMembers.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static void _showPresenceDetailSheet(
    BuildContext context,
    CommunityMember? member,
    FriendPresenceStatus status,
    String lang,
    List<PostModel> drops,
  ) {
    final name = member?.name ?? status.userId;
    final handle = member != null ? '@${member.handle}' : '@${status.userId}';
    final latestDrop = drops.where((d) => d.authorId == status.userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orangeSubtle,
                      border: Border.all(color: AppColors.orange),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member?.initials ?? 'U',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          handle,
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status.isOnline ? AppColors.mintSubtle : AppColors.paper2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: status.isOnline ? AppColors.mint : AppColors.borderHairline,
                      ),
                    ),
                    child: Text(
                      status.getLocalizedLabel(lang),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (latestDrop.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: AppColors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestDrop.first.placeName,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              latestDrop.first.note,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 11,
                                color: AppColors.ink2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

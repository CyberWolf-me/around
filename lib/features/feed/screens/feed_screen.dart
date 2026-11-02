import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/outbox_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/story_rail.dart';
import '../widgets/caught_up_widget.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsNotifier = ref.watch(postsRepositoryProvider.notifier);
    ref.watch(postsRepositoryProvider);
    final followedFriends = ref.watch(followedFriendsProvider);
    final blockedUsers = ref.watch(blockedUsersProvider);
    final userProfile = ref.watch(currentProfileProvider);
    final outboxCount = ref.watch(outboxCountProvider);
    final unreadNotifs = ref.watch(notificationsProvider).where((n) => n.unread).length;

    final visibleDrops = postsNotifier.getFriendsDrops(
      followedFriends,
      blockedIds: blockedUsers,
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.8,
                ),
                children: const [
                  TextSpan(text: 'Around'),
                  TextSpan(text: '.', style: TextStyle(color: AppColors.orange)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Text(
                  'Tashkent · ${userProfile.neighborhood}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          BouncingWidget(
            scaleFactor: 0.9,
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper2,
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.ink),
                ),
                if (unreadNotifs > 0)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BouncingWidget(
              scaleFactor: 0.9,
              onTap: () => context.push('/profile'),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  userProfile.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.paper,
        onRefresh: () async {
          await ref.read(postsRepositoryProvider.notifier).syncRemoteFeed();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: StoryRailWrapper(),
              ),
            ),
            if (outboxCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: BouncingWidget(
                    onTap: () async {
                      final synced = await OutboxService.drainOutbox(ref);
                      if (context.mounted && synced > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✓ Synced $synced offline drops to Around!')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.butterSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.butter, width: 1.2),
                        boxShadow: const [AppColors.shadowSubtle],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 18, color: AppColors.ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$outboxCount drop${outboxCount > 1 ? 's' : ''} saved offline · Tap to sync now',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const Icon(Icons.refresh_rounded, size: 16, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (visibleDrops.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                    boxShadow: const [AppColors.shadowCard],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.butterSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded, color: AppColors.ink, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your circle is quiet today',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connect with friends in Tashkent or tap DROP below to recommend your favorite spot.',
                        style: GoogleFonts.instrumentSans(fontSize: 12.5, color: AppColors.ink2, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      BouncingWidget(
                        onTap: () => context.go('/explore'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.explore_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Discover Tashkent Venues',
                                style: GoogleFonts.instrumentSans(
                                  color: Colors.white,
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
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = visibleDrops[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: BentoCard(
                          post: post,
                          onTap: () => context.push('/places/${post.placeId}'),
                        ),
                      );
                    },
                    childCount: visibleDrops.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CaughtUpWidget(
                  onExploreTapped: () => context.go('/explore'),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryRailWrapper extends ConsumerWidget {
  const StoryRailWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StoryRail(
      onSelectPlace: (placeId) => context.push('/places/$placeId'),
    );
  }
}

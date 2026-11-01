import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
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

    final visibleDrops = postsNotifier.getFriendsDrops(
      followedFriends,
      blockedIds: blockedUsers,
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Tashkent · ${userProfile.neighborhood}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 22, color: AppColors.ink),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.orange,
                child: Text(
                  userProfile.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: StoryRailWrapper(),
            ),
          ),
          if (visibleDrops.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [AppColors.shadow],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppColors.butter,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline, color: AppColors.ink, size: 28),
                    ),
                    const SizedBox(height: 12),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/explore'),
                      icon: const Icon(Icons.explore, size: 16, color: Colors.white),
                      label: const Text('Discover Tashkent Venues', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.ink, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = visibleDrops[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
            child: SizedBox(height: 70),
          ),
        ],
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

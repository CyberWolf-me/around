import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    ref.watch(postsRepositoryProvider); // trigger rebuild on post changes
    final followedFriends = ref.watch(followedFriendsProvider);
    final userProfile = ref.watch(currentProfileProvider);

    final visibleDrops = postsNotifier.getFriendsDrops(followedFriends);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'BricolageGrotesque',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.8,
                ),
                children: [
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
                border: Border.all(color: AppColors.ink.withOpacity(0.2)),
              ),
              child: Text(
                'Tashkent',
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 70), // tab bar clearance
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

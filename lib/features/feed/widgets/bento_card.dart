import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'comments_sheet.dart';

class BentoCard extends ConsumerWidget {
  final PostModel post;
  final VoidCallback onTap;

  const BentoCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlaces = ref.watch(savedPlacesProvider);
    final isSaved = savedPlaces.contains(post.placeId);

    // Note Card (Text First)
    if (post.size == PostSize.note || post.mediaUrl == null) {
      return GestureDetector(
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: post.tint ?? AppColors.butter,
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [AppColors.shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      context.push('/users/${post.authorId}');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.ink,
                          child: Text(
                            post.authorAvatar ?? post.authorName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          post.authorName.split(' ').first,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _AudiencePill(isFriends: post.isFriendsOnly),
                  const Spacer(),
                  Text(
                    post.placeCategory.split('·').first.trim(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '“${post.note}”',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.placeName,
                          style: const TextStyle(
                            color: AppColors.paper,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.north_east, size: 10, color: AppColors.paper),
                      ],
                    ),
                  ),
                  ...post.tags.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 9.5, color: AppColors.ink2),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      ref.read(postsRepositoryProvider.notifier).reactToPost(post.id, reaction: post.userReaction ?? 'heart');
                    },
                    onLongPress: () => _showReactionPicker(context, ref, post.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: post.userReaction != null ? AppColors.orange.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: post.userReaction != null ? AppColors.orange : AppColors.ink.withValues(alpha: 0.3),
                          width: post.userReaction != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _reactionIcon(post.userReaction),
                            size: 11,
                            color: _reactionColor(post.userReaction),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${post.savesCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      CommentsSheet.show(context, postId: post.id, postTitle: '${post.authorName} at ${post.placeName}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 11, color: AppColors.ink2),
                          SizedBox(width: 3),
                          Text(
                            'Comment',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Photo Card
    final double imgHeight = post.size == PostSize.hero
        ? 200.0
        : (post.size == PostSize.wide ? 140.0 : 120.0);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [AppColors.shadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: imgHeight,
                  width: double.infinity,
                  child: AppImage(
                    path: post.mediaUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _AudiencePill(isFriends: post.isFriendsOnly),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticService.medium();
                      ref.read(savedPlacesProvider.notifier).toggleSave(post.placeId);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSaved ? AppColors.orange : AppColors.paper.withValues(alpha: 0.92),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [AppColors.shadowSm],
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 15,
                        color: isSaved ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          context.push('/users/${post.authorId}');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: AppColors.ink,
                              child: Text(
                                post.authorAvatar ?? post.authorName[0],
                                style: const TextStyle(color: Colors.white, fontSize: 8),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              post.authorName.split(' ').first,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.timeAgo,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    post.placeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    post.note,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink2,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          ref.read(postsRepositoryProvider.notifier).reactToPost(post.id, reaction: post.userReaction ?? 'heart');
                        },
                        onLongPress: () => _showReactionPicker(context, ref, post.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: post.userReaction != null ? AppColors.orange.withValues(alpha: 0.18) : AppColors.paper2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: post.userReaction != null ? AppColors.orange : AppColors.ink.withValues(alpha: 0.2),
                              width: post.userReaction != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _reactionIcon(post.userReaction),
                                size: 12,
                                color: _reactionColor(post.userReaction),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.savesCount}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          CommentsSheet.show(context, postId: post.id, postTitle: '${post.authorName} at ${post.placeName}');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.ink2),
                              SizedBox(width: 4),
                              Text(
                                'Comment',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.placeCategory.split('·').first.trim(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _reactionIcon(String? reaction) {
    switch (reaction) {
      case 'fire':
        return Icons.local_fire_department;
      case 'coffee':
        return Icons.coffee;
      case 'bookmark_nod':
        return Icons.bookmark;
      case 'heart':
      default:
        return Icons.favorite;
    }
  }

  Color _reactionColor(String? reaction) {
    switch (reaction) {
      case 'fire':
        return AppColors.orange;
      case 'coffee':
        return const Color(0xFF8D6E63);
      case 'bookmark_nod':
        return AppColors.ink;
      case 'heart':
      default:
        return reaction != null ? AppColors.danger : AppColors.danger.withValues(alpha: 0.6);
    }
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref, String postId) {
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'React to Drop',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReactionOption(ctx, ref, postId, 'heart', Icons.favorite, 'Love', AppColors.danger),
                _buildReactionOption(ctx, ref, postId, 'fire', Icons.local_fire_department, 'Fire', AppColors.orange),
                _buildReactionOption(ctx, ref, postId, 'coffee', Icons.coffee, 'Vibe', const Color(0xFF8D6E63)),
                _buildReactionOption(ctx, ref, postId, 'bookmark_nod', Icons.bookmark, 'Saved', AppColors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionOption(
    BuildContext ctx,
    WidgetRef ref,
    String postId,
    String reaction,
    IconData icon,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        Navigator.pop(ctx);
        ref.read(postsRepositoryProvider.notifier).reactToPost(postId, reaction: reaction);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.paper2,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _AudiencePill extends StatelessWidget {
  final bool isFriends;

  const _AudiencePill({required this.isFriends});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isFriends ? AppColors.butter : AppColors.ink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ink, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFriends ? Icons.lock : Icons.public,
            size: 9,
            color: isFriends ? AppColors.ink : AppColors.paper,
          ),
          const SizedBox(width: 3),
          Text(
            isFriends ? 'Friends' : 'Public',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isFriends ? AppColors.ink : AppColors.paper,
            ),
          ),
        ],
      ),
    );
  }
}

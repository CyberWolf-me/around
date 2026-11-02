import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
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
      return BouncingWidget(
        scaleFactor: 0.985,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: post.tint ?? AppColors.paper2,
            border: Border.all(color: AppColors.borderSubtle, width: 1.0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [AppColors.shadowCard],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BouncingWidget(
                    scaleFactor: 0.94,
                    onTap: () => context.push('/users/${post.authorId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.ink,
                          child: Text(
                            post.authorAvatar ?? post.authorName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.authorName.split(' ').first,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AudiencePill(isFriends: post.isFriendsOnly),
                  const Spacer(),
                  Text(
                    post.placeCategory.split('·').first.trim(),
                    style: GoogleFonts.spaceMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '“${post.note}”',
                style: GoogleFonts.instrumentSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.placeName,
                          style: GoogleFonts.instrumentSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.north_east_rounded, size: 11, color: Colors.white),
                      ],
                    ),
                  ),
                  ...post.tags.take(3).map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                  ),
                  BouncingWidget(
                    scaleFactor: 0.92,
                    onTap: () {
                      ref.read(postsRepositoryProvider.notifier).reactToPost(post.id, reaction: post.userReaction ?? 'heart');
                    },
                    onLongPress: () => _showReactionPicker(context, ref, post.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: post.userReaction != null ? AppColors.orangeSubtle : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: post.userReaction != null ? AppColors.orange : AppColors.borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _reactionIcon(post.userReaction),
                            size: 13,
                            color: _reactionColor(post.userReaction),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.reactionsCount}',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BouncingWidget(
                    scaleFactor: 0.92,
                    onTap: () {
                      CommentsSheet.show(context, postId: post.id, postTitle: '${post.authorName} at ${post.placeName}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppColors.ink2),
                          const SizedBox(width: 4),
                          Text(
                            'Comment',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
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

    // Photo Card (Rich Editorial Discovery)
    final double imgHeight = post.size == PostSize.hero
        ? 210.0
        : (post.size == PostSize.wide ? 165.0 : 145.0);

    return BouncingWidget(
      scaleFactor: 0.985,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [AppColors.shadowCard],
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
                // Gradient Scrim for Top Controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.38),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Audience Pill
                Positioned(
                  top: 10,
                  left: 10,
                  child: _AudiencePill(isFriends: post.isFriendsOnly),
                ),
                // Bookmark Save Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: BookmarkButton(
                    isSaved: isSaved,
                    size: 34,
                    onToggle: () {
                      ref.read(savedPlacesProvider.notifier).toggleSave(post.placeId);
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BouncingWidget(
                        scaleFactor: 0.94,
                        onTap: () => context.push('/users/${post.authorId}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: AppColors.ink,
                              child: Text(
                                post.authorAvatar ?? post.authorName[0],
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              post.authorName.split(' ').first,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.timeAgo,
                        style: GoogleFonts.spaceMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.placeName,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.note,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 13,
                      color: AppColors.ink2,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      BouncingWidget(
                        scaleFactor: 0.92,
                        onTap: () {
                          ref.read(postsRepositoryProvider.notifier).reactToPost(post.id, reaction: post.userReaction ?? 'heart');
                        },
                        onLongPress: () => _showReactionPicker(context, ref, post.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: post.userReaction != null ? AppColors.orangeSubtle : AppColors.paper2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: post.userReaction != null ? AppColors.orange : AppColors.borderHairline,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _reactionIcon(post.userReaction),
                                size: 13,
                                color: _reactionColor(post.userReaction),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.reactionsCount}',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BouncingWidget(
                        scaleFactor: 0.92,
                        onTap: () {
                          CommentsSheet.show(context, postId: post.id, postTitle: '${post.authorName} at ${post.placeName}');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.borderHairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppColors.ink2),
                              const SizedBox(width: 4),
                              Text(
                                'Comment',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.placeCategory.split('·').first.trim(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink3,
                          ),
                        ),
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
        return Icons.local_fire_department_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'bookmark_nod':
        return Icons.bookmark_rounded;
      case 'heart':
      default:
        return Icons.favorite_rounded;
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
        return reaction != null ? AppColors.danger : AppColors.danger.withValues(alpha: 0.65);
    }
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref, String postId) {
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [AppColors.shadowFloating],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'React to Drop',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReactionOption(ctx, ref, postId, 'heart', Icons.favorite_rounded, 'Love', AppColors.danger),
                _buildReactionOption(ctx, ref, postId, 'fire', Icons.local_fire_department_rounded, 'Fire', AppColors.orange),
                _buildReactionOption(ctx, ref, postId, 'coffee', Icons.coffee_rounded, 'Vibe', const Color(0xFF8D6E63)),
                _buildReactionOption(ctx, ref, postId, 'bookmark_nod', Icons.bookmark_rounded, 'Saved', AppColors.ink),
              ],
            ),
            const SizedBox(height: 10),
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
    return BouncingWidget(
      onTap: () {
        Navigator.pop(ctx);
        ref.read(postsRepositoryProvider.notifier).reactToPost(postId, reaction: reaction);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper2,
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isFriends ? AppColors.butter : AppColors.ink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ink, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFriends ? Icons.lock_rounded : Icons.public_rounded,
            size: 9.5,
            color: isFriends ? AppColors.ink : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isFriends ? 'Friends' : 'Public',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isFriends ? AppColors.ink : Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

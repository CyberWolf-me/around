import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../create_post/screens/create_drop_sheet.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  int _tabIndex = 0; // 0 = Friends' Drops, 1 = Public Reviews

  Future<void> _copyShareLink(PlaceModel place) async {
    HapticService.light();
    final link = 'https://around.app/places/${place.slug}';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied link: $link'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDirectionsDialog(PlaceModel place) {
    HapticService.light();
    final coordsText = '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.ink, width: 2.5),
            left: BorderSide(color: AppColors.ink, width: 2),
            right: BorderSide(color: AppColors.ink, width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Walk to ${place.name}',
              style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${place.streetAddress}, ${place.district}, ${place.city}',
              style: const TextStyle(fontSize: 13, color: AppColors.ink2),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimated: ${place.walkDistanceLabel} (${place.distanceMeters.round()}m) · GPS: $coordsText',
              style: GoogleFonts.spaceMono(fontSize: 10.5, color: AppColors.ink3),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: '${place.name}, ${place.streetAddress}, Tashkent ($coordsText)'));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Venue address & GPS coordinates copied for Yandex / Google Maps')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                label: const Text('Copy Address & Coordinates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.ink, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportOrBlockSheet({required String targetType, required String targetId, String? authorId, String? authorName}) {
    HapticService.medium();
    final myId = SupabaseService.currentUser?.id ?? ref.read(currentProfileProvider).id;
    final reasons = [
      'Inappropriate photo or text',
      'Spam or promotional shilling',
      'Wrong venue / inaccurate location',
      'Harassment or privacy violation',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.ink, width: 2.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety & Moderation',
              style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...reasons.map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined, color: AppColors.orange, size: 18),
                  title: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    var quarantined = false;
                    if (targetType == 'post') {
                      quarantined = await ref.read(postsRepositoryProvider.notifier).reportPost(targetId, r);
                    } else {
                      await StorageService.addReport({
                        'target_type': targetType,
                        'target_id': targetId,
                        'reason': r,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            quarantined
                                ? 'Drop automatically quarantined after reaching 3 community reports.'
                                : 'Report submitted: "$r"',
                          ),
                        ),
                      );
                    }
                  },
                )),
            if (authorId != null && authorId != myId && authorId != 'you') ...[
              const Divider(),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: AppColors.danger, size: 18),
                title: Text(
                  'Block @${authorName ?? authorId}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
                onTap: () async {
                  await ref.read(blockedUsersProvider.notifier).blockUser(authorId);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Blocked ${authorName ?? authorId}. Their drops are now hidden.')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placesRepo = ref.watch(placesRepositoryProvider);
    final postsNotifier = ref.watch(postsRepositoryProvider.notifier);
    ref.watch(postsRepositoryProvider);
    final followedFriends = ref.watch(followedFriendsProvider);
    final blockedUsers = ref.watch(blockedUsersProvider);
    final savedPlaces = ref.watch(savedPlacesProvider);

    final place = placesRepo.getPlaceById(widget.placeId);
    if (place == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Place not found')),
      );
    }

    final isSaved = savedPlaces.contains(place.id);
    final friendDrops = postsNotifier.getDropsForPlace(
      place.id,
      friendsOnly: true,
      followedIds: followedFriends,
      blockedIds: blockedUsers,
    );
    final publicDrops = postsNotifier.getDropsForPlace(
      place.id,
      friendsOnly: false,
      blockedIds: blockedUsers,
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.ink),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Place · ${place.shortCategory}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.orange : AppColors.ink,
                ),
                onPressed: () {
                  HapticService.medium();
                  ref.read(savedPlacesProvider.notifier).toggleSave(place.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSaved ? 'Removed from saved' : 'Saved to your shortlist'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.ink),
                onPressed: () => _copyShareLink(place),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: AppColors.ink3, size: 20),
                tooltip: 'Report Venue',
                onPressed: () => _showReportOrBlockSheet(targetType: 'place', targetId: place.id),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [AppColors.shadow],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      path: place.heroImageUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x3015130F),
                            Color(0xBB15130F),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: Text(
                                  place.shortCategory,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  place.statusLine,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            place.name,
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${place.streetAddress} · ${place.walkDistanceLabel}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paper2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink, width: 1.8),
                        boxShadow: const [AppColors.shadowSm],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${place.ratingAvg}',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.star, size: 14, color: AppColors.orange),
                            ],
                          ),
                          Text(
                            '${place.ratingCount} public ratings',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink, width: 1.8),
                        boxShadow: const [AppColors.shadowSm],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${friendDrops.length} ${friendDrops.length == 1 ? 'friend' : 'friends'}',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'dropped this spot',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: Text(
                  '“${place.description}”',
                  style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.ink2),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: place.tags.map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
                    ),
                    child: Text('#$t', style: const TextStyle(fontSize: 10.5, color: AppColors.ink2)),
                  ),
                ).toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          setState(() => _tabIndex = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Friends' Drops (${friendDrops.length})",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _tabIndex == 0 ? AppColors.paper : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          setState(() => _tabIndex = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Public Reviews (${publicDrops.length})",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _tabIndex == 1 ? AppColors.paper : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final List<PostModel> list = _tabIndex == 0 ? friendDrops : publicDrops;
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        _tabIndex == 0 ? 'No drops from friends yet.' : 'No public reviews yet.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  final post = list[index];
                  return Container(
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
                            GestureDetector(
                              onTap: () => context.push('/users/${post.authorId}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.ink,
                                    child: Text(
                                      post.authorAvatar ?? post.authorName[0],
                                      style: const TextStyle(color: Colors.white, fontSize: 9),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    post.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(post.timeAgo, style: Theme.of(context).textTheme.labelSmall),
                            IconButton(
                              icon: const Icon(Icons.more_horiz, size: 16, color: AppColors.ink3),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showReportOrBlockSheet(
                                targetType: 'post',
                                targetId: post.id,
                                authorId: post.authorId,
                                authorName: post.authorUsername,
                              ),
                            ),
                          ],
                        ),
                        if (post.mediaUrl != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: AppImage(path: post.mediaUrl!, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '“${post.note}”',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                        ),
                      ],
                    ),
                  );
                },
                childCount: (_tabIndex == 0 ? friendDrops : publicDrops).isEmpty
                    ? 1
                    : (_tabIndex == 0 ? friendDrops.length : publicDrops.length),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.ink, width: 1.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDirectionsDialog(place),
                icon: const Icon(Icons.navigation, size: 16, color: AppColors.ink),
                label: const Text('Directions', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.ink, width: 1.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticService.medium();
                  if (!SupabaseService.isAuthenticated) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.ink, width: 2),
                        ),
                        title: Text('Account Required', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800)),
                        content: const Text('Sign in or create an account to drop recommendations and share spots with friends.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.ink3))),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/auth');
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CreateDropSheet(presetPlaceId: place.id),
                  );
                },
                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                label: const Text('Drop This Place', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.ink, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

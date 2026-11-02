import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/collections_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../create_post/screens/create_drop_sheet.dart';
import '../../feed/widgets/comments_sheet.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  int _tabIndex = 0; // 0 = Friends' Drops, 1 = Public Reviews

  Future<void> _copyShareLink(PlaceModel place) async {
    final link = await DeepLinkService.copyPlaceShareLink(place.slug);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied link: $link'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddToCollectionSheet(String placeId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final collections = ref.watch(collectionsRepositoryProvider);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inkLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.collections_bookmark_rounded, size: 20, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Save to Collection',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (collections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No collections created yet. Go to Saved tab to create one.',
                      style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink3),
                    ),
                  ),
                )
              else
                ...collections.map((col) {
                  final inCol = col.placeIds.contains(placeId);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      inCol ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: inCol ? AppColors.orange : AppColors.ink3,
                      size: 22,
                    ),
                    title: Text(col.title, style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${col.placeIds.length} spots · ${col.audience}', style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink3)),
                    onTap: () {
                      HapticService.selection();
                      if (inCol) {
                        ref.read(collectionsRepositoryProvider.notifier).removePlaceFromCollection(col.id, placeId);
                      } else {
                        ref.read(collectionsRepositoryProvider.notifier).addPlaceToCollection(col.id, placeId);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(inCol ? 'Removed from ${col.title}' : 'Added to ${col.title}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchMapsUrl(BuildContext ctx, Uri nativeUri, Uri webFallbackUri) async {
    HapticService.selection();
    if (ctx.mounted) Navigator.pop(ctx);
    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map navigation application')),
          );
        }
      }
    }
  }

  void _showDirectionsDialog(PlaceModel place) {
    final coordsText = '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}';
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.inkLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Walk to ${place.name}',
              style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Text(
              '${place.streetAddress}, ${place.district}, ${place.city}',
              style: GoogleFonts.instrumentSans(fontSize: 13.5, color: AppColors.ink2),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimated: ${place.walkDistanceLabel} (${place.distanceMeters.round()}m) · GPS: $coordsText',
              style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink3),
            ),
            const SizedBox(height: 18),
            // Yandex Maps (Primary in Tashkent)
            SizedBox(
              width: double.infinity,
              child: BouncingWidget(
                onTap: () {
                  final native = Uri.parse('yandexmaps://build_route_on_map?lat_to=${place.latitude}&lon_to=${place.longitude}');
                  final web = Uri.parse('https://yandex.com/maps/?rtext=~${place.latitude}%2C${place.longitude}&rtt=pd');
                  _launchMapsUrl(ctx, native, web);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation_rounded, size: 17, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Open in Yandex Maps (Tashkent Standard)',
                        style: GoogleFonts.instrumentSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Google Maps
            SizedBox(
              width: double.infinity,
              child: BouncingWidget(
                onTap: () {
                  final native = Uri.parse('geo:${place.latitude},${place.longitude}?q=${place.latitude},${place.longitude}(${Uri.encodeComponent(place.name)})');
                  final web = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}');
                  _launchMapsUrl(ctx, native, web);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_outlined, size: 17, color: AppColors.ink),
                      const SizedBox(width: 8),
                      Text(
                        'Open in Google Maps',
                        style: GoogleFonts.instrumentSans(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Copy Address & GPS
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: '${place.name}, ${place.streetAddress}, Tashkent ($coordsText)'));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Venue address & GPS coordinates copied to clipboard')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.ink2),
                label: Text(
                  'Copy Address & GPS Coordinates',
                  style: GoogleFonts.instrumentSans(color: AppColors.ink2, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportOrBlockSheet({required String targetType, required String targetId, String? authorId, String? authorName}) {
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
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [AppColors.shadowFloating],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety & Moderation',
              style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
            ),
            const SizedBox(height: 10),
            ...reasons.map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined, color: AppColors.orange, size: 18),
                  title: Text(r, style: GoogleFonts.instrumentSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
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
              const Divider(color: AppColors.borderHairline),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_rounded, color: AppColors.danger, size: 18),
                title: Text(
                  'Block @${authorName ?? authorId}',
                  style: GoogleFonts.instrumentSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.danger),
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
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Place · ${place.shortCategory}',
              style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink3),
            ),
            actions: [
              BookmarkButton(
                isSaved: isSaved,
                size: 36,
                onToggle: () {
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
                icon: const Icon(Icons.playlist_add_rounded, color: AppColors.ink),
                tooltip: 'Add to Collection',
                onPressed: () => _showAddToCollectionSheet(place.id),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: AppColors.ink, size: 20),
                onPressed: () => _copyShareLink(place),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: AppColors.ink3, size: 20),
                tooltip: 'Report Venue',
                onPressed: () => _showReportOrBlockSheet(targetType: 'place', targetId: place.id),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  boxShadow: const [AppColors.shadowCard],
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
                            Color(0x2515130F),
                            Color(0xC815130F),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  place.shortCategory,
                                  style: GoogleFonts.instrumentSans(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    place.statusLine,
                                    style: GoogleFonts.spaceMono(
                                      color: AppColors.ink,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            place.name,
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${place.streetAddress} · ${place.walkDistanceLabel}',
                                  style: GoogleFonts.instrumentSans(color: Colors.white, fontSize: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                        boxShadow: const [AppColors.shadowSubtle],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${place.ratingAvg}',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.orange),
                            ],
                          ),
                          Text(
                            '${place.ratingCount} community ratings',
                            style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.butterSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.butter, width: 1.0),
                        boxShadow: const [AppColors.shadowSubtle],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${friendDrops.length} ${friendDrops.length == 1 ? 'friend' : 'friends'}',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'dropped this spot',
                            style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink2),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Text(
                  '“${place.description}”',
                  style: GoogleFonts.instrumentSans(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.ink2, height: 1.4),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: place.tags.map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Text(
                      '#$t',
                      style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink2, fontWeight: FontWeight.w500),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        scaleFactor: 0.95,
                        onTap: () => setState(() => _tabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _tabIndex == 0 ? const [AppColors.shadowSubtle] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Friends' Drops (${friendDrops.length})",
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _tabIndex == 0 ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: BouncingWidget(
                        scaleFactor: 0.95,
                        onTap: () => setState(() => _tabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _tabIndex == 1 ? const [AppColors.shadowSubtle] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Public Reviews (${publicDrops.length})",
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _tabIndex == 1 ? Colors.white : AppColors.ink,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final List<PostModel> list = _tabIndex == 0 ? friendDrops : publicDrops;
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: Text(
                        _tabIndex == 0 ? 'No drops from friends yet.' : 'No public reviews yet.',
                        style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink3),
                      ),
                    );
                  }
                  final post = list[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle, width: 1.0),
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
                                    radius: 12,
                                    backgroundColor: AppColors.ink,
                                    child: Text(
                                      post.authorAvatar ?? post.authorName[0],
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    post.authorName,
                                    style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(post.timeAgo, style: GoogleFonts.spaceMono(fontSize: 9.5, color: AppColors.ink3)),
                            IconButton(
                              icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.ink3),
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
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 130,
                              width: double.infinity,
                              child: AppImage(path: post.mediaUrl!, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '“${post.note}”',
                          style: GoogleFonts.instrumentSans(fontSize: 13.5, color: AppColors.ink, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            BouncingWidget(
                              scaleFactor: 0.92,
                              onTap: () {
                                ref.read(postsRepositoryProvider.notifier).reactToPost(post.id, reaction: post.userReaction ?? 'heart');
                              },
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
                                      post.userReaction == 'fire'
                                          ? Icons.local_fire_department_rounded
                                          : (post.userReaction == 'coffee'
                                              ? Icons.coffee_rounded
                                              : (post.userReaction == 'bookmark_nod'
                                                  ? Icons.bookmark_rounded
                                                  : Icons.favorite_rounded)),
                                      size: 13,
                                      color: post.userReaction != null ? AppColors.danger : AppColors.danger.withValues(alpha: 0.65),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post.savesCount}',
                                      style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BouncingWidget(
                              scaleFactor: 0.92,
                              onTap: () {
                                CommentsSheet.show(
                                  context,
                                  postId: post.id,
                                  postTitle: '${post.authorName} at ${post.placeName}',
                                );
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
                                      style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.borderHairline, width: 1.0)),
          boxShadow: [AppColors.shadowSubtle],
        ),
        child: Row(
          children: [
            Expanded(
              child: BouncingWidget(
                onTap: () => _showDirectionsDialog(place),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_rounded, size: 15, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Directions',
                          style: GoogleFonts.instrumentSans(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: BouncingWidget(
                onTap: () {
                  if (!SupabaseService.isAuthenticated) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Drop This Place',
                          style: GoogleFonts.instrumentSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

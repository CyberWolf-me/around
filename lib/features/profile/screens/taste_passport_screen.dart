import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../widgets/curator_trophy_cabinet.dart';
import '../widgets/taste_passport_card.dart';
import '../widgets/taste_radar_widget.dart';
import '../widgets/trophy_cabinet_widget.dart';
import '../../../core/services/curator_accolades_engine.dart';
import '../../../data/repositories/curator_accolades_repository.dart';

/// Screen displaying a user's shareable Tashkent Taste Passport.
/// Can be opened directly or via deep link: around://passport/:username
class TastePassportScreen extends ConsumerStatefulWidget {
  final String username;

  const TastePassportScreen({super.key, required this.username});

  @override
  ConsumerState<TastePassportScreen> createState() => _TastePassportScreenState();
}

class _TastePassportScreenState extends ConsumerState<TastePassportScreen> {
  late Future<CommunityMember?> _memberFuture;

  @override
  void initState() {
    super.initState();
    _memberFuture = fetchCommunityMember(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider);
    final currentLang = ref.watch(appLocaleProvider);
    final accoladesEngine = ref.watch(curatorAccoladesEngineProvider);
    final isMe = widget.username == 'you' ||
        widget.username.toLowerCase() == currentProfile.username.toLowerCase() ||
        widget.username == currentProfile.id;

    if (isMe) {
      final myDrops = ref.watch(postsRepositoryProvider).where((p) => p.authorId == currentProfile.id).toList();
      final savedIds = ref.watch(savedPlacesProvider);
      final allPlaces = ref.watch(placesRepositoryProvider).getAllPlaces();
      final topPlaces = savedIds
          .map((id) => allPlaces.where((p) => p.id == PlacesRepository.resolveCanonicalId(id)).firstOrNull)
          .whereType<PlaceModel>()
          .take(4)
          .toList();

      final dropDistricts = myDrops
          .map((d) => allPlaces.where((p) => p.id == d.placeId).firstOrNull?.district ?? '')
          .where((d) => d.isNotEmpty)
          .toList();
      final visitedIds = myDrops.map((d) => d.placeId).toSet()..addAll(savedIds);
      final trophies = TrophyCabinetWidget.createDefaultTrophies(
        visitedPlaceIds: visitedIds,
        streakWeeks: myDrops.isNotEmpty ? 4 : 0,
        userDropDistricts: dropDistricts,
      );

      final myAccolades = ref.watch(curatorAccoladesProvider(currentProfile.id)).asData?.value ??
          accoladesEngine.buildAccolades(
            userId: currentProfile.id,
            username: currentProfile.username,
            crownsCount: 0,
            trophies: [],
            laurels: [],
            totalCuratorXp: myDrops.length * 20,
          );

      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: AppColors.paper,
          elevation: 0,
          leading: const BackButton(color: AppColors.ink),
          title: Text(
            'Tashkent Taste Passport',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.ink),
              tooltip: 'Copy Passport Link',
              onPressed: () {
                DeepLinkService.copyPassportShareLink(currentProfile.username);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Passport link copied: https://around.tashkent.app/passport/${currentProfile.username}'),
                    backgroundColor: AppColors.ink,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              TastePassportCard(
                profile: currentProfile,
                topPlaces: topPlaces,
                totalDrops: myDrops.length,
                totalSaved: savedIds.length,
              ),
              const SizedBox(height: 14),
              CuratorTrophyCabinet(
                accolades: myAccolades,
                locale: currentLang,
              ),
              const SizedBox(height: 14),
              TasteRadarWidget(
                places: topPlaces,
                languageCode: currentLang,
              ),
              const SizedBox(height: 14),
              TrophyCabinetWidget(
                trophies: trophies,
                curatorName: currentProfile.fullName,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: AppColors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your Tashkent Taste Passport automatically reflects your verified venue drops and saved district favorites.',
                        style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<CommunityMember?>(
      future: _memberFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.paper,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2.5),
            ),
          );
        }

        final member = snapshot.data;
        if (member == null) {
          return Scaffold(
            backgroundColor: AppColors.paper,
            appBar: AppBar(leading: const BackButton(color: AppColors.ink)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied, size: 48, color: AppColors.ink3),
                    const SizedBox(height: 12),
                    Text(
                      'Taste Passport Not Found',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No Tashkent curator was found for "@${widget.username}".',
                      style: const TextStyle(color: AppColors.ink2, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final allPosts = ref.watch(postsRepositoryProvider);
        final memberPosts = allPosts.where((p) => p.authorId == member.id).toList();
        final allPlaces = ref.watch(placesRepositoryProvider).getAllPlaces();

        // Get places from their drops or neighborhood
        final topPlaces = memberPosts
            .map((p) => allPlaces.where((pl) => pl.id == p.placeId).firstOrNull)
            .whereType<PlaceModel>()
            .toSet()
            .toList();

        // If topPlaces is empty, backfill with places from their neighborhood
        if (topPlaces.isEmpty) {
          topPlaces.addAll(
            allPlaces.where((p) => p.district.toLowerCase() == member.neighborhood.toLowerCase()).take(3),
          );
        }

        final memberDistricts = memberPosts
            .map((d) => allPlaces.where((p) => p.id == d.placeId).firstOrNull?.district ?? '')
            .where((d) => d.isNotEmpty)
            .toList();
        if (memberDistricts.isEmpty && member.neighborhood.isNotEmpty) {
          memberDistricts.add(member.neighborhood);
        }
        final memberVisitedIds = memberPosts.map((d) => d.placeId).toSet()..addAll(topPlaces.map((p) => p.id));
        final trophies = TrophyCabinetWidget.createDefaultTrophies(
          visitedPlaceIds: memberVisitedIds,
          streakWeeks: member.dropsCount >= 5 ? 4 : 2,
          userDropDistricts: memberDistricts,
        );

        final memberAccolades = ref.watch(curatorAccoladesProvider(member.id)).asData?.value ??
            accoladesEngine.buildAccolades(
              userId: member.id,
              username: member.handle,
              crownsCount: member.dropsCount >= 10 ? 1 : 0,
              trophies: [],
              laurels: [],
              totalCuratorXp: member.dropsCount * 25,
            );

        final memberProfile = ProfileModel(
          id: member.id,
          username: member.handle,
          fullName: member.name,
          bio: member.bio,
          neighborhood: member.neighborhood,
          dropsCount: member.dropsCount,
          friendsCount: 0,
          savedCount: topPlaces.length,
          hideVisitsHistory: member.hideVisitsHistory,
          defaultAudience: 'public',
          discoverableByFriends: true,
          quietHours: false,
          allowFriendRequests: member.allowFriendRequests,
        );

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            backgroundColor: AppColors.paper,
            elevation: 0,
            leading: const BackButton(color: AppColors.ink),
            title: Text(
              '${member.name}\'s Passport',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.ink),
                tooltip: 'Copy Passport Link',
                onPressed: () {
                  DeepLinkService.copyPassportShareLink(member.handle);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Passport link copied: https://around.tashkent.app/passport/${member.handle}'),
                      backgroundColor: AppColors.ink,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                TastePassportCard(
                  profile: memberProfile,
                  topPlaces: topPlaces,
                  totalDrops: member.dropsCount,
                  totalSaved: topPlaces.length,
                ),
                const SizedBox(height: 14),
                CuratorTrophyCabinet(
                  accolades: memberAccolades,
                  locale: currentLang,
                ),
                const SizedBox(height: 14),
                TasteRadarWidget(
                  places: topPlaces,
                  languageCode: currentLang,
                ),
                const SizedBox(height: 14),
                TrophyCabinetWidget(
                  trophies: trophies,
                  curatorName: member.name,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/collections_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../core/services/atmosphere_service.dart';
import '../widgets/category_chips.dart';
import '../widgets/city_map_widget.dart';
import '../widgets/venue_row_widget.dart';
import '../../places/widgets/district_density_overlay.dart';
import 'package:latlong2/latlong.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  // 0 = Map, 1 = List, 2 = For You (Intelligent Explainable Recommendations)
  int _viewMode = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedPlaceId = 'breadly';
  String? _selectedDistrict;
  LatLng? _mapTargetLocation;
  bool _atmosphereActive = false;
  late AtmosphereInfo _currentAtmosphere;
  late Future<List<PlaceModel>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _currentAtmosphere = AtmosphereService.getCurrentInfo();
    _refreshPlaces();
  }

  void _refreshPlaces() {
    _placesFuture = ref.read(placesRepositoryProvider).getNearbyPlaces(
          category: _atmosphereActive ? 'All' : _selectedCategory,
          searchQuery: _searchQuery,
        ).then((places) {
          if (_atmosphereActive) {
            return AtmosphereService.filterPlaces(places, _currentAtmosphere.mode);
          }
          return places;
        });
  }

  @override
  Widget build(BuildContext context) {
    final placesRepo = ref.watch(placesRepositoryProvider);
    final savedPlaces = ref.watch(savedPlacesProvider);
    final savedStatuses = ref.watch(savedPlaceStatusesProvider);
    final followedFriends = ref.watch(followedFriendsProvider);
    final allDrops = ref.watch(postsRepositoryProvider);
    final collections = ref.watch(collectionsRepositoryProvider);

    // Compute explainable recommendations
    final friendPlaceIds = allDrops
        .where((d) => followedFriends.contains(d.authorId))
        .map((d) => d.placeId)
        .toSet();

    final recommendations = placesRepo.getRecommendedPlaces(
      acceptedFriendPlaceIds: friendPlaceIds,
      savedPlaceIds: savedPlaces.toSet(),
      savedStatuses: savedStatuses,
    );

    final densityAsync = ref.watch(districtDensityProvider);
    final densities = densityAsync.asData?.value ?? const <DistrictDensityModel>[];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewMode == 2 ? 'Personalized Discovery' : 'Tashkent Exploration',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.ink3,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              _viewMode == 2 ? 'Recommended for You' : 'Tashkent Community',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              children: [
                _ViewToggleButton(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  isSelected: _viewMode == 0,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _viewMode = 0);
                  },
                ),
                _ViewToggleButton(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'List',
                  isSelected: _viewMode == 1,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _viewMode = 1);
                  },
                ),
                _ViewToggleButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'For You',
                  isSelected: _viewMode == 2,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _viewMode = 2);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: _viewMode == 2
          ? _buildRecommendationsView(recommendations, savedPlaces, collections, placesRepo)
          : FutureBuilder<List<PlaceModel>>(
              future: _placesFuture,
              builder: (context, snapshot) {
                final places = snapshot.data ?? [];
                final selectedPlace = placesRepo.getPlaceById(_selectedPlaceId) ?? (places.isNotEmpty ? places.first : null);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                          boxShadow: const [AppColors.shadowSubtle],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 20, color: AppColors.ink3),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                    _refreshPlaces();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search cafés, plov, study spots...',
                                  hintStyle: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.inkLight),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Colors.transparent,
                                  filled: false,
                                ),
                                style: GoogleFonts.instrumentSans(fontSize: 13.5, color: AppColors.ink),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              BouncingWidget(
                                onTap: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _refreshPlaces();
                                  });
                                },
                                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.ink3),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Atmosphere Rhythm Indicator & Quick Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _atmosphereActive ? _currentAtmosphere.bgTint : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _atmosphereActive ? _currentAtmosphere.accentColor : AppColors.borderHairline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _currentAtmosphere.icon,
                              size: 16,
                              color: _atmosphereActive ? _currentAtmosphere.accentColor : AppColors.ink,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_currentAtmosphere.title} · ${_currentAtmosphere.tagline}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BouncingWidget(
                              scaleFactor: 0.94,
                              onTap: () {
                                HapticService.selection();
                                setState(() {
                                  _atmosphereActive = !_atmosphereActive;
                                  _refreshPlaces();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _atmosphereActive ? AppColors.ink : AppColors.paper2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _atmosphereActive ? 'Filtered' : 'Filter',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _atmosphereActive ? Colors.white : AppColors.ink2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: CategoryChips(
                        selectedCategory: _selectedCategory,
                        atmosphereLabel: _currentAtmosphere.title,
                        isAtmosphereActive: _atmosphereActive,
                        onToggleAtmosphere: () {
                          HapticService.selection();
                          setState(() {
                            _atmosphereActive = !_atmosphereActive;
                            _refreshPlaces();
                          });
                        },
                        onSelected: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                            _atmosphereActive = false;
                            _refreshPlaces();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _viewMode == 0
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  if (densities.isNotEmpty) ...[
                                    DistrictDensityOverlay(
                                      districts: densities,
                                      selectedDistrict: _selectedDistrict,
                                      onDistrictTap: (district) {
                                        setState(() {
                                          _selectedDistrict = district.district;
                                          _mapTargetLocation = LatLng(district.centroidLat, district.centroidLng);
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  Expanded(
                                    child: CityMapWidget(
                                      places: places,
                                      selectedPlaceId: _selectedPlaceId,
                                      districtDensities: densities,
                                      targetLocation: _mapTargetLocation,
                                      onSelectPlace: (id) => setState(() => _selectedPlaceId = id),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (selectedPlace != null)
                                    BouncingWidget(
                                      scaleFactor: 0.985,
                                      onTap: () => context.push('/places/${selectedPlace.id}'),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                                          boxShadow: const [AppColors.shadowCard],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 72,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: AppImage(
                                                path: selectedPlace.heroImageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          selectedPlace.name,
                                                          style: GoogleFonts.bricolageGrotesque(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w800,
                                                            letterSpacing: -0.2,
                                                            color: AppColors.ink,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.paper2,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          selectedPlace.priceTier,
                                                          style: GoogleFonts.spaceMono(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.ink2,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${selectedPlace.category} · ${selectedPlace.walkDistanceLabel}',
                                                    style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.star_rounded, size: 14, color: AppColors.orange),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${selectedPlace.ratingAvg}',
                                                        style: GoogleFonts.instrumentSans(fontSize: 11.5, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '(${selectedPlace.ratingCount})',
                                                        style: GoogleFonts.spaceMono(fontSize: 9.5, color: AppColors.ink3),
                                                      ),
                                                      const Spacer(),
                                                      BookmarkButton(
                                                        isSaved: savedPlaces.contains(selectedPlace.id),
                                                        size: 34,
                                                        onToggle: () {
                                                          ref.read(savedPlacesProvider.notifier).toggleSave(selectedPlace.id);
                                                        },
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
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: places.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final place = places[index];
                                return VenueRowWidget(
                                  place: place,
                                  onTap: () => context.push('/places/${place.id}'),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 70),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildRecommendationsView(
    List<RecommendedPlaceResult> recs,
    List<String> savedPlaces,
    List<CollectionModel> collections,
    PlacesRepository placesRepo,
  ) {
    if (recs.isEmpty && collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.butterSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 28, color: AppColors.orange),
              ),
              const SizedBox(height: 14),
              Text(
                'No recommendations yet',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect with friends or save places in Tashkent to unlock explainable, privacy-preserving recommendations.',
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(fontSize: 12.5, color: AppColors.ink2, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (collections.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                'Curated Tastemaker Guides',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${collections.length} Guides',
                  style: GoogleFonts.spaceMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.ink2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Shortlists curated by Tashkent locals, creators & friends',
            style: GoogleFonts.instrumentSans(fontSize: 11.5, color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: collections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final col = collections[index];
                return BouncingWidget(
                  scaleFactor: 0.96,
                  onTap: () {
                    HapticService.selection();
                    _showCollectionBottomSheet(context, col, placesRepo);
                  },
                  child: Container(
                    width: 230,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.orangeSubtle,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                col.audience.toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 13, color: AppColors.ink3),
                                const SizedBox(width: 2),
                                Text(
                                  '${col.placeIds.length}',
                                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink2),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          col.title,
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: -0.2,
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            col.description,
                            style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink3, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.orange),
            const SizedBox(width: 8),
            Text(
              'Personalized Venues',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recs.map((item) {
          final place = item.place;
          final isSaved = savedPlaces.contains(place.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BouncingWidget(
              scaleFactor: 0.985,
              onTap: () {
                HapticService.light();
                context.push('/places/${place.id}');
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  boxShadow: const [AppColors.shadowCard],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      place.name,
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.paper2,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(place.priceTier, style: GoogleFonts.spaceMono(fontSize: 9.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${place.category} · ${place.district}',
                                style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.orange),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${place.ratingAvg}',
                                    style: GoogleFonts.instrumentSans(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.directions_walk_rounded, size: 13, color: AppColors.ink3),
                                  const SizedBox(width: 2),
                                  Text(
                                    place.walkDistanceLabel,
                                    style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink3),
                                  ),
                                  const Spacer(),
                                  BookmarkButton(
                                    isSaved: isSaved,
                                    size: 34,
                                    onToggle: () {
                                      ref.read(savedPlacesProvider.notifier).toggleSave(place.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.butterSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.butter, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.explanation,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  void _showCollectionBottomSheet(
    BuildContext context,
    CollectionModel collection,
    PlacesRepository placesRepo,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final places = collection.placeIds
            .map((id) => placesRepo.getPlaceById(id))
            .whereType<PlaceModel>()
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.88,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: ListView(
                controller: scrollController,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          collection.audience.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    collection.title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  if (collection.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      collection.description,
                      style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink2, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Places in this guide (${places.length})',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (places.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No places loaded for this collection.',
                          style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink3),
                        ),
                      ),
                    )
                  else
                    ...places.map((place) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: VenueRowWidget(
                            place: place,
                            onTap: () {
                              Navigator.of(ctx).pop();
                              context.push('/places/${place.id}');
                            },
                          ),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingWidget(
      scaleFactor: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected ? Border.all(color: AppColors.borderSubtle, width: 1.0) : null,
          boxShadow: isSelected ? const [AppColors.shadowSubtle] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.orange : AppColors.ink3,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

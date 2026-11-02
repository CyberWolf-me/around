import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/collections_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../widgets/category_chips.dart';
import '../widgets/city_map_widget.dart';
import '../widgets/venue_row_widget.dart';

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
  late Future<List<PlaceModel>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _refreshPlaces();
  }

  void _refreshPlaces() {
    _placesFuture = ref.read(placesRepositoryProvider).getNearbyPlaces(
          category: _selectedCategory,
          searchQuery: _searchQuery,
        );
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

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewMode == 2 ? 'Personalized Discovery' : 'Public Discovery',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
            ),
            Text(
              _viewMode == 2 ? 'Recommended for You' : 'Tashkent Community',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Row(
              children: [
                _ViewToggleButton(
                  icon: Icons.map,
                  label: 'Map',
                  isSelected: _viewMode == 0,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _viewMode = 0);
                  },
                ),
                _ViewToggleButton(
                  icon: Icons.view_list,
                  label: 'List',
                  isSelected: _viewMode == 1,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _viewMode = 1);
                  },
                ),
                _ViewToggleButton(
                  icon: Icons.auto_awesome,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.ink, width: 1.8),
                          boxShadow: const [AppColors.shadowSm],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18, color: AppColors.ink3),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                    _refreshPlaces();
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search cafés, plov, study spots...',
                                  hintStyle: TextStyle(fontSize: 12, color: AppColors.ink3),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13, color: AppColors.ink),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _refreshPlaces();
                                  });
                                },
                                child: const Icon(Icons.close, size: 16, color: AppColors.ink3),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: CategoryChips(
                        selectedCategory: _selectedCategory,
                        onSelected: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                            _refreshPlaces();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _viewMode == 0
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: CityMapWidget(
                                      places: places,
                                      selectedPlaceId: _selectedPlaceId,
                                      onSelectPlace: (id) => setState(() => _selectedPlaceId = id),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (selectedPlace != null)
                                    GestureDetector(
                                      onTap: () => context.push('/places/${selectedPlace.id}'),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.paper,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.ink, width: 2),
                                          boxShadow: const [AppColors.shadow],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 72,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.ink, width: 1.5),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: AppImage(
                                                path: selectedPlace.heroImageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          selectedPlace.name,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        selectedPlace.priceTier,
                                                        style: Theme.of(context).textTheme.labelSmall,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${selectedPlace.category} · ${selectedPlace.walkDistanceLabel}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.star, size: 12, color: AppColors.orange),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${selectedPlace.ratingAvg}',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '(${selectedPlace.ratingCount})',
                                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                                                      ),
                                                      const Spacer(),
                                                      IconButton(
                                                        icon: Icon(
                                                          savedPlaces.contains(selectedPlace.id)
                                                              ? Icons.bookmark
                                                              : Icons.bookmark_border,
                                                          size: 18,
                                                          color: savedPlaces.contains(selectedPlace.id)
                                                              ? AppColors.orange
                                                              : AppColors.ink3,
                                                        ),
                                                        onPressed: () {
                                                          HapticService.medium();
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              itemCount: places.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final place = places[index];
                                return VenueRowWidget(
                                  place: place,
                                  onTap: () => context.push('/places/${place.id}'),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 60),
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
                  color: AppColors.paper2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 28, color: AppColors.orange),
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
              const Text(
                'Connect with friends or save places in Tashkent to unlock explainable, privacy-preserving recommendations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.ink2),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        if (collections.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.auto_stories, size: 16, color: AppColors.orange),
              const SizedBox(width: 6),
              Text(
                'Curated Tastemaker Guides',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${collections.length} Guides',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Shortlists curated by Tashkent locals, creators & friends',
            style: TextStyle(fontSize: 11, color: AppColors.ink3),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 135,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: collections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final col = collections[index];
                return GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    _showCollectionBottomSheet(context, col, placesRepo);
                  },
                  child: Container(
                    width: 220,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                col.audience.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 12, color: AppColors.ink3),
                                const SizedBox(width: 2),
                                Text(
                                  '${col.placeIds.length}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink2),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          col.title,
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            col.description,
                            style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
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
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              'Personalized Venues',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...recs.map((item) {
          final place = item.place;
          final isSaved = savedPlaces.contains(place.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                context.push('/places/${place.id}');
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [AppColors.shadowSm],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.ink, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
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
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(place.priceTier, style: Theme.of(context).textTheme.labelSmall),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${place.category} · ${place.district}',
                                style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 13, color: AppColors.orange),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${place.ratingAvg}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.directions_walk, size: 13, color: AppColors.ink3),
                                  const SizedBox(width: 2),
                                  Text(
                                    place.walkDistanceLabel,
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                                      size: 19,
                                      color: isSaved ? AppColors.orange : AppColors.ink3,
                                    ),
                                    onPressed: () {
                                      HapticService.medium();
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
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.butter.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: AppColors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.explanation,
                              style: const TextStyle(
                                fontSize: 11,
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
        const SizedBox(height: 40),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final places = collection.placeIds
            .map((id) => placesRepo.getPlaceById(id))
            .whereType<PlaceModel>()
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.ink3.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          collection.audience.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    collection.title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (collection.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      collection.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Places in this guide (${places.length})',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (places.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No places loaded for this collection.',
                          style: TextStyle(fontSize: 12, color: AppColors.ink3),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.ink, width: 1.2) : null,
          boxShadow: isSelected ? const [AppColors.shadowSm] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.ink : AppColors.ink3,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

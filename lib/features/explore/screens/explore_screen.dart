import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/places_repository.dart';
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
  bool _isMapView = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedPlaceId = 'kettle';

  @override
  Widget build(BuildContext context) {
    final placesRepo = ref.watch(placesRepositoryProvider);
    final savedPlaces = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Public Discovery',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
            ),
            const Text(
              'Tashkent Community',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'BricolageGrotesque',
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          // Segmented mode toggle (Map vs List)
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
                  isSelected: _isMapView,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _isMapView = true);
                  },
                ),
                _ViewToggleButton(
                  icon: Icons.view_list,
                  label: 'List',
                  isSelected: !_isMapView,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _isMapView = false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<PlaceModel>>(
        future: placesRepo.getNearbyPlaces(
          category: _selectedCategory,
          searchQuery: _searchQuery,
        ),
        builder: (context, snapshot) {
          final places = snapshot.data ?? [];
          final selectedPlace = placesRepo.getPlaceById(_selectedPlaceId) ?? (places.isNotEmpty ? places.first : null);

          return Column(
            children: [
              // Search input
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
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search cafés, ramen, study spots...',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.ink3),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13, color: AppColors.ink),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: const Icon(Icons.close, size: 16, color: AppColors.ink3),
                        ),
                    ],
                  ),
                ),
              ),

              // Category chips
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: CategoryChips(
                  selectedCategory: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),

              // Content based on View Mode
              Expanded(
                child: _isMapView
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
                            // Active Place Preview Card
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
                                        child: Image.asset(
                                          selectedPlace.heroImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(color: AppColors.paper2),
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
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.ink,
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
              const SizedBox(height: 60), // tab bar clearance
            ],
          );
        },
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.paper : AppColors.ink,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.paper : AppColors.ink,
                fontFamily: 'SpaceMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

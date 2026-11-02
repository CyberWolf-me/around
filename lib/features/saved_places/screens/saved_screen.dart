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
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _activeFilter = 'All';

  void _showAddPlanDialog(List<PlaceModel> allPlaces) {
    String selectedPlaceId = allPlaces.isNotEmpty ? allPlaces.first.id : 'breadly';
    final timeCtrl = TextEditingController(text: 'Sun 11:00 AM');
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          title: Text('New Plan with Friends', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlaceId,
                items: allPlaces
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlaceId = val);
                },
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'When', hintText: 'e.g. Sat 4:00 PM'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note', hintText: 'e.g. Coffee & study session'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
            ),
            ElevatedButton(
              onPressed: () async {
                final place = ref.read(placesRepositoryProvider).getPlaceById(selectedPlaceId);
                final myInitials = ref.read(currentProfileProvider).initials;
                await ref.read(friendPlansProvider.notifier).addPlan(
                      placeId: selectedPlaceId,
                      placeName: place?.name ?? 'Tashkent Venue',
                      scheduleTime: timeCtrl.text.trim().isEmpty ? 'Sat 11:00 AM' : timeCtrl.text.trim(),
                      attendeeInitials: [myInitials],
                      note: noteCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.ink),
              child: const Text('Create Plan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCollectionDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedAudience = 'friends';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          title: Text('New Custom Collection', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Collection Title', hintText: 'e.g. Tashkent Matcha Spots'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Best ceremonial matcha in town'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedAudience,
                items: const [
                  DropdownMenuItem(value: 'friends', child: Text('Friends Only')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'private', child: Text('Private (Only Me)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedAudience = val);
                },
                decoration: const InputDecoration(labelText: 'Audience'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(collectionsRepositoryProvider.notifier).createCollection(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      audience: selectedAudience,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlaceToCollectionDialog(CollectionModel collection, List<PlaceModel> allSavedVenues) {
    final available = allSavedVenues.where((p) => !collection.placeIds.contains(p.id)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your saved places are already in this collection.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('Add to "${collection.title}"', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final place = available[idx];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(width: 36, height: 36, child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover)),
                ),
                title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(place.district, style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.orange),
                onTap: () {
                  HapticService.selection();
                  ref.read(collectionsRepositoryProvider.notifier).addPlaceToCollection(collection.id, place.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${place.name} to ${collection.title}')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildCollectionsView(
    List<CollectionModel> collections,
    PlacesRepository placesRepo,
    List<PlaceModel> allSavedVenues,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Collections',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const Text(
                  'Themed shortlists & collaborative guides',
                  style: TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('New List', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (collections.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.collections_bookmark_outlined, size: 36, color: AppColors.ink3),
                const SizedBox(height: 12),
                const Text(
                  'No collections created yet.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Organize your favorite Tashkent spots into custom lists.',
                  style: TextStyle(fontSize: 12, color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateCollectionDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.ink),
                  child: const Text('Create Collection'),
                ),
              ],
            ),
          )
        else
          ...collections.map((col) {
            final places = col.placeIds
                .map((id) => placesRepo.getPlaceById(id))
                .whereType<PlaceModel>()
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: col.audience == 'public'
                              ? AppColors.ink
                              : (col.audience == 'friends' ? AppColors.orange : AppColors.paper2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          col.audience.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: col.audience == 'private' ? AppColors.ink : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (col.isCollaborative)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.ink, width: 1),
                          ),
                          child: const Text(
                            'COLLABORATIVE',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.ink3),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: const EdgeInsets.all(10),
                        tooltip: 'Delete Collection',
                        onPressed: () {
                          HapticService.medium();
                          ref.read(collectionsRepositoryProvider.notifier).deleteCollection(col.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    col.title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (col.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      col.description,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (places.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No places added yet.',
                        style: TextStyle(fontSize: 11, color: AppColors.ink3, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ...places.map((place) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.paper2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push('/places/${place.id}'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${place.category} · ${place.district}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.ink2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.ink2),
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  padding: const EdgeInsets.all(12),
                                  tooltip: 'Remove from Collection',
                                  onPressed: () {
                                    HapticService.selection();
                                    ref.read(collectionsRepositoryProvider.notifier).removePlaceFromCollection(col.id, place.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showAddPlaceToCollectionDialog(col, allSavedVenues),
                      icon: const Icon(Icons.add, size: 13, color: AppColors.ink),
                      label: const Text('+ Add Saved Place', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 60),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedPlaces = ref.watch(savedPlacesProvider);
    final statuses = ref.watch(savedPlaceStatusesProvider);
    final statusNotifier = ref.read(savedPlaceStatusesProvider.notifier);
    final placesRepo = ref.watch(placesRepositoryProvider);
    final friendPlans = ref.watch(friendPlansProvider);
    final collections = ref.watch(collectionsRepositoryProvider);

    final List<PlaceModel> allSavedVenues = savedPlaces
        .map((id) => placesRepo.getPlaceById(id))
        .whereType<PlaceModel>()
        .toList();

    final List<PlaceModel> filteredSavedVenues = allSavedVenues.where((place) {
      if (_activeFilter == 'All') return true;
      final status = statuses[place.id] ?? 'want_to_go';
      if (_activeFilter == 'Want to go') return status == 'want_to_go';
      if (_activeFilter == 'Been') return status == 'been';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your shortlist', style: Theme.of(context).textTheme.labelSmall),
            Row(
              children: [
                Text(
                  'Saved',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _activeFilter == 'Collections'
                      ? '${collections.length} lists'
                      : '${filteredSavedVenues.length} places',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: OutlinedButton.icon(
              onPressed: () => _showAddPlanDialog(placesRepo.getAllPlaces()),
              icon: const Icon(Icons.add, size: 14, color: AppColors.ink),
              label: const Text('Plan', style: TextStyle(color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.ink, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          Row(
            children: ['All', 'Want to go', 'Been', 'Collections'].map((filter) {
              final isSel = _activeFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      setState(() => _activeFilter = filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.ink : AppColors.paper2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ink, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isSel ? AppColors.paper : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (_activeFilter == 'Collections')
            _buildCollectionsView(collections, placesRepo, allSavedVenues)
          else ...[
          if (friendPlans.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [AppColors.shadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Text(
                        '${friendPlans.length} plans with friends in Tashkent',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...friendPlans.map((plan) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/places/${plan.placeId}'),
                                child: Row(
                                  children: [
                                    Row(
                                      children: plan.attendeeInitials
                                          .map(
                                            (init) => Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: CircleAvatar(
                                                radius: 9,
                                                backgroundColor: AppColors.ink,
                                                child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 7)),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        plan.placeName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.ink,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        plan.scheduleTime,
                                        style: const TextStyle(color: Colors.white, fontSize: 9.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (plan.note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plan.note,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.ink2),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticService.selection();
                                      ref.read(friendPlansProvider.notifier).rsvpToPlan(plan.id, 'going');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: plan.myRsvp == 'going' ? AppColors.mint : AppColors.paper2,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: plan.myRsvp == 'going' ? AppColors.ink : AppColors.ink.withValues(alpha: 0.2),
                                          width: plan.myRsvp == 'going' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            plan.myRsvp == 'going' ? Icons.check_circle : Icons.check,
                                            size: 11,
                                            color: AppColors.ink,
                                          ),
                                          const SizedBox(width: 3),
                                          const Text(
                                            'Going',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      HapticService.selection();
                                      ref.read(friendPlansProvider.notifier).rsvpToPlan(plan.id, 'declined');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: plan.myRsvp == 'declined' ? AppColors.danger.withValues(alpha: 0.2) : AppColors.paper2,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: plan.myRsvp == 'declined' ? AppColors.danger : AppColors.ink.withValues(alpha: 0.2),
                                          width: plan.myRsvp == 'declined' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.close,
                                            size: 11,
                                            color: plan.myRsvp == 'declined' ? AppColors.danger : AppColors.ink3,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Decline',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: plan.myRsvp == 'declined' ? AppColors.danger : AppColors.ink3,
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
                      )),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Curated Collections',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: _showCreateCollectionDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 12, color: AppColors.ink),
                      SizedBox(width: 2),
                      Text('New', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: collections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final col = collections[idx];
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: const [AppColors.shadowSm],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: col.audience == 'public' ? AppColors.ink : AppColors.butter,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              col.audience,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: col.audience == 'public' ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        col.description,
                        style: const TextStyle(fontSize: 10, color: AppColors.ink2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '${col.placeIds.length} spots',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.orange),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 4,
                            children: col.placeIds.take(2).map((pid) {
                              final p = placesRepo.getPlaceById(pid);
                              return GestureDetector(
                                onTap: () => context.push('/places/$pid'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper2,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    p?.name.split(' ').first ?? pid,
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (filteredSavedVenues.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('No places in "$_activeFilter".'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/explore'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                    child: const Text('Discover Venues', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            ...filteredSavedVenues.map((PlaceModel place) {
              final currentStatus = statuses[place.id] ?? 'want_to_go';
              final isBeen = currentStatus == 'been';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/places/${place.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.ink, width: 1.8),
                            boxShadow: const [AppColors.shadowSm],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Text(
                                      '${place.category} · ${place.walkDistanceLabel}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 10, color: AppColors.orange),
                                        const SizedBox(width: 2),
                                        Text('${place.ratingAvg}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            HapticService.selection();
                                            statusNotifier.setStatus(place.id, isBeen ? 'want_to_go' : 'been');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isBeen ? AppColors.mint : AppColors.butter,
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: AppColors.ink, width: 1),
                                            ),
                                            child: Text(
                                              isBeen ? '✓ Been' : 'Want to go',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.ink),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.bookmark, color: AppColors.orange),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      tooltip: 'Remove from Saved',
                      onPressed: () {
                        HapticService.medium();
                        ref.read(savedPlacesProvider.notifier).remove(place.id);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}

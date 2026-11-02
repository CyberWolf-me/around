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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
          ),
          title: Text(
            'New Plan with Friends',
            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlaceId,
                items: allPlaces
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: GoogleFonts.instrumentSans(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlaceId = val);
                },
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'When', hintText: 'e.g. Sat 4:00 PM'),
              ),
              const SizedBox(height: 10),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
          ),
          title: Text(
            'New Custom Collection',
            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Collection Title', hintText: 'e.g. Tashkent Matcha Spots'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Best ceremonial matcha in town'),
              ),
              const SizedBox(height: 10),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        title: Text(
          'Add to "${collection.title}"',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2),
        ),
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
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 40, height: 40, child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover)),
                ),
                title: Text(place.name, style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(place.district, style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink2)),
                trailing: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.orange),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Themed shortlists & collaborative guides',
                  style: GoogleFonts.instrumentSans(fontSize: 11.5, color: AppColors.ink3),
                ),
              ],
            ),
            BouncingWidget(
              onTap: _showCreateCollectionDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [AppColors.shadowSubtle],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'New List',
                      style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (collections.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(Icons.collections_bookmark_outlined, size: 40, color: AppColors.ink3),
                const SizedBox(height: 12),
                Text(
                  'No collections created yet.',
                  style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organize your favorite Tashkent spots into custom lists.',
                  style: GoogleFonts.instrumentSans(fontSize: 12.5, color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateCollectionDialog,
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
              padding: const EdgeInsets.all(16),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: col.audience == 'public'
                              ? AppColors.ink
                              : (col.audience == 'friends' ? AppColors.orangeSubtle : AppColors.paper2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          col.audience.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: col.audience == 'public'
                                ? Colors.white
                                : (col.audience == 'friends' ? AppColors.orange : AppColors.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (col.isCollaborative)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.mintSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.mint),
                          ),
                          child: Text(
                            'COLLABORATIVE',
                            style: GoogleFonts.spaceMono(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.ink3),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                        tooltip: 'Delete Collection',
                        onPressed: () {
                          HapticService.medium();
                          ref.read(collectionsRepositoryProvider.notifier).deleteCollection(col.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    col.title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.ink,
                    ),
                  ),
                  if (col.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      col.description,
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (places.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No places added yet.',
                        style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink3, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ...places.map((place) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWarm,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderHairline),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: BouncingWidget(
                                    scaleFactor: 0.98,
                                    onTap: () => context.push('/places/${place.id}'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${place.category} · ${place.district}',
                                          style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.ink3),
                                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  padding: EdgeInsets.zero,
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
                      icon: const Icon(Icons.add_rounded, size: 15, color: AppColors.orange),
                      label: Text(
                        'Add Saved Place',
                        style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange),
                      ),
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
            Text('Your shortlist', style: GoogleFonts.spaceMono(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.ink3)),
            Row(
              children: [
                Text(
                  'Saved',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _activeFilter == 'Collections'
                        ? '${collections.length} lists'
                        : '${filteredSavedVenues.length} places',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BouncingWidget(
              onTap: () => _showAddPlanDialog(placesRepo.getAllPlaces()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text(
                      'Plan',
                      style: GoogleFonts.instrumentSans(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Row(
            children: ['All', 'Want to go', 'Been', 'Collections'].map((filter) {
              final isSel = _activeFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: BouncingWidget(
                    scaleFactor: 0.94,
                    onTap: () {
                      setState(() => _activeFilter = filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.ink : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? AppColors.ink : AppColors.borderSubtle, width: 1.0),
                        boxShadow: isSel ? const [AppColors.shadowSubtle] : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : AppColors.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_activeFilter == 'Collections')
            _buildCollectionsView(collections, placesRepo, allSavedVenues)
          else ...[
            if (friendPlans.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mintSubtle,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.mint, width: 1.0),
                  boxShadow: const [AppColors.shadowSubtle],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group_rounded, size: 16, color: AppColors.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${friendPlans.length} plans with friends in Tashkent',
                            style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...friendPlans.map((plan) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderHairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BouncingWidget(
                                  scaleFactor: 0.98,
                                  onTap: () => context.push('/places/${plan.placeId}'),
                                  child: Row(
                                    children: [
                                      Row(
                                        children: plan.attendeeInitials
                                            .map(
                                              (init) => Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: CircleAvatar(
                                                  radius: 10,
                                                  backgroundColor: AppColors.ink,
                                                  child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          plan.placeName,
                                          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.paper2,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          plan.scheduleTime,
                                          style: GoogleFonts.spaceMono(color: AppColors.ink, fontSize: 9.5, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (plan.note.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    plan.note,
                                    style: GoogleFonts.instrumentSans(fontSize: 11.5, color: AppColors.ink2),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    BouncingWidget(
                                      scaleFactor: 0.92,
                                      onTap: () {
                                        ref.read(friendPlansProvider.notifier).rsvpToPlan(plan.id, 'going');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: plan.myRsvp == 'going' ? AppColors.mint : AppColors.paper2,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: plan.myRsvp == 'going' ? AppColors.ink : AppColors.borderHairline,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              plan.myRsvp == 'going' ? Icons.check_circle_rounded : Icons.check_rounded,
                                              size: 13,
                                              color: AppColors.ink,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Going',
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
                                        ref.read(friendPlansProvider.notifier).rsvpToPlan(plan.id, 'declined');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: plan.myRsvp == 'declined' ? AppColors.danger.withValues(alpha: 0.15) : AppColors.paper2,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: plan.myRsvp == 'declined' ? AppColors.danger : AppColors.borderHairline,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.close_rounded,
                                              size: 13,
                                              color: plan.myRsvp == 'declined' ? AppColors.danger : AppColors.ink3,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Decline',
                                              style: GoogleFonts.instrumentSans(
                                                fontSize: 11,
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
            if (filteredSavedVenues.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Text(
                      'No places in "$_activeFilter".',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/explore'),
                      child: const Text('Discover Venues'),
                    ),
                  ],
                ),
              )
            else
              ...filteredSavedVenues.map((PlaceModel place) {
                final currentStatus = statuses[place.id] ?? 'want_to_go';
                final isBeen = currentStatus == 'been';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BouncingWidget(
                    scaleFactor: 0.985,
                    onTap: () => context.push('/places/${place.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                        boxShadow: const [AppColors.shadowCard],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: AppImage(path: place.heroImageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${place.category} · ${place.walkDistanceLabel}',
                                  style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 13, color: AppColors.orange),
                                    const SizedBox(width: 2),
                                    Text('${place.ratingAvg}', style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    BouncingWidget(
                                      scaleFactor: 0.92,
                                      onTap: () {
                                        statusNotifier.setStatus(place.id, isBeen ? 'want_to_go' : 'been');
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 160),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isBeen ? AppColors.mintSubtle : AppColors.butterSubtle,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: isBeen ? AppColors.mint : AppColors.butter, width: 1.0),
                                        ),
                                        child: Text(
                                          isBeen ? '✓ Been' : 'Want to go',
                                          style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          BookmarkButton(
                            isSaved: true,
                            size: 34,
                            onToggle: () {
                              ref.read(savedPlacesProvider.notifier).remove(place.id);
                            },
                          ),
                        ],
                      ),
                    ),
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

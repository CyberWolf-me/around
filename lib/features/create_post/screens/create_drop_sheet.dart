import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/haptic_service.dart';

class CreateDropSheet extends ConsumerStatefulWidget {
  final String? presetPlaceId;

  const CreateDropSheet({super.key, this.presetPlaceId});

  @override
  ConsumerState<CreateDropSheet> createState() => _CreateDropSheetState();
}

class _CreateDropSheetState extends ConsumerState<CreateDropSheet> {
  int _currentStep = 0;
  String? _selectedPhoto = 'assets/kettle-hero.jpg';
  late String _selectedPlaceId;
  final TextEditingController _noteController = TextEditingController();
  int _rating = 5;
  final List<String> _selectedTags = ['quiet mornings'];
  PostAudience _audience = PostAudience.friends;
  String _venueSearch = '';

  static const List<String> _curatedPhotos = [
    'assets/kettle-hero.jpg',
    'assets/bakery-counter.jpg',
    'assets/pastries.jpg',
    'assets/study-desk.jpg',
    'assets/wine-tall.jpg',
    'assets/records-crates.jpg',
    'assets/ramen-bowl.jpg',
    'assets/bookshop-tall.jpg',
  ];

  static const List<String> _availableTags = [
    'quiet mornings',
    'good cortado',
    'outlets',
    'date night',
    'late night',
    'cash only',
    'big tables',
    'solo seats',
    'staff picks',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlaceId = widget.presetPlaceId ?? 'kettle';
    if (widget.presetPlaceId != null) {
      _currentStep = 2; // skip to note step if place preselected
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticService.medium();
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitDrop();
    }
  }

  void _prevStep() {
    HapticService.light();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _submitDrop() {
    final placesRepo = ref.read(placesRepositoryProvider);
    final place = placesRepo.getPlaceById(_selectedPlaceId);

    ref.read(postsRepositoryProvider.notifier).publishDrop(
          placeId: _selectedPlaceId,
          placeName: place?.name ?? 'Venue',
          placeCategory: place?.category ?? 'Café',
          placeAddress: place?.streetAddress ?? '',
          note: _noteController.text.trim().isEmpty ? 'Dropped this place.' : _noteController.text.trim(),
          rating: _rating,
          audience: _audience,
          tags: _selectedTags,
          mediaPath: _selectedPhoto,
        );

    HapticService.heavy();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _audience == PostAudience.friends
              ? 'Dropped for your friends only'
              : 'Dropped publicly for Tashkent community',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placesRepo = ref.watch(placesRepositoryProvider);
    final currentPlace = placesRepo.getPlaceById(_selectedPlaceId);

    final stepTitles = ['Select Photo', 'Choose Venue', 'Add Note & Tags', 'Audience & Privacy'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(_currentStep == 0 ? Icons.close : Icons.arrow_back),
                  onPressed: _prevStep,
                ),
                Column(
                  children: [
                    Text(
                      'STEP ${_currentStep + 1} OF 4',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                    Text(
                      stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BricolageGrotesque',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x2515130F)),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(currentPlace),
            ),
          ),

          // Bottom Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x2015130F))),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.ink, width: 1.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back', style: TextStyle(color: AppColors.ink)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.ink, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 3 ? 'Publish Drop' : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep == 3 ? Icons.send : Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(dynamic currentPlace) {
    switch (_currentStep) {
      case 0: // Photo Selection
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [AppColors.shadow],
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedPhoto != null
                  ? Image.asset(_selectedPhoto!, fit: BoxFit.cover)
                  : const Center(child: Text('No photo selected')),
            ),
            const SizedBox(height: 16),
            const Text(
              'OR SELECT CURATED LOCAL VENUE PHOTO:',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppColors.ink3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _curatedPhotos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, i) {
                final photo = _curatedPhotos[i];
                final isChosen = _selectedPhoto == photo;
                return GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _selectedPhoto = photo);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChosen ? AppColors.orange : AppColors.ink,
                        width: isChosen ? 2.5 : 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(photo, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ],
        );

      case 1: // Venue Search & Confirmation
        final placesRepo = ref.watch(placesRepositoryProvider);
        return FutureBuilder(
          future: placesRepo.getNearbyPlaces(searchQuery: _venueSearch),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            return Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _venueSearch = val),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search Tashkent venues...',
                    filled: true,
                    fillColor: AppColors.paper2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    final isSel = _selectedPlaceId == p.id;
                    return GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        setState(() => _selectedPlaceId = p.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.butter : AppColors.paper,
                          border: Border.all(
                            color: isSel ? AppColors.orange : const Color(0x3015130F),
                            width: 1.8,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSel ? const [AppColors.shadowSm] : null,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 38,
                                height: 38,
                                child: Image.asset(p.heroImageUrl, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${p.category} · ${p.streetAddress}',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel) const Icon(Icons.check_circle, color: AppColors.ink, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );

      case 2: // Note, Rating, Tags
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentPlace != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Text(
                      currentPlace.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      currentPlace.shortCategory,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text('Short review note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 180,
              decoration: InputDecoration(
                hintText: 'e.g. Back room is quiet until eleven, cortado is the best here...',
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.ink, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Rating:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Row(
              children: List.generate(5, (index) {
                final starVal = index + 1;
                return IconButton(
                  icon: Icon(
                    starVal <= _rating ? Icons.star : Icons.star_border,
                    color: starVal <= _rating ? AppColors.orange : AppColors.ink3,
                  ),
                  onPressed: () {
                    HapticService.selection();
                    setState(() => _rating = starVal);
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _availableTags.map((t) {
                final isChosen = _selectedTags.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: isChosen,
                  onSelected: (val) {
                    HapticService.selection();
                    setState(() {
                      if (val) {
                        _selectedTags.add(t);
                      } else {
                        _selectedTags.remove(t);
                      }
                    });
                  },
                  selectedColor: AppColors.ink,
                  labelStyle: TextStyle(
                    color: isChosen ? AppColors.paper : AppColors.ink,
                    fontSize: 10.5,
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case 3: // Audience & Privacy (NON-NEGOTIABLE PRIVACY INVARIANT)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who can discover this drop?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink3),
            ),
            const SizedBox(height: 12),
            // Friends Only
            GestureDetector(
              onTap: () {
                HapticService.selection();
                setState(() => _audience = PostAudience.friends);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _audience == PostAudience.friends ? AppColors.butter : AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _audience == PostAudience.friends ? AppColors.ink : const Color(0x3015130F),
                    width: 2,
                  ),
                  boxShadow: _audience == PostAudience.friends ? const [AppColors.shadow] : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.paper,
                      radius: 18,
                      child: Icon(Icons.lock, size: 18, color: AppColors.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Friends Only (Recommended)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Only mutual connections see this. Inaccessible to public search, unauthenticated users, or strangers via API.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Public Discovery
            GestureDetector(
              onTap: () {
                HapticService.selection();
                setState(() => _audience = PostAudience.public);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _audience == PostAudience.public ? AppColors.paper2 : AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _audience == PostAudience.public ? AppColors.ink : const Color(0x3015130F),
                    width: 2,
                  ),
                  boxShadow: _audience == PostAudience.public ? const [AppColors.shadow] : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.paper,
                      radius: 18,
                      child: Icon(Icons.public, size: 18, color: AppColors.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Public Community Discovery',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Discoverable by everyone in Tashkent on Explore and the venue page. Your location history stays private.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

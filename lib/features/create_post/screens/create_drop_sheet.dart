import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/place_model.dart';
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
  String? _selectedPhoto = 'assets/bakery-counter.jpg';
  late String _selectedPlaceId;
  final TextEditingController _noteController = TextEditingController();
  int _rating = 5;
  final List<String> _selectedTags = ['specialty coffee'];
  PostAudience _audience = PostAudience.friends;
  String _venueSearch = '';
  final ImagePicker _picker = ImagePicker();

  static const List<String> _curatedPhotos = [
    'assets/bakery-counter.jpg',
    'assets/study-desk.jpg',
    'assets/patisserie.jpg',
    'assets/cafe-light.jpg',
    'assets/street.jpg',
    'assets/window-girl.jpg',
    'assets/wine-wide.jpg',
    'assets/bookshop.jpg',
  ];

  static const List<String> _availableTags = [
    'specialty coffee',
    'artisan sourdough',
    'power outlets',
    'study-friendly',
    'pistachio eclair',
    'wedding plov',
    'v60 pour-over',
    'lake view',
    'craft cocktails',
    'quiet nooks',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlaceId = widget.presetPlaceId ?? 'breadly';
    if (widget.presetPlaceId != null) {
      _currentStep = 2; // skip to note step if place preselected
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    HapticService.medium();
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _selectedPhoto = file.path;
        });
        HapticService.selection();
      }
    } catch (e) {
      debugPrint('[CreateDropSheet] Photo pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera/gallery: $e')),
        );
      }
    }
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
          placeName: place?.name ?? 'Tashkent Spot',
          placeCategory: place?.category ?? 'Café',
          placeAddress: place?.streetAddress ?? 'Tashkent, Uzbekistan',
          note: _noteController.text.trim().isEmpty ? 'Recommended spot in Tashkent.' : _noteController.text.trim(),
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
              ? '✓ Dropped for your friends only'
              : '✓ Dropped publicly for Tashkent community',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddCustomPlaceDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Café · Brunch');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: const Text('Add New Tashkent Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Venue Name *', hintText: 'e.g. Socials Cafe'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address / Street *', hintText: 'e.g. 15 Navoi St, Yunusabad'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Specialty Coffee'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
              final newPlace = PlaceModel(
                id: newId,
                slug: newId,
                name: nameCtrl.text.trim(),
                category: categoryCtrl.text.trim().isEmpty ? 'Café' : categoryCtrl.text.trim(),
                streetAddress: addressCtrl.text.trim().isEmpty ? 'Tashkent' : addressCtrl.text.trim(),
                district: 'Tashkent',
                city: 'Tashkent',
                latitude: 41.3111,
                longitude: 69.2797,
                heroImageUrl: _selectedPhoto ?? 'assets/bakery-counter.jpg',
                statusLine: 'Added by you',
              );
              await ref.read(placesRepositoryProvider).addCustomPlace(newPlace);
              setState(() {
                _selectedPlaceId = newId;
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            child: const Text('Add Venue'),
          ),
        ],
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
              children: [
                Text(
                  'STEP ${_currentStep + 1} OF 4',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${stepTitles[_currentStep]}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Step Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: List.generate(4, (i) {
                final isDone = i <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.orange : const Color(0x3015130F),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildStepContent(currentPlace),
            ),
          ),

          // Footer Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x2015130F), width: 1.5)),
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
      case 0: // Photo Selection with Live Camera & Gallery Pickers
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Preview of selected photo
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [AppColors.shadow],
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedPhoto != null
                  ? AppImage(path: _selectedPhoto!, fit: BoxFit.cover)
                  : const Center(child: Text('No photo selected')),
            ),
            const SizedBox(height: 14),

            // Live Camera & Gallery Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18, color: AppColors.ink),
                    label: const Text('From Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.ink, width: 1.8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'OR SELECT CURATED TASHKENT PHOTO:',
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
                    child: AppImage(path: photo, fit: BoxFit.cover),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _venueSearch = val),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: 'Search Tashkent spots...',
                          filled: true,
                          fillColor: AppColors.paper2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_location_alt, color: AppColors.orange),
                      tooltip: 'Add Custom Venue',
                      onPressed: _showAddCustomPlaceDialog,
                    ),
                  ],
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
                                width: 42,
                                height: 42,
                                child: AppImage(path: p.heroImageUrl, fit: BoxFit.cover),
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
                                    '${p.district} · ${p.streetAddress}',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                    Expanded(
                      child: Text(
                        currentPlace.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currentPlace.district,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text('Your experience or recommendation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 240,
              decoration: InputDecoration(
                hintText: 'e.g. Lavender matcha is unreal. Courtyard gets sun until noon, perfect for reading.',
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
                  label: Text('#$t'),
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
                            'Only mutual connections see this. Inaccessible to public search, unauthenticated users, or strangers.',
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
                  color: _audience == PostAudience.public ? AppColors.butter : AppColors.paper,
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
                            'Public (Tashkent Community)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Featured on the venue page and Tashkent Explore feed. Helps anyone discovering this neighborhood.',
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

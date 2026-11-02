import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/outbox_service.dart';

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
  late PostAudience _audience;
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
    _selectedPlaceId = PlacesRepository.resolveCanonicalId(widget.presetPlaceId ?? 'breadly');
    final defaultAud = ref.read(currentProfileProvider).defaultAudience;
    _audience = defaultAud == 'public' ? PostAudience.public : PostAudience.friends;
    if (widget.presetPlaceId != null) {
      _currentStep = 2;
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 78,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final err = AppLogger.validateImagePath(file.path, byteLength: bytes.length);
        if (err != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err.message)),
            );
          }
          return;
        }
        // Persist as a base64 data URI so OS temporary cache purges never break local drops
        final persistentDataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedPhoto = persistentDataUri;
        });
        HapticService.selection();
      }
    } catch (e) {
      AppLogger.error('CreateDropSheet', 'Photo pick error', e);
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

  Future<void> _submitDrop() async {
    final placesRepo = ref.read(placesRepositoryProvider);
    final place = placesRepo.getPlaceById(_selectedPlaceId);
    final effectiveNote = _noteController.text.trim().isEmpty
        ? 'Recommended spot in ${place?.district ?? 'Tashkent'}.'
        : _noteController.text.trim();

    final failure = await ref.read(postsRepositoryProvider.notifier).publishDrop(
          placeId: _selectedPlaceId,
          placeName: place?.name ?? 'Tashkent Spot',
          placeCategory: place?.category ?? 'Café',
          placeAddress: place?.streetAddress ?? 'Tashkent, Uzbekistan',
          note: effectiveNote,
          rating: _rating,
          audience: _audience,
          tags: _selectedTags,
          mediaPath: _selectedPhoto,
        );

    if (failure != null) {
      final msg = failure.message.toLowerCase();
      if (failure.code == 'NETWORK_ERROR' || msg.contains('network') || msg.contains('offline') || msg.contains('failed host lookup') || msg.contains('client is offline')) {
        await OutboxService.queueDrop(
          PendingDrop(
            id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
            placeId: _selectedPlaceId,
            placeName: place?.name ?? 'Tashkent Spot',
            placeCategory: place?.category ?? 'Café',
            placeAddress: place?.streetAddress ?? 'Tashkent, Uzbekistan',
            localPhotoPath: _selectedPhoto,
            note: effectiveNote,
            rating: _rating,
            tags: _selectedTags,
            audience: _audience.name,
            createdAt: DateTime.now(),
          ),
        );
        ref.read(outboxCountProvider.notifier).refresh();
        HapticService.heavy();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Saved to offline outbox. Will sync automatically when connected.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }
      return;
    }

    HapticService.heavy();
    if (mounted) {
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
  }

  void _showAddCustomPlaceDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final districtCtrl = TextEditingController(text: 'Mirabad');
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
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Venue Name *', hintText: 'e.g. Socials Cafe'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Address / Street *', hintText: 'e.g. 15 Taras Shevchenko St'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: districtCtrl,
                decoration: const InputDecoration(labelText: 'District', hintText: 'e.g. Mirabad, Yakkasaray'),
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
                district: districtCtrl.text.trim().isEmpty ? 'Mirabad' : districtCtrl.text.trim(),
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
    final PlaceModel? currentPlace = placesRepo.getPlaceById(_selectedPlaceId);
    const stepTitles = ['Select Photo', 'Choose Venue', 'Add Note & Tags', 'Audience & Privacy'];

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  'STEP ${_currentStep + 1} OF 4',
                  style: GoogleFonts.spaceMono(
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildStepContent(currentPlace),
            ),
          ),
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

  Widget _buildStepContent(PlaceModel? currentPlace) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'OR SELECT CURATED TASHKENT PHOTO:',
              style: GoogleFonts.spaceMono(
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

      case 1:
        final placesRepo = ref.watch(placesRepositoryProvider);
        return FutureBuilder<List<PlaceModel>>(
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

      case 2:
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

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who can discover this drop?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink3),
            ),
            const SizedBox(height: 12),
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
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.paper,
                      radius: 18,
                      child: Icon(Icons.lock, size: 18, color: AppColors.ink),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.paper,
                      radius: 18,
                      child: Icon(Icons.public, size: 18, color: AppColors.ink),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

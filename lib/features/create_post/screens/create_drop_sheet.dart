import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/exif_sanitizer.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/bouncing_widget.dart';
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
  bool _isNoteOnly = false;
  Color _selectedTint = AppColors.butterSubtle;
  String? _selectedPhoto = 'assets/bakery-counter.jpg';
  late String _selectedPlaceId;
  final TextEditingController _noteController = TextEditingController();
  int _rating = 5;
  final List<String> _selectedTags = ['specialty coffee'];
  late PostAudience _audience;
  String _venueSearch = '';
  final ImagePicker _picker = ImagePicker();

  static const List<Map<String, dynamic>> _tintOptions = [
    {'name': 'Butter', 'color': AppColors.butterSubtle},
    {'name': 'Mint', 'color': AppColors.mintSubtle},
    {'name': 'Water', 'color': AppColors.cobaltSubtle},
    {'name': 'Blush', 'color': AppColors.orangeSubtle},
    {'name': 'Paper', 'color': AppColors.paper2},
  ];

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
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file != null) {
        final rawBytes = await file.readAsBytes();
        final sanitizedBytes = ExifSanitizer.stripExif(rawBytes);
        final err = AppLogger.validateImagePath(file.path, byteLength: sanitizedBytes.length);
        if (err != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err.message)),
            );
          }
          return;
        }
        final persistentDataUri = 'data:image/jpeg;base64,${base64Encode(sanitizedBytes)}';
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
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitDrop();
    }
  }

  void _prevStep() {
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
          mediaPath: _isNoteOnly ? null : _selectedPhoto,
          tint: _isNoteOnly ? _selectedTint : null,
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
            localPhotoPath: _isNoteOnly ? null : _selectedPhoto,
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        title: Text(
          'Add New Tashkent Venue',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2),
        ),
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
    final stepTitles = [
      _isNoteOnly ? 'Format & Color' : 'Select Photo',
      'Choose Venue',
      'Add Note & Tags',
      'Audience & Privacy'
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [AppColors.shadowFloating],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Text(
                  'STEP ${_currentStep + 1} OF 4',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '· ${stepTitles[_currentStep]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink2),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: List.generate(4, (i) {
                final isDone = i <= _currentStep;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.orange : AppColors.paper2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildStepContent(currentPlace),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderHairline, width: 1.0)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: BouncingWidget(
                      scaleFactor: 0.95,
                      onTap: _prevStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Back',
                          style: GoogleFonts.instrumentSans(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: _nextStep,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 3 ? 'Publish Drop' : 'Continue',
                            style: GoogleFonts.instrumentSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentStep == 3 ? Icons.send_rounded : Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
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
            // Format Selector: Photo vs Note Card
            Row(
              children: [
                Expanded(
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: () {
                      setState(() {
                        _isNoteOnly = false;
                        _selectedPhoto ??= 'assets/bakery-counter.jpg';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isNoteOnly ? AppColors.ink : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isNoteOnly ? AppColors.ink : AppColors.borderSubtle,
                          width: 1.0,
                        ),
                        boxShadow: !_isNoteOnly ? const [AppColors.shadowSubtle] : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 16, color: !_isNoteOnly ? Colors.white : AppColors.ink2),
                          const SizedBox(width: 6),
                          Text(
                            'Photo Drop',
                            style: GoogleFonts.instrumentSans(
                              color: !_isNoteOnly ? Colors.white : AppColors.ink2,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: () {
                      setState(() {
                        _isNoteOnly = true;
                        _selectedPhoto = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isNoteOnly ? AppColors.ink : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isNoteOnly ? AppColors.ink : AppColors.borderSubtle,
                          width: 1.0,
                        ),
                        boxShadow: _isNoteOnly ? const [AppColors.shadowSubtle] : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 16, color: _isNoteOnly ? Colors.white : AppColors.ink2),
                          const SizedBox(width: 6),
                          Text(
                            'Note Card',
                            style: GoogleFonts.instrumentSans(
                              color: _isNoteOnly ? Colors.white : AppColors.ink2,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isNoteOnly) ...[
              // Note Card Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _selectedTint,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  boxShadow: const [AppColors.shadowCard],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.ink,
                          child: Text(
                            ref.read(currentProfileProvider).initials,
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ref.read(currentProfileProvider).fullName.split(' ').first,
                          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text('NOTE DROP', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _noteController.text.trim().isEmpty
                          ? '“Your personal recommendation note will appear here with this card color…”'
                          : '“${_noteController.text.trim()}”',
                      style: GoogleFonts.instrumentSans(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '· Venue: ${currentPlace?.name ?? 'Selected Spot'}',
                      style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'PICK CARD PAPER TINT:',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: AppColors.ink3,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _tintOptions.map((opt) {
                  final Color c = opt['color'] as Color;
                  final String name = opt['name'] as String;
                  final isSelected = _selectedTint == c;
                  return BouncingWidget(
                    scaleFactor: 0.9,
                    onTap: () => setState(() => _selectedTint = c),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.orange : AppColors.borderSubtle,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.orange.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected ? const Icon(Icons.check_rounded, size: 20, color: AppColors.ink) : null,
                        ),
                        const SizedBox(height: 6),
                        Text(name, style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink2)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  boxShadow: const [AppColors.shadowCard],
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
                    child: BouncingWidget(
                      scaleFactor: 0.95,
                      onTap: () => _pickPhoto(ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [AppColors.shadowSubtle],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Take Photo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.instrumentSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BouncingWidget(
                      scaleFactor: 0.95,
                      onTap: () => _pickPhoto(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_rounded, size: 18, color: AppColors.ink),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'From Gallery',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.instrumentSans(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'OR SELECT CURATED TASHKENT PHOTO:',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: AppColors.ink3,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
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
                  return BouncingWidget(
                    scaleFactor: 0.92,
                    onTap: () => setState(() => _selectedPhoto = photo),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isChosen ? AppColors.orange : AppColors.borderHairline,
                          width: isChosen ? 2.5 : 1.0,
                        ),
                        boxShadow: isChosen
                            ? [
                                BoxShadow(
                                  color: AppColors.orange.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppImage(path: photo, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ],
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
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 18, color: AppColors.ink3),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) => setState(() => _venueSearch = val),
                                decoration: InputDecoration(
                                  hintText: 'Search Tashkent spots...',
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BouncingWidget(
                      scaleFactor: 0.9,
                      onTap: _showAddCustomPlaceDialog,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.add_location_alt_rounded, color: AppColors.orange, size: 20),
                      ),
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
                    return BouncingWidget(
                      scaleFactor: 0.98,
                      onTap: () => setState(() => _selectedPlaceId = p.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.butterSubtle : AppColors.cardSurface,
                          border: Border.all(
                            color: isSel ? AppColors.orange : AppColors.borderHairline,
                            width: isSel ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSel ? const [AppColors.shadowSubtle] : null,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: AppImage(path: p.heroImageUrl, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2),
                                  ),
                                  Text(
                                    '${p.district} · ${p.streetAddress}',
                                    style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink3),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSel) const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 22),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentPlace.name,
                        style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currentPlace.district,
                      style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Your experience or recommendation:',
              style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 240,
              decoration: InputDecoration(
                hintText: 'e.g. Lavender matcha is unreal. Courtyard gets sun until noon, perfect for reading.',
                filled: true,
                fillColor: AppColors.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
                ),
              ),
              style: GoogleFonts.instrumentSans(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text('Rating:', style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final starVal = index + 1;
                return BouncingWidget(
                  scaleFactor: 0.85,
                  onTap: () => setState(() => _rating = starVal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starVal <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: starVal <= _rating ? AppColors.orange : AppColors.inkLight,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text('Tags:', style: GoogleFonts.instrumentSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((t) {
                final isChosen = _selectedTags.contains(t);
                return BouncingWidget(
                  scaleFactor: 0.94,
                  onTap: () {
                    setState(() {
                      if (isChosen) {
                        _selectedTags.remove(t);
                      } else {
                        _selectedTags.add(t);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isChosen ? AppColors.ink : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isChosen ? AppColors.ink : AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '#$t',
                      style: GoogleFonts.instrumentSans(
                        color: isChosen ? Colors.white : AppColors.ink2,
                        fontSize: 11,
                        fontWeight: isChosen ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
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
            Text(
              'Who can discover this drop?',
              style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink3),
            ),
            const SizedBox(height: 14),
            BouncingWidget(
              scaleFactor: 0.985,
              onTap: () => setState(() => _audience = PostAudience.friends),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _audience == PostAudience.friends ? AppColors.butterSubtle : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _audience == PostAudience.friends ? AppColors.orange : AppColors.borderSubtle,
                    width: _audience == PostAudience.friends ? 1.8 : 1.0,
                  ),
                  boxShadow: _audience == PostAudience.friends ? const [AppColors.shadowSubtle] : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.butter,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 20, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Friends Only (Recommended)',
                            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only mutual connections see this. Inaccessible to public search, unauthenticated users, or strangers.',
                            style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            BouncingWidget(
              scaleFactor: 0.985,
              onTap: () => setState(() => _audience = PostAudience.public),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _audience == PostAudience.public ? AppColors.orangeSubtle : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _audience == PostAudience.public ? AppColors.orange : AppColors.borderSubtle,
                    width: _audience == PostAudience.public ? 1.8 : 1.0,
                  ),
                  boxShadow: _audience == PostAudience.public ? const [AppColors.shadowSubtle] : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.public_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public (Tashkent Community)',
                            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Featured on the venue page and Tashkent Explore feed. Helps anyone discovering this neighborhood.',
                            style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink2, height: 1.4),
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

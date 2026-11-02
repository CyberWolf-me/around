import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String _selectedDistrict = 'Mirabad';
  String _selectedAudience = 'friends'; // 'friends' | 'public'

  static const List<Map<String, String>> _districts = [
    {
      'id': 'Mirabad',
      'name': 'Mirabad District',
      'tagline': 'Specialty coffee, artisan bakeries & evening wine bars',
      'badge': 'Most Active',
    },
    {
      'id': 'Yakkasaray',
      'name': 'Yakkasaray District',
      'tagline': 'Quiet tree-lined streets, local roasters & green promenades',
      'badge': 'Walkable',
    },
    {
      'id': 'Central Tashkent',
      'name': 'Central Tashkent (All)',
      'tagline': 'Curated venues across Mirabad, Yakkasaray & downtown avenues',
      'badge': 'Complete Map',
    },
    {
      'id': 'Yunusabad',
      'name': 'Yunusabad District',
      'tagline': 'Contemporary roasteries, broad avenues & evening gatherings',
      'badge': 'Modern Hub',
    },
    {
      'id': 'Shaykhontohur',
      'name': 'Shaykhontohur (Old City)',
      'tagline': 'Chorsu culinary alleys, traditional tea houses & heritage vibes',
      'badge': 'Historic',
    },
  ];

  static const List<Map<String, String>> _steps = [
    {
      'kicker': 'SOCIAL DISCOVERY · TASHKENT',
      'title': 'Where friends\nactually go.',
      'body':
          'Yandex and 2GIS have thousands of anonymous star ratings. Around is built from authentic places your trusted friends visited, ordered from, and loved.',
    },
    {
      'kicker': 'DUAL-LAYER PRIVACY',
      'title': 'Drop a place.\nChoose your circle.',
      'body':
          'Every drop defaults to Friends Only—no public surveillance. Toggle to Public Discovery only when you want to recommend a hidden gem to all of Tashkent.',
    },
    {
      'kicker': 'COMMUNITY & TASTE',
      'title': 'Where do you\nexplore most?',
      'body':
          'Pick your home neighborhood in Tashkent to anchor your Taste Passport and see what your circle is discovering around you.',
    },
  ];

  Future<void> _finishOnboarding({bool asGuest = false}) async {
    await StorageService.setOnboarded(true);
    await StorageService.setUserNeighborhood(_selectedDistrict);

    AnalyticsService.instance.track(
      AnalyticsEvent.onboardingComplete,
      {
        'neighborhood': _selectedDistrict,
        'as_guest': asGuest,
      },
    );

    if (asGuest) {
      await StorageService.setGuestMode(true);
      if (mounted) {
        context.go('/feed');
      }
    } else {
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_step];

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      children: const [
                        TextSpan(text: 'Around'),
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: AppColors.orange),
                        ),
                      ],
                    ),
                  ),
                  BouncingWidget(
                    onTap: () {
                      HapticService.light();
                      _finishOnboarding(asGuest: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.ink2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Interactive Visual Area by Step
              if (_step == 0) _buildStep0FriendCard(),
              if (_step == 1) _buildStep1PrivacyCard(),
              if (_step == 2) _buildStep2DistrictPicker(),

              const Spacer(),

              // Step Kicker & Title
              Text(
                s['kicker']!,
                style: GoogleFonts.spaceMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s['title']!,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s['body']!,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Navigation & Actions
              if (_step == 2) ...[
                Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        onTap: () {
                          HapticService.light();
                          _finishOnboarding(asGuest: true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1.2,
                            ),
                            boxShadow: const [AppColors.shadowTactile],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Browse as Guest',
                            style: GoogleFonts.instrumentSans(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: BouncingWidget(
                        onTap: () {
                          HapticService.medium();
                          _finishOnboarding(asGuest: false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [AppColors.shadowTactile],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Launch $_selectedDistrict',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.instrumentSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward,
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
              ] else ...[
                Row(
                  children: [
                    Row(
                      children: List.generate(3, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _step ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _step ? AppColors.ink : AppColors.borderHairline,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    BouncingWidget(
                      onTap: () {
                        HapticService.medium();
                        setState(() => _step++);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [AppColors.shadowTactile],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Next',
                              style: GoogleFonts.instrumentSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Step 0: Authentic friend drop card visual
  Widget _buildStep0FriendCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [AppColors.shadowCard],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.butter,
                child: Text(
                  'KR',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamila R.',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Mutual Friend · Mirabad',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butter,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/bakery-counter.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Breadly Bakery & Café',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"The best morning lavender matcha and sourdough in Mirabad. Super quiet courtyard for reading."',
            style: GoogleFonts.instrumentSans(
              fontSize: 12.5,
              color: AppColors.ink2,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Interactive Dual-Layer Privacy Toggle
  Widget _buildStep1PrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [AppColors.shadowCard],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT AUDIENCE FOR YOUR DROP',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.ink3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BouncingWidget(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _selectedAudience = 'friends');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedAudience == 'friends'
                          ? AppColors.ink
                          : AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAudience == 'friends'
                            ? AppColors.ink
                            : AppColors.borderHairline,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: _selectedAudience == 'friends'
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Friends Only',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _selectedAudience == 'friends'
                                  ? Colors.white
                                  : AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
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
                  onTap: () {
                    HapticService.selection();
                    setState(() => _selectedAudience = 'public');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedAudience == 'public'
                          ? AppColors.orange
                          : AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAudience == 'public'
                            ? AppColors.orange
                            : AppColors.borderHairline,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public,
                          size: 14,
                          color: _selectedAudience == 'public'
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Public Discovery',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _selectedAudience == 'public'
                                  ? Colors.white
                                  : AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _selectedAudience == 'friends'
                      ? Icons.verified_user_outlined
                      : Icons.explore_outlined,
                  size: 20,
                  color: _selectedAudience == 'friends'
                      ? AppColors.mint
                      : AppColors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedAudience == 'friends'
                        ? 'Enforced by PostgreSQL Row-Level Security (RLS). Only your mutually accepted friends can ever see this drop.'
                        : 'Visible on Tashkent Explore map and Public Reviews. Helps fellow locals discover hidden gems.',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      color: AppColors.ink2,
                      height: 1.35,
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

  /// Step 2: District Picker with Badge Highlights
  Widget _buildStep2DistrictPicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [AppColors.shadowCard],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _districts.take(3).map((d) {
          final isSelected = _selectedDistrict == d['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BouncingWidget(
              onTap: () {
                HapticService.selection();
                setState(() => _selectedDistrict = d['id']!);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.butter : AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.ink : AppColors.borderHairline,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? const [AppColors.shadowTactile] : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.orange : AppColors.paper2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.ink : AppColors.borderHairline,
                          width: 1.2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.ink2,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  d['name']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.paper.withValues(alpha: 0.6)
                                      : AppColors.paper2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  d['badge']!,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d['tagline']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.ink2,
                              height: 1.25,
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
        }).toList(),
      ),
    );
  }
}

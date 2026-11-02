import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/profiles_repository.dart';
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
  ];

  static const List<Map<String, String>> _steps = [
    {
      'kicker': 'AROUND · TASHKENT',
      'title': 'Where should\nwe go?',
      'body': 'A living map built from places your friends actually went — not ratings written by strangers.',
      'img': 'assets/kettle-hero.jpg',
    },
    {
      'kicker': 'CURATE YOUR CIRCLE',
      'title': 'Follow trusted\nlocals.',
      'body': 'Your feed is only as good as the people on it. Start with friends whose taste you trust for coffee, food, and culture.',
      'img': 'assets/friends.jpg',
    },
    {
      'kicker': 'NEIGHBOURHOOD FIRST',
      'title': 'Pick your\nneighborhood.',
      'body': 'We start with Tashkent so everything you see is walkable. You can expand your radius anytime.',
      'img': 'assets/street.jpg',
    },
  ];

  Future<void> _finishOnboarding({bool asGuest = false}) async {
    await StorageService.setOnboarded(true);
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
    final followedSet = ref.watch(followedFriendsProvider);
    final followedNotifier = ref.read(followedFriendsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        TextSpan(text: '.', style: TextStyle(color: AppColors.orange)),
                      ],
                    ),
                  ),
                  BouncingWidget(
                    onTap: () {
                      HapticService.light();
                      _finishOnboarding(asGuest: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

              // Interactive Visual Area
              if (_step == 1)
                Container(
                  height: 270,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                    boxShadow: const [AppColors.shadowCard],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: kTashkentCommunityMembers.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = kTashkentCommunityMembers[index];
                      final isFollowing = followedSet.contains(member.id);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFollowing ? AppColors.orange.withValues(alpha: 0.3) : AppColors.borderHairline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.butter,
                              child: Text(
                                member.initials,
                                style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                                  ),
                                  Text(
                                    '@${member.handle} · ${member.neighborhood}',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                                  ),
                                ],
                              ),
                            ),
                            BouncingWidget(
                              onTap: () {
                                HapticService.selection();
                                followedNotifier.toggleFollow(member.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isFollowing ? AppColors.paper2 : AppColors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFollowing ? AppColors.borderSubtle : AppColors.orange,
                                  ),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : '+ Follow',
                                  style: TextStyle(
                                    color: isFollowing ? AppColors.ink : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else if (_step == 2)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                    boxShadow: const [AppColors.shadowCard],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _districts.map((d) {
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
                                    border: Border.all(color: isSelected ? AppColors.ink : AppColors.borderHairline, width: 1.2),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : const Icon(Icons.location_on_outlined, size: 15, color: AppColors.ink2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            d['name']!,
                                            style: GoogleFonts.bricolageGrotesque(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.paper.withValues(alpha: 0.6) : AppColors.paper2,
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
                                        style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.25),
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
                )
              else
                Center(
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderSubtle, width: 1),
                      boxShadow: const [AppColors.shadowCard],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(s['img']!, fit: BoxFit.cover),
                  ),
                ),

              const Spacer(),

              // Text Kicker & Content
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

              // Bottom Control Bar
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
                            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
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
                              Text(
                                'Launch $_selectedDistrict',
                                style: GoogleFonts.instrumentSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
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
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
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
                            const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
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
}

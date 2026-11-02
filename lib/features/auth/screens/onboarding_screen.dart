import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
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
      'tagline': 'Specialty coffee, artisan bakeries & evening social spots',
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
      'tagline': 'Explore all curated venues across Mirabad, Yakkasaray & downtown',
      'badge': 'Complete Map',
    },
  ];

  static const List<Map<String, String>> _steps = [
    {
      'kicker': 'Around · Tashkent',
      'title': 'Where should\nwe go?',
      'body': 'A living map built from places your friends actually went — not from ratings written by strangers.',
      'img': 'assets/kettle-hero.jpg',
    },
    {
      'kicker': 'Step 1 of 2',
      'title': 'Follow five\npeople.',
      'body': 'Your feed is only as good as the people on it. Start with the friends you would message for coffee recommendations.',
      'img': 'assets/friends.jpg',
    },
    {
      'kicker': 'Step 2 of 2',
      'title': 'Pick a\nneighbourhood.',
      'body': 'We start with Tashkent (Mirabad & Yakkasaray) so everything you see is walkable. You can widen your discovery radius anytime.',
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      children: const [
                        TextSpan(text: 'Around'),
                        TextSpan(text: '.', style: TextStyle(color: AppColors.orange)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip', style: TextStyle(color: AppColors.ink3)),
                  ),
                ],
              ),
              const Spacer(),
              if (_step == 1)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: kTashkentCommunityMembers.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final member = kTashkentCommunityMembers[index];
                      final isFollowing = followedSet.contains(member.id);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.ink,
                              child: Text(
                                member.initials,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                  Text(
                                    '@${member.handle} · ${member.neighborhood}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticService.selection();
                                followedNotifier.toggleFollow(member.id);
                              },
                              child: Text(
                                isFollowing ? 'Following' : '+ Follow',
                                style: TextStyle(
                                  color: isFollowing ? AppColors.ink : AppColors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
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
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.ink, width: 2),
                    boxShadow: const [AppColors.shadowSm],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _districts.map((d) {
                      final isSelected = _selectedDistrict == d['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticService.selection();
                            setState(() => _selectedDistrict = d['id']!);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.butter : AppColors.paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.ink : AppColors.ink.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1.2,
                              ),
                              boxShadow: isSelected ? const [AppColors.shadowSm] : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.orange : AppColors.paper2,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.ink, width: 1.5),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 15, color: AppColors.ink)
                                      : const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink2),
                                ),
                                const SizedBox(width: 10),
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
                                              fontSize: 13,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.orange.withValues(alpha: 0.2) : AppColors.paper3,
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
                                      const SizedBox(height: 2),
                                      Text(
                                        d['tagline']!,
                                        style: const TextStyle(fontSize: 10.5, color: AppColors.ink2, height: 1.25),
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
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      boxShadow: const [AppColors.shadowLg],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(s['img']!, fit: BoxFit.cover),
                  ),
                ),
              const Spacer(),
              Text(
                s['kicker']!,
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s['title']!,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s['body']!,
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink2, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (_step == 2) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticService.light();
                          _finishOnboarding(asGuest: true);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.ink, width: 1.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Browse as Guest',
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticService.medium();
                          _finishOnboarding(asGuest: false);
                        },
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.ink),
                        label: Text(
                          'Launch $_selectedDistrict',
                          style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.ink, width: 2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        return Container(
                          margin: const EdgeInsets.only(right: 5),
                          width: i == _step ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _step ? AppColors.ink : const Color(0x3015130F),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticService.medium();
                        setState(() => _step++);
                      },
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.ink),
                      label: const Text(
                        'Next',
                        style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.ink, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

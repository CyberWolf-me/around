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

  Future<void> _finishOnboarding() async {
    await StorageService.setOnboarded(true);
    if (mounted) {
      context.go('/auth');
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
              const SizedBox(height: 24),
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
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _finishOnboarding();
                      }
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    label: Text(
                      _step == 2 ? 'Launch Tashkent' : 'Next',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
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
          ),
        ),
      ),
    );
  }
}

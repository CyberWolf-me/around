import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  final steps = const [
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
      'body': 'We start with Tashkent / Barlow Hill so everything you see is walkable. You can widen your discovery radius anytime.',
      'img': 'assets/street.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final s = steps[_step];

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wordmark & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'BricolageGrotesque',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      children: [
                        TextSpan(text: 'Around'),
                        TextSpan(text: '.', style: TextStyle(color: AppColors.orange)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/feed'),
                    child: const Text('Skip', style: TextStyle(color: AppColors.ink3)),
                  ),
                ],
              ),
              const Spacer(),

              // Visual Art Frame
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

              // Text copy
              Text(
                s['kicker']!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                  fontFamily: 'SpaceMono',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s['title']!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BricolageGrotesque',
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s['body']!,
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink2, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Bottom Navigation & Launch
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
                        context.go('/feed');
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

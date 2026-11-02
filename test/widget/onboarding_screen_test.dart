import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:around_app/core/services/analytics_service.dart';
import 'package:around_app/data/services/storage_service.dart';
import 'package:around_app/features/auth/screens/onboarding_screen.dart';

void main() {
  group('OnboardingScreen Redesign Tests (P12-03)', () {
    setUp(() async {
      await StorageService.clearAuthSession();
      await StorageService.setOnboarded(false);
      AnalyticsService.instance.resetForTesting();
    });

    testWidgets('3-step interactive onboarding flow navigation & analytics', (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
          GoRoute(path: '/auth', builder: (_, __) => const Scaffold(body: Text('AUTH_SCREEN'))),
          GoRoute(path: '/feed', builder: (_, __) => const Scaffold(body: Text('FEED_SCREEN'))),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Friends discovery hero
      expect(find.text('Where friends\nactually go.'), findsOneWidget);
      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('Kamila R.'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to advance to Step 1
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 1: Dual-layer privacy toggle
      expect(find.text('Drop a place.\nChoose your circle.'), findsOneWidget);
      expect(find.text('Friends Only'), findsOneWidget);
      expect(find.text('Public Discovery'), findsOneWidget);

      // Tap Public Discovery toggle
      await tester.tap(find.text('Public Discovery'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Visible on Tashkent Explore map'), findsOneWidget);

      // Tap Next to advance to Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: District selection
      expect(find.text('Where do you\nexplore most?'), findsOneWidget);
      expect(find.text('Mirabad District'), findsOneWidget);
      expect(find.text('Yakkasaray District'), findsOneWidget);
      expect(find.text('Browse as Guest'), findsOneWidget);
      expect(find.text('Launch Mirabad'), findsOneWidget);

      // Select Yakkasaray
      await tester.tap(find.text('Yakkasaray District'));
      await tester.pumpAndSettle();
      expect(find.text('Launch Yakkasaray'), findsOneWidget);

      // Tap Launch Yakkasaray
      await tester.tap(find.text('Launch Yakkasaray'));
      await tester.pumpAndSettle();

      // Verify persistence & analytics
      expect(StorageService.isOnboarded(), isTrue);
      expect(StorageService.getUserNeighborhood(), equals('Yakkasaray'));

      final events = AnalyticsService.instance.recentEvents;
      expect(events.any((e) => e.eventName == 'onboarding_complete'), isTrue);
      final completeEvent = events.firstWhere((e) => e.eventName == 'onboarding_complete');
      expect(completeEvent.properties['neighborhood'], equals('Yakkasaray'));
      expect(completeEvent.properties['as_guest'], isFalse);
    });
  });
}

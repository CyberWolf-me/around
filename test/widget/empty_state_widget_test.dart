import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:around_app/core/widgets/empty_state_widget.dart';
import 'package:around_app/data/repositories/profiles_repository.dart';
import 'package:around_app/data/repositories/saved_places_repository.dart';
import 'package:around_app/features/feed/screens/feed_screen.dart';
import 'package:around_app/features/saved_places/screens/saved_screen.dart';

class _EmptyFollowedFriendsNotifier extends FollowedFriendsNotifier {
  @override
  Set<String> build() => <String>{};
}

class _EmptySavedPlacesNotifier extends SavedPlacesNotifier {
  @override
  List<String> build() => <String>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmptyStateWidget & Error Resilience Tests (P12-05)', () {
    testWidgets('EmptyStateWidget.feedEmpty renders correctly and triggers callbacks', (tester) async {
      bool inviteTapped = false;
      bool exploreTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget.feedEmpty(
              onInviteFriends: () => inviteTapped = true,
              onDiscoverVenues: () => exploreTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your circle is quiet today'), findsOneWidget);
      expect(find.textContaining('Around is built around places friends actually go'), findsOneWidget);
      expect(find.text('Invite Friends via Telegram'), findsOneWidget);
      expect(find.text('Explore Tashkent Venues'), findsOneWidget);

      await tester.tap(find.text('Invite Friends via Telegram'));
      await tester.pumpAndSettle();
      expect(inviteTapped, isTrue);

      await tester.tap(find.text('Explore Tashkent Venues'));
      await tester.pumpAndSettle();
      expect(exploreTapped, isTrue);
    });

    testWidgets('EmptyStateWidget.savedEmpty adapts title and subtitle to filter', (tester) async {
      bool exploreTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget.savedEmpty(
              filterName: 'Coffee & Bakeries',
              onDiscoverVenues: () => exploreTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No places in "Coffee & Bakeries"'), findsOneWidget);
      expect(find.text('Discover Venues'), findsOneWidget);

      await tester.tap(find.text('Discover Venues'));
      await tester.pumpAndSettle();
      expect(exploreTapped, isTrue);
    });

    testWidgets('EmptyStateWidget.error renders connection interruption state and retries', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget.error(
              message: 'Database query timed out',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connection interrupted'), findsOneWidget);
      expect(find.text('Database query timed out'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('FeedScreen displays EmptyStateWidget when circle has no visible drops', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/feed',
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/explore', builder: (_, __) => const Scaffold(body: Text('EXPLORE_SCREEN'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            followedFriendsProvider.overrideWith(() => _EmptyFollowedFriendsNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Since followed friends is empty, visibleDrops is empty -> EmptyStateWidget is shown
      expect(find.text('Your circle is quiet today'), findsOneWidget);
      expect(find.text('Invite Friends via Telegram'), findsOneWidget);
      expect(find.text('Explore Tashkent Venues'), findsOneWidget);
    });

    testWidgets('SavedScreen displays EmptyStateWidget when filter yields zero places', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/saved',
        routes: [
          GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
          GoRoute(path: '/explore', builder: (_, __) => const Scaffold(body: Text('EXPLORE_SCREEN'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedPlacesProvider.overrideWith(() => _EmptySavedPlacesNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsWidgets);
      expect(find.text('No saved gems yet'), findsOneWidget);
      expect(find.text('Discover Venues'), findsOneWidget);
    });
  });
}
